package utils

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/aptos-labs/aptos-go-sdk"
	"github.com/smartcontractkit/chainlink-aptos/bindings/bind"
	"github.com/smartcontractkit/chainlink-aptos/bindings/compile"
	mcmsbind "github.com/smartcontractkit/chainlink-aptos/bindings/mcms"
	"github.com/smartcontractkit/mcms"
	aptosmcms "github.com/smartcontractkit/mcms/sdk/aptos"
	"github.com/smartcontractkit/mcms/types"
)

const (
	ValidUntilHours     = 72
	MCMSProposalVersion = "v1"
)

func GenerateProposal(
	client aptos.AptosRpcClient,
	mcmsContract mcmsbind.MCMS,
	chainSel uint64,
	operations []types.Operation,
	description string,
	opCount uint64,
) (*mcms.Proposal, uint64, error) {
	if opCount == 0 {
		// Create MCMS inspector
		inspector := aptosmcms.NewInspector(client)
		startingOpCount, err := inspector.GetOpCount(context.Background(), mcmsContract.Address.StringLong())
		if err != nil {
			return nil, 0, fmt.Errorf("failed to get starting op count: %w", err)
		}
		opCount = startingOpCount
	}

	// Create proposal builder
	validUntil := time.Now().Add(time.Hour * ValidUntilHours).Unix()
	proposalBuilder := mcms.NewProposalBuilder().
		SetVersion(MCMSProposalVersion).
		SetValidUntil(uint32(validUntil)).
		SetDescription(description).
		SetOverridePreviousRoot(true).
		AddChainMetadata(
			types.ChainSelector(chainSel),
			types.ChainMetadata{
				StartingOpCount: opCount,
				MCMAddress:      mcmsContract.Address.StringLong(),
			},
		)

	// Add operations and build
	for _, op := range operations {
		proposalBuilder.AddOperation(op)
	}
	proposal, err := proposalBuilder.Build()
	if err != nil {
		return nil, opCount, fmt.Errorf("failed to build proposal: %w", err)
	}

	return proposal, opCount + uint64(len(operations)), nil
}

// CreateChunksAndStage creates chunks from the compiled packages and build MCMS operations to stages them within the MCMS contract
func CreateChunksAndStage(
	payload compile.CompiledPackage,
	mcmsContract mcmsbind.MCMS,
	chainSel uint64,
	seed string,
	codeObjectAddress *aptos.AccountAddress,
	packageName string, // TODO: this will be returned from Encode method
) ([]types.Operation, error) {
	// Validate seed XOR codeObjectAddress, one and only one must be provided
	if (seed != "") == (codeObjectAddress != nil) {
		return nil, fmt.Errorf("either provide seed to publishToObject or objectAddress to upgradeObjectCode")
	}

	var operations []types.Operation

	// Create chunks
	chunks, err := bind.CreateChunks(payload, bind.ChunkSizeInBytes)
	if err != nil {
		return operations, fmt.Errorf("failed to create chunks: %w", err)
	}

	// Stage chunks with mcms_deployer module and execute with the last one
	for i, chunk := range chunks {
		var (
			module   aptos.ModuleId
			function string
			args     [][]byte
			err      error
		)

		// First chunks get staged, the last one gets published or upgraded
		if i != len(chunks)-1 {
			module, function, _, args, err = mcmsContract.MCMSDeployer.EncodeStageCodeChunk(
				chunk.Metadata,
				chunk.CodeIndices,
				chunk.Chunks,
			)
		} else if seed != "" {
			module, function, _, args, err = mcmsContract.MCMSDeployer.EncodeStageCodeChunkAndPublishToObject(
				chunk.Metadata,
				chunk.CodeIndices,
				chunk.Chunks,
				[]byte(seed),
			)
		} else {
			module, function, _, args, err = mcmsContract.MCMSDeployer.EncodeStageCodeChunkAndUpgradeObjectCode(
				chunk.Metadata,
				chunk.CodeIndices,
				chunk.Chunks,
				*codeObjectAddress,
			)
		}
		if err != nil {
			return operations, fmt.Errorf("failed to encode chunk %d: %w", i, err)
		}
		additionalFields := aptosmcms.AdditionalFields{
			ModuleName:  module.Name,
			Function:    function,
			PackageName: packageName,
		}
		afBytes, err := json.Marshal(additionalFields)
		if err != nil {
			return operations, fmt.Errorf("failed to marshal additional fields: %w", err)
		}
		operations = append(operations, types.Operation{
			ChainSelector: types.ChainSelector(chainSel),
			Transaction: types.Transaction{
				To:               mcmsContract.Address.StringLong(),
				Data:             aptosmcms.ArgsToData(args),
				AdditionalFields: afBytes,
			},
		})
	}

	return operations, nil
}
