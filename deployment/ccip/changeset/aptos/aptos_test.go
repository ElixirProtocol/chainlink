package aptos

import (
	"testing"

	"github.com/stretchr/testify/require"
	"go.uber.org/zap/zapcore"

	"github.com/smartcontractkit/chainlink/deployment/ccip/changeset/testhelpers"
	"github.com/smartcontractkit/chainlink/deployment/environment/memory"
	"github.com/smartcontractkit/chainlink/v2/core/logger"
)

// TODO: This is to test the implementation of Aptos chains in memory environment
// To be deleted after changesets tests are added
func TestAptosMemoryEnv(t *testing.T) {
	t.Parallel()
	// env, _ := testhelpers.NewMemoryEnvironment(t, testhelpers.WithAptosChains(1))
	// aptosChainSelectors := denv.Env.AllChainSelectorsAptos()
	lggr := logger.TestLogger(t)
	env := memory.NewMemoryEnvironment(t, lggr, zapcore.InfoLevel, memory.MemoryEnvironmentConfig{
		Bootstraps:  1,
		Chains:      1,
		AptosChains: 1,
		Nodes:       4,
	})
	aptosChainSelectors := env.AllChainSelectorsAptos()
	require.Len(t, aptosChainSelectors, 1)
}

// TODO: This is to test the implementation of Aptos chains in memory environment
// To be deleted after changesets tests are added
func TestAptosHelperMemoryEnv(t *testing.T) {
	t.Parallel()
	depEvn, testEnv := testhelpers.NewMemoryEnvironment(
		t,
		testhelpers.WithAptosChains(1),
		testhelpers.WithNoJobsAndContracts(), // currently not supporting jobs and contracts
	)
	aptosChainSelectors := depEvn.Env.AllChainSelectorsAptos()
	require.Len(t, aptosChainSelectors, 1)
	aptosChainSelectors2 := testEnv.DeployedEnvironment().Env.AllChainSelectorsAptos()
	require.Len(t, aptosChainSelectors2, 1)
}
