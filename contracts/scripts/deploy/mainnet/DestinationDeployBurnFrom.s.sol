// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper

import {BurnFromMintTokenPool} from "src/v0.8/ccip/pools/BurnFromMintTokenPool.sol";
import {IBurnMintERC20} from "src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";
import {RegistryModuleOwnerCustom} from
    "src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "src/v0.8/ccip/libraries/RateLimiter.sol";

contract DeployBurnFromMintTokenPoolDestination is Script {
    function run() external {

        // Read caller information.
        (, address deployer,) = vm.readCallers();

        // Get the chain name based on the current chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Construct the path to the deployed token JSON file
        // string memory root = vm.projectRoot();

        // Mainnet
        // address tokenAddress = ;
        // Sepolia
        address tokenAddress = 0x9516d5F1362F439a74963304E922e3A738D8CE02;

        // Fetch network configuration (router and RMN proxy addresses)
        HelperConfig helperConfig = new HelperConfig();
        (, address router, address rmnProxy, address tokenAdminRegistry, address registryModuleOwnerCustom,,,) = helperConfig.activeNetworkConfig();

        // Ensure that the token address, router, and RMN proxy are valid
        require(tokenAddress != address(0), "Invalid token address");
        require(router != address(0) && rmnProxy != address(0), "Router or RMN Proxy not defined for this network");

        vm.startBroadcast();

        // STEP 1
        // // Cast the token address to the IBurnMintERC20 interface
        // IBurnMintERC20 token = IBurnMintERC20(tokenAddress);
        //
        // // Mainnet minting contract address
        // // address minter = 0x69088d25a635D22dcbe7c4A5C7707B9cc64bD114;
        // // Dev minting contract address
        // address minter = 0x9516d5F1362F439a74963304E922e3A738D8CE02;
        //
        // // Deploy the BurnFromMintTokenPool contract associated with the token
        // BurnFromMintTokenPool tokenPool = new BurnFromMintTokenPool (
        //     token,
        //     18, // The number of decimals of the token
        //     new address[](0), // Empty array for initial operators
        //     rmnProxy,
        //     router,
        //     minter
        // );
        //
        // console.log("Burn & Mint token pool deployed to:", address(tokenPool));
        //
        // // Grant mint and burn roles to the token pool on the token contract
        // // TODO:
        // console.log("Granted mint and burn roles to token pool:", address(tokenPool));

        // // STEP 2
        // // Serialize and write the token pool address to a new JSON file
        // string memory jsonObj = "internal_key";
        // string memory key = string(abi.encodePacked("deployedTokenPool_", chainName));
        // string memory finalJson = vm.serializeAddress(jsonObj, key, address(0x01805CD1300Bb37Eb61ff4780f6A70a0Ca4dE2bd));
        //
        // string memory poolFileName = string(abi.encodePacked("./scripts/deploy/output/deployedTokenPool_", chainName, ".json"));
        // console.log("Writing deployed token pool address to file:", poolFileName);
        // vm.writeJson(finalJson, poolFileName);
        //
        // // Instantiate the registry contract
        // RegistryModuleOwnerCustom registryContract = RegistryModuleOwnerCustom(registryModuleOwnerCustom);
        //
        // console.log("Claiming admin of the token via owner() for signer:", deployer);
        // // Register the admin via owner() function
        // registryContract.registerAdminViaGetCCIPAdmin(tokenAddress);
        // console.log("Admin claimed successfully for token:", tokenAddress);


        // // STEP 3
        // // Instantiate the TokenAdminRegistry contract
        // TokenAdminRegistry tokenAdminRegistryContract = TokenAdminRegistry(tokenAdminRegistry);
        //
        // // Fetch the token configuration for the given token address
        // TokenAdminRegistry.TokenConfig memory tokenConfig = tokenAdminRegistryContract.getTokenConfig(tokenAddress);
        //
        // // Get the pending administrator for the token
        // address pendingAdministrator = tokenConfig.pendingAdministrator;
        //
        // // Ensure the signer is the pending administrator
        // require(pendingAdministrator == deployer, "Only the pending administrator can accept the admin role");
        //
        // // Accept the admin role for the token
        // tokenAdminRegistryContract.acceptAdminRole(tokenAddress);
        //
        // console.log("Accepted admin role for token:", tokenAddress);

        // // Step 4
        // address poolAddress = 0x01805CD1300Bb37Eb61ff4780f6A70a0Ca4dE2bd;
        //
        // // Instantiate the TokenAdminRegistry contract
        // TokenAdminRegistry tokenAdminRegistryContract = TokenAdminRegistry(tokenAdminRegistry);
        //
        // require(poolAddress != address(0), "Invalid pool address");
        // require(tokenAdminRegistry != address(0), "TokenAdminRegistry is not defined for this network");
        //
        // // Fetch the token configuration to get the administrator's address
        // TokenAdminRegistry.TokenConfig memory config = tokenAdminRegistryContract.getTokenConfig(tokenAddress);
        // address tokenAdministratorAddress = config.administrator;
        //
        // console.log("Setting pool for token:", tokenAddress);
        // console.log("New pool address:", poolAddress);
        // console.log("Action performed by admin:", tokenAdministratorAddress);
        //
        // // Use the administrator's address to set the pool for the token
        // tokenAdminRegistryContract.setPool(tokenAddress, poolAddress);
        //
        // console.log("Pool set for token", tokenAddress, "to", poolAddress);


        // Step 5
        address poolAddress = 0x01805CD1300Bb37Eb61ff4780f6A70a0Ca4dE2bd;
        address remotePoolAddress = 0x2dDf7716E27b144C979C98858f407C601716156b;
        address remoteTokenAddress = 0xa6B08f1B0d894429Ed73fB68F0330318b188e2B0;
        uint64 remoteChainId = 11155111;

        // For remotePoolAddresses, create an array with the remotePoolAddress
        address[] memory remotePoolAddresses = new address[](1);
        remotePoolAddresses[0] = remotePoolAddress;

        HelperConfig.NetworkConfig memory remoteNetworkConfig =
            HelperUtils.getNetworkConfig(helperConfig, remoteChainId);

        uint64 remoteChainSelector = remoteNetworkConfig.chainSelector;

        require(poolAddress != address(0), "Invalid pool address");
        require(remotePoolAddress != address(0), "Invalid remote pool address");
        require(remoteTokenAddress != address(0), "Invalid remote token address");
        require(remoteChainSelector != 0, "chainSelector is not defined for the remote chain");

        // Instantiate the local TokenPool contract
        TokenPool poolContract = TokenPool(poolAddress);

        // Prepare chain update data for configuring cross-chain transfers
        TokenPool.ChainUpdate[] memory chainUpdates = new TokenPool.ChainUpdate[](1);

        // Encode remote pool addresses
        bytes[] memory remotePoolAddressesEncoded = new bytes[](remotePoolAddresses.length);
        for (uint256 i = 0; i < remotePoolAddresses.length; i++) {
            remotePoolAddressesEncoded[i] = abi.encode(remotePoolAddresses[i]);
        }

        chainUpdates[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector, // Chain selector of the remote chain
            remotePoolAddresses: remotePoolAddressesEncoded, // Array of encoded addresses of the remote pools
            remoteTokenAddress: abi.encode(remoteTokenAddress), // Encoded address of the remote token
            outboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: false, // Set to true to enable outbound rate limiting
                capacity: 0, // Max tokens allowed in the outbound rate limiter
                rate: 0 // Refill rate per second for the outbound rate limiter
            }),
            inboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: false, // Set to true to enable inbound rate limiting
                capacity: 0, // Max tokens allowed in the inbound rate limiter
                rate: 0 // Refill rate per second for the inbound rate limiter
            })
        });

        // Create an empty array for chainSelectorRemovals
        uint64[] memory chainSelectorRemovals = new uint64[](0);

        // Apply the chain updates to configure the pool
        poolContract.applyChainUpdates(chainSelectorRemovals, chainUpdates);

        console.log("Chain update applied to pool at address:", poolAddress);


        vm.stopBroadcast();
    }
}
