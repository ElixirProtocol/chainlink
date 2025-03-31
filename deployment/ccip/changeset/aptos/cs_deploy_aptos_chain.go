package aptos

import (
	"errors"
	"fmt"

	"github.com/aptos-labs/aptos-go-sdk"

	"github.com/smartcontractkit/chainlink/deployment"
	"github.com/smartcontractkit/chainlink/deployment/ccip/changeset"
	"github.com/smartcontractkit/chainlink/deployment/ccip/changeset/aptos/operation"
	"github.com/smartcontractkit/mcms"
)

// CsDeployAptosChain deploys CCIP Package for Aptos chains
var CsDeployAptosChain deployment.ChangeSetV2[DeployAptosChainConfig] = CsDeployAptosChainImp{}

type CsDeployAptosChainImp struct{}

func (cs CsDeployAptosChainImp) VerifyPreconditions(env deployment.Environment, config DeployAptosChainConfig) error {
	// Validate env and prerequisite contracts
	state, err := changeset.LoadOnchainStateAptos(env)
	if err != nil {
		return fmt.Errorf("failed to load existing onchain state: %w", err)
	}
	var errs []error
	for chainSel := range config.ContractParamsPerChain {
		if _, ok := env.AptosChains[chainSel]; !ok {
			errs = append(errs, fmt.Errorf("chain %d not found in env", chainSel))
		}
		chainState, ok := state[chainSel]
		if !ok {
			errs = append(errs, fmt.Errorf("chain %d not found in state", chainSel))
		}
		if chainState.MCMSAddress == (aptos.AccountAddress{}) {
			mcmsConfig := config.MCMSConfigPerChain[chainSel]
			err = mcmsConfig.Validate()
			errs = append(errs, fmt.Errorf("invalid mcms configs for chain %d: %w", chainSel, err))
		}
		if err := config.Validate(); err != nil {
			errs = append(errs, fmt.Errorf("invalid config for chain %d: %w", chainSel, err))
		}
	}

	return errors.Join(errs...)
}

func (cs CsDeployAptosChainImp) Apply(env deployment.Environment, config DeployAptosChainConfig) (deployment.ChangesetOutput, error) {
	state, err := changeset.LoadOnchainStateAptos(env)
	if err != nil {
		return deployment.ChangesetOutput{}, fmt.Errorf("failed to load onchain state: %w", err)
	}

	ab := deployment.NewMemoryAddressBook()
	proposals := &[]mcms.Proposal{}

	// Deploy CCIP on each Aptos chain in config
	for chainSel := range config.ContractParamsPerChain {
		chainState := state[chainSel]
		aptosChain := env.AptosChains[chainSel]

		// TODO: Config home chain operations

		// MCMS Deploy operations
		opsMCMS := operation.MCMSDeploymentOperations{
			Env:          env,
			Ab:           ab,
			AptosChain:   aptosChain,
			OnChainState: chainState,
			MCMSConfigs:  config.MCMSConfigPerChain[chainSel],
			Proposals:    proposals,
			MCMSOpCount:  0,
		}
		err := runMCMSDeployOperations(&opsMCMS)
		if err != nil {
			return deployment.ChangesetOutput{}, fmt.Errorf("failed to deploy MCMS contracts for chain %d: %w", chainSel, err)
		}

		// CCIP Deploy operations
		ccipOps := operation.CCIPDeploymentOperations{
			Env:          env,
			Ab:           ab,
			AptosChain:   aptosChain,
			OnChainState: opsMCMS.OnChainState,
			Proposals:    proposals,
			MCMSOpCount:  opsMCMS.MCMSOpCount,
		}
		err = runCCIPDeployOperations(&ccipOps)
		if err != nil {
			return deployment.ChangesetOutput{}, fmt.Errorf("failed to deploy CCIP contracts for chain %d: %w", chainSel, err)
		}

		// TODO: Initialize contracts operations

	}

	return deployment.ChangesetOutput{
		AddressBook:   ab,
		MCMSProposals: *proposals,
	}, nil
}

func runMCMSDeployOperations(ops *operation.MCMSDeploymentOperations) error {
	// Check if MCMS package is already deployed
	if (ops.OnChainState.MCMSAddress != aptos.AccountAddress{}) {
		ops.Env.Logger.Infow("MCMS Package already deployed", "addr", ops.OnChainState.MCMSAddress.String())
		return nil
	}
	// Deploy MCMS
	addressMCMS, contractMCMS, err := ops.DeployMCMS()
	if err != nil {
		return fmt.Errorf("failed to deploy MCMS contract: %w", err)
	}
	// Configure MCMS
	err = ops.ConfigureMCMS(addressMCMS)
	if err != nil {
		return fmt.Errorf("failed to configure MCMS contract: %w", err)
	}
	// Transfer ownership to self
	err = ops.TransferOwnershipToSelf(contractMCMS)
	if err != nil {
		return fmt.Errorf("failed to transfer ownership to self: %w", err)
	}
	// Generate proposal to transfer ownership to self
	proposal, mcmsOpCount, err := ops.GenerateAcceptOwnershipProposal(addressMCMS, contractMCMS)
	if err != nil {
		return fmt.Errorf("failed to build AcceptOwnership proposal: %w", err)
	}
	*ops.Proposals = append(*ops.Proposals, *proposal)
	ops.MCMSOpCount = mcmsOpCount

	return nil
}

func runCCIPDeployOperations(ops *operation.CCIPDeploymentOperations) error {
	// Cleanup MCMS staging area
	err := ops.GenerateCleanupStagingProposal()
	if err != nil {
		return fmt.Errorf("failed to generate cleanup staging proposal: %w", err)
	}
	// Generate proposals - Deploy CCIP package
	ccipObjectAddress, err := ops.GenerateDeployCCIPProposal()
	if err != nil {
		return fmt.Errorf("failed to generate CCIP deploy proposal: %w", err)
	}
	// Generate proposals - Deploy Router package
	err = ops.GenerateDeployRouterProposal(ccipObjectAddress)
	if err != nil {
		return fmt.Errorf("failed to generate Router deploy proposal: %w", err)
	}

	return nil
}
