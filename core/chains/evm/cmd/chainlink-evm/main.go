package main

import (
	"context"
	"fmt"
	"strings"

	"github.com/hashicorp/go-plugin"
	"github.com/pelletier/go-toml/v2"
	"github.com/prometheus/client_golang/prometheus"

	"github.com/smartcontractkit/chainlink-common/pkg/loop"
	"github.com/smartcontractkit/chainlink-common/pkg/sqlutil"
	"github.com/smartcontractkit/chainlink-common/pkg/types/core"
	evmcfg "github.com/smartcontractkit/chainlink-integrations/evm/config/toml"
	"github.com/smartcontractkit/chainlink-integrations/evm/keys"
	"github.com/smartcontractkit/chainlink/v2/core/chains/legacyevm"
	"github.com/smartcontractkit/chainlink/v2/core/services/relay/evm"
	clhttp "github.com/smartcontractkit/chainlink/v2/core/utils/http"
)

const (
	loggerName = "PluginSolana"
)

func main() {
	s := loop.MustNewStartedServer(loggerName)
	defer s.Stop()

	p := &pluginRelayer{Plugin: loop.Plugin{Logger: s.Logger}, DataSource: s.DataSource}
	defer s.Logger.ErrorIfFn(p.Close, "Failed to close")

	s.MustRegister(p)

	stopCh := make(chan struct{})
	defer close(stopCh)

	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: loop.PluginRelayerHandshakeConfig(),
		Plugins: map[string]plugin.Plugin{
			loop.PluginRelayerName: &loop.GRPCPluginRelayer{
				PluginServer: p,
				BrokerConfig: loop.BrokerConfig{
					StopCh:   stopCh,
					Logger:   s.Logger,
					GRPCOpts: s.GRPCOpts,
				},
			},
		},
		GRPCServer: s.GRPCOpts.NewServer,
	})
}

type pluginRelayer struct {
	loop.Plugin
	sqlutil.DataSource
}

func (c *pluginRelayer) NewRelayer(ctx context.Context, config string, keystore core.Keystore, capRegistry core.CapabilitiesRegistry) (loop.Relayer, error) {
	d := toml.NewDecoder(strings.NewReader(config))
	d.DisallowUnknownFields()
	var cfg struct {
		EVM evmcfg.EVMConfig
	}

	if err := d.Decode(&cfg); err != nil {
		return nil, fmt.Errorf("failed to decode config toml: %w:\n\t%s", err, config)
	}

	evmKeystore := keys.NewChainStore(keystore, cfg.EVM.ChainID.ToInt())

	chain, err := legacyevm.NewTOMLChain(&cfg.EVM, legacyevm.ChainRelayOpts{
		Logger:   c.Logger,
		KeyStore: evmKeystore,
		ChainOpts: legacyevm.ChainOpts{
			ChainConfigs:   nil,
			DatabaseConfig: nil,
			FeatureConfig:  nil,
			ListenerConfig: nil,
			MailMon:        nil,
			GasEstimator:   nil,
			DS:             c.DataSource,
		},
		//TODO other opts?
	}, nil) // TODO client are not accessible
	if err != nil {
		return nil, fmt.Errorf("failed to create chain: %w", err)
	}

	//TODO do we need the "whole" relayer?
	ra, err := evm.NewRelayer(c.Logger, chain, evm.RelayerOpts{
		DS:                    c.DataSource,
		Registerer:            prometheus.DefaultRegisterer,
		EVMKeystore:           evmKeystore,
		CSAKeystore:           nil, //TODO csaKeystore
		MercuryPool:           nil,
		RetirementReportCache: nil,
		MercuryConfig:         nil,
		CapabilitiesRegistry:  capRegistry,
		HTTPClient:            clhttp.NewUnrestrictedHTTPClient(), //TODO core dependency
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create relayer: %w", err)
	}

	c.SubService(ra)

	return ra, nil
}
