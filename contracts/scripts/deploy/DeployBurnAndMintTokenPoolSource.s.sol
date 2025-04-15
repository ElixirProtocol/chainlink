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

contract DeployBurnFromMintTokenPoolSource is Script {
    function run() external {
        vm.startBroadcast();

        // Read caller information.
        (, address deployer,) = vm.readCallers();

        // Get the chain name based on the current chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Construct the path to the deployed token JSON file
        // string memory root = vm.projectRoot();

        // Mainnet
        // address tokenAddress = ;
        // Sepolia
        address tokenAddress = 0xa6B08f1B0d894429Ed73fB68F0330318b188e2B0;

        // Fetch network configuration (router and RMN proxy addresses)
        HelperConfig helperConfig = new HelperConfig();
        (, address router, address rmnProxy, address tokenAdminRegistry, address registryModuleOwnerCustom,,,) = helperConfig.activeNetworkConfig();

        // Ensure that the token address, router, and RMN proxy are valid
        require(tokenAddress != address(0), "Invalid token address");
        require(router != address(0) && rmnProxy != address(0), "Router or RMN Proxy not defined for this network");

        // // Cast the token address to the IBurnMintERC20 interface
        // IBurnMintERC20 token = IBurnMintERC20(tokenAddress);
        //
        // // Mainnet minting contract address
        // // address minter = 0x69088d25a635D22dcbe7c4A5C7707B9cc64bD114;
        // // Dev minting contract address
        // address minter = 0x6C5FfEB3507055aFc2461394c1AE8C1Fe2d870AB;
        //
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
        //
        // // Serialize and write the token pool address to a new JSON file
        // string memory jsonObj = "internal_key";
        // string memory key = string(abi.encodePacked("deployedTokenPool_", chainName));
        // string memory finalJson = vm.serializeAddress(jsonObj, key, address(tokenPool));
        //
        // string memory poolFileName = string(abi.encodePacked("./scripts/deploy/output/deployedTokenPool_", chainName, ".json"));
        // console.log("Writing deployed token pool address to file:", poolFileName);
        // vm.writeJson(finalJson, poolFileName);
        //
        // // Instantiate the registry contract
        // RegistryModuleOwnerCustom registryContract = RegistryModuleOwnerCustom(registryModuleOwnerCustom);
        //
        // console.log("Claiming admin of the token via owner() for signer:", msg.sender);
        // // Register the admin via owner() function
        // registryContract.registerAdminViaOwner(tokenAddress);
        // console.log("Admin claimed successfully for token:", tokenAddress);


        // Instantiate the TokenAdminRegistry contract
        TokenAdminRegistry tokenAdminRegistryContract = TokenAdminRegistry(tokenAdminRegistry);

        // Fetch the token configuration for the given token address
        TokenAdminRegistry.TokenConfig memory tokenConfig = tokenAdminRegistryContract.getTokenConfig(tokenAddress);

        // Get the pending administrator for the token
        address pendingAdministrator = tokenConfig.pendingAdministrator;

        // Ensure the signer is the pending administrator
        require(pendingAdministrator == deployer, "Only the pending administrator can accept the admin role");

        // Accept the admin role for the token
        tokenAdminRegistryContract.acceptAdminRole(tokenAddress);

        console.log("Accepted admin role for token:", tokenAddress);
        vm.stopBroadcast();
    }
}
