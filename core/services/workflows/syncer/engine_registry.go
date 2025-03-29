package syncer

import (
	"encoding/hex"
	"errors"
	"fmt"
	"maps"
	"slices"
	"sync"

	"github.com/smartcontractkit/chainlink-common/pkg/services"
)

var errNotFound = errors.New("engine not found")

type EngineKey string

type ServiceWithMetadata struct {
	metadata GetWorkflowMetadata
	service  services.Service
}

type EngineRegistry struct {
	engines map[EngineKey]ServiceWithMetadata
	mu      sync.RWMutex
}

func NewEngineRegistry() *EngineRegistry {
	return &EngineRegistry{
		engines: make(map[EngineKey]ServiceWithMetadata),
	}
}

// KeyFor generates a key that will be used to identify the engine in the engine registry.
// This is used instead of a Workflow ID, because the WID will change
// if the workflow code is modified.
func (r *EngineRegistry) KeyFor(owner []byte, name string) EngineKey {
	return EngineKey(hex.EncodeToString(owner) + "-" + name)
}

// Add adds an engine to the registry.
func (r *EngineRegistry) Add(key EngineKey, engine services.Service, metadata GetWorkflowMetadata) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, found := r.engines[key]; found {
		return errors.New("attempting to register duplicate engine")
	}
	r.engines[key] = ServiceWithMetadata{
		metadata: metadata,
		service:  engine,
	}
	return nil
}

// Get retrieves an engine from the registry.
func (r *EngineRegistry) Get(key EngineKey) (services.Service, GetWorkflowMetadata, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	engine, found := r.engines[key]
	if !found {
		return nil, GetWorkflowMetadata{}, errNotFound
	}
	return engine.service, engine.metadata, nil
}

// GetAllKeys retrieves all of the keys that are currently known by the engine registry.
func (r *EngineRegistry) GetAllKeys() []EngineKey {
	r.mu.RLock()
	defer r.mu.RUnlock()
	keys := []EngineKey{}
	for key, _ := range r.engines {
		keys = append(keys, key)
	}
	return keys
}

// Contains is true if the engine exists.
func (r *EngineRegistry) Contains(id EngineKey) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	_, found := r.engines[id]
	return found
}

// Pop removes an engine from the registry and returns the engine if found.
func (r *EngineRegistry) Pop(id EngineKey) (services.Service, GetWorkflowMetadata, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	engine, ok := r.engines[id]
	if !ok {
		return nil, GetWorkflowMetadata{}, fmt.Errorf("pop failed: %w", errNotFound)
	}
	delete(r.engines, id)
	return engine.service, engine.metadata, nil
}

// PopAll removes and returns all engines.
func (r *EngineRegistry) PopAll() ([]services.Service, []GetWorkflowMetadata) {
	r.mu.Lock()
	defer r.mu.Unlock()
	all := slices.Collect(maps.Values(r.engines))
	r.engines = make(map[EngineKey]ServiceWithMetadata)
	services := make([]services.Service, len(all))
	metadata := make([]GetWorkflowMetadata, len(all))
	for i := range all {
		services[i] = all[i].service
		metadata[i] = all[i].metadata
	}
	return services, metadata
}
