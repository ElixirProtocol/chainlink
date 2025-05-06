// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint64 chainSelector;
        address router;
        address rmnProxy;
        address tokenAdminRegistry;
        address registryModuleOwnerCustom;
        address link;
        uint256 confirmations;
        string nativeCurrencySymbol;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getEthereumSepoliaConfig();
        } else if (block.chainid == 421614) {
            activeNetworkConfig = getArbitrumSepolia();
        } else if (block.chainid == 43113) {
            activeNetworkConfig = getAvalancheFujiConfig();
        } else if (block.chainid == 84532) {
            activeNetworkConfig = getBaseSepoliaConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getEthereumMainnetConfig();
        } else if (block.chainid == 43114) {
            activeNetworkConfig = getAvalancheMainnetConfig();
        } else if (block.chainid == 137) {
            activeNetworkConfig = getPolygonPosMainnetConfig();
        } else if (block.chainid == 80094) {
            activeNetworkConfig = getBerachainMainnetConfig();
        }

    }

    function getEthereumMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethereumMainnetConfig = NetworkConfig({
            chainSelector: 5009297550715157269,
            router: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
            rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
            tokenAdminRegistry: 0xb22764f98dD05c789929716D677382Df22C05Cb6,
            registryModuleOwnerCustom: 0x4855174E9479E211337832E109E7721d43A4CA64,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            confirmations: 7,
            nativeCurrencySymbol: "ETH"
        });
        return ethereumMainnetConfig;
    }

    function getAvalancheMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory avalancheMainnetConfig = NetworkConfig({
            chainSelector: 6433500567565415381,
            router: 0xF4c7E640EdA248ef95972845a62bdC74237805dB,
            rmnProxy: 0xcBD48A8eB077381c3c4Eb36b402d7283aB2b11Bc,
            tokenAdminRegistry: 0xc8df5D618c6a59Cc6A311E96a39450381001464F,
            registryModuleOwnerCustom: 0x76Aa17dCda9E8529149E76e9ffaE4aD1C4AD701B,
            link: 0x5947BB275c521040051D82396192181b413227A3,
            confirmations: 2,
            nativeCurrencySymbol: "AVAX"
        });
        return avalancheMainnetConfig;
    }

    function getPolygonPosMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory polygonPosMainnetConfig = NetworkConfig({
            chainSelector: 4051577828743386545,
            router: 0x849c5ED5a80F5B408Dd4969b78c2C8fdf0565Bfe,
            rmnProxy: 0xf1ceAa46D8d13Cac9fC38aaEF3d3d14754C5A9c2,
            tokenAdminRegistry: 0x00F027eA6D0fb03256A15E9182B2B9227A4931d8,
            registryModuleOwnerCustom: 0xc751E86208F0F8aF2d5CD0e29716cA7AD98B5eF5,
            link: 0xb0897686c545045aFc77CF20eC7A532E3120E0F1,
            confirmations: 10,
            nativeCurrencySymbol: "POL"
        });
        return polygonPosMainnetConfig;
    }

    function getBerachainMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory berachainMainnetConfig = NetworkConfig({
            chainSelector: 1294465214383781161,
            router: 0x71a275704c283486fBa26dad3dd0DB78804426eF,
            rmnProxy: 0x25943b8C30C47F4eF09CcF2BAE315EbaF591881d,
            tokenAdminRegistry: 0x0944C3Fb1dB7D165336569221995B31cBE6c8A55,
            registryModuleOwnerCustom: 0x452b8543fdF4Da91FE914CC92c3B79632730cFC7,
            link: 0x71052BAe71C25C78E37fD12E5ff1101A71d9018F,
            confirmations: 10,
            nativeCurrencySymbol: "BERA"
        });
        return berachainMainnetConfig;
    }

    function getEthereumSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethereumSepoliaConfig = NetworkConfig({
            chainSelector: 16015286601757825753,
            router: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
            rmnProxy: 0xba3f6251de62dED61Ff98590cB2fDf6871FbB991,
            tokenAdminRegistry: 0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82,
            registryModuleOwnerCustom: 0x62e731218d0D47305aba2BE3751E7EE9E5520790,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            confirmations: 2,
            nativeCurrencySymbol: "ETH"
        });
        return ethereumSepoliaConfig;
    }

    function getArbitrumSepolia() public pure returns (NetworkConfig memory) {
        NetworkConfig memory arbitrumSepoliaConfig = NetworkConfig({
            chainSelector: 3478487238524512106,
            router: 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165,
            rmnProxy: 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2,
            tokenAdminRegistry: 0x8126bE56454B628a88C17849B9ED99dd5a11Bd2f,
            registryModuleOwnerCustom: 0xE625f0b8b0Ac86946035a7729Aba124c8A64cf69,
            link: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E,
            confirmations: 2,
            nativeCurrencySymbol: "ETH"
        });
        return arbitrumSepoliaConfig;
    }

    function getAvalancheFujiConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory avalancheFujiConfig = NetworkConfig({
            chainSelector: 14767482510784806043,
            router: 0xF694E193200268f9a4868e4Aa017A0118C9a8177,
            rmnProxy: 0xAc8CFc3762a979628334a0E4C1026244498E821b,
            tokenAdminRegistry: 0xA92053a4a3922084d992fD2835bdBa4caC6877e6,
            registryModuleOwnerCustom: 0x97300785aF1edE1343DB6d90706A35CF14aA3d81,
            link: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            confirmations: 2,
            nativeCurrencySymbol: "AVAX"
        });
        return avalancheFujiConfig;
    }

    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory baseSepoliaConfig = NetworkConfig({
            chainSelector: 10344971235874465080,
            router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            rmnProxy: 0x99360767a4705f68CcCb9533195B761648d6d807,
            tokenAdminRegistry: 0x736D0bBb318c1B27Ff686cd19804094E66250e17,
            registryModuleOwnerCustom: 0x8A55C61227f26a3e2f217842eCF20b52007bAaBe,
            link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
            confirmations: 2,
            nativeCurrencySymbol: "ETH"
        });
        return baseSepoliaConfig;
    }
}
