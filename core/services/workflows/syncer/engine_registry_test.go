package syncer

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/smartcontractkit/chainlink-common/pkg/services"
)

func TestEngineRegistry(t *testing.T) {
	var srv services.Service = &fakeService{}

	const id1 = "foo"
	er := NewEngineRegistry()
	require.False(t, er.Contains(id1))

	e, m, err := er.Get(id1)
	require.ErrorIs(t, err, errNotFound)
	require.Nil(t, e)
	require.Equal(t, GetWorkflowMetadata{}, m)

	e, m, err = er.Pop(id1)
	require.ErrorIs(t, err, errNotFound)
	require.Nil(t, e)
	require.Equal(t, GetWorkflowMetadata{}, m)

	metadata := GetWorkflowMetadata{
		WorkflowID:   [32]byte{0, 1, 2, 3, 4},
		Owner:        []byte{1, 2, 3, 4, 5},
		DonID:        uint32(3),
		Status:       uint8(1),
		WorkflowName: "my-workflow",
		BinaryURL:    "http://something1",
		ConfigURL:    "http://something2",
		SecretsURL:   "http://something3",
	}
	// add
	require.NoError(t, er.Add(id1, srv, metadata))
	require.True(t, er.Contains(id1))

	e, m, err = er.Get(id1)
	require.NoError(t, err)
	require.Equal(t, srv, e)
	require.Equal(t, metadata, m)

	// remove
	e, m, err = er.Pop(id1)
	require.NoError(t, err)
	require.Equal(t, srv, e)
	require.Equal(t, metadata, m)
	require.False(t, er.Contains(id1))

	// re-add
	require.NoError(t, er.Add(id1, srv, metadata))

	es, ms := er.PopAll()
	require.Len(t, es, 1)
	require.Equal(t, srv, es[0])
	require.Equal(t, metadata, ms[0])
}

type fakeService struct{}

func (f fakeService) Start(ctx context.Context) error { return nil }

func (f fakeService) Close() error { return nil }

func (f fakeService) Ready() error { return nil }

func (f fakeService) HealthReport() map[string]error { return map[string]error{} }

func (f fakeService) Name() string { return "" }
