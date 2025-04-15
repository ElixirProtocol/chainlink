// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper

import {BurnFromMintTokenPool} from "src/v0.8/ccip/pools/BurnFromMintTokenPool.sol";
import {IBurnMintERC20} from "src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";

contract DeployBurnFromMintTokenPool is Script {
    function run() external {
        // Get the chain name based on the current chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Construct the path to the deployed token JSON file
        string memory root = vm.projectRoot();
        string memory deployedTokenPath = string.concat(root, "/script/output/deployedToken_", chainName, ".json");

        // Extract the deployed token address from the JSON file
        address tokenAddress =
            HelperUtils.getAddressFromJson(vm, deployedTokenPath, string.concat(".deployedToken_", chainName));

        // Fetch network configuration (router and RMN proxy addresses)
        HelperConfig helperConfig = new HelperConfig();
        (, address router, address rmnProxy,,,,,) = helperConfig.activeNetworkConfig();

        // Ensure that the token address, router, and RMN proxy are valid
        require(tokenAddress != address(0), "Invalid token address");
        require(router != address(0) && rmnProxy != address(0), "Router or RMN Proxy not defined for this network");

        // Cast the token address to the IBurnMintERC20 interface
        IBurnMintERC20 token = IBurnMintERC20(tokenAddress);

        // Mainnet minting contract address
        // address minter = 0x69088d25a635D22dcbe7c4A5C7707B9cc64bD114;
        // Dev minting contract address
        address minter = 0x6C5FfEB3507055aFc2461394c1AE8C1Fe2d870AB;

        vm.startBroadcast();

        // Deploy the BurnFromMintTokenPool contract associated with the token
        BurnFromMintTokenPool tokenPool = new BurnFromMintTokenPool (
            token,
            18, // The number of decimals of the token
            new address[](0), // Empty array for initial operators
            rmnProxy,
            router,
            minter
        );

        console.log("Burn & Mint token pool deployed to:", address(tokenPool));

        // Grant mint and burn roles to the token pool on the token contract
        // TODO:
        console.log("Granted mint and burn roles to token pool:", address(tokenPool));

        vm.stopBroadcast();

        // Serialize and write the token pool address to a new JSON file
        string memory jsonObj = "internal_key";
        string memory key = string(abi.encodePacked("deployedTokenPool_", chainName));
        string memory finalJson = vm.serializeAddress(jsonObj, key, address(tokenPool));

        string memory poolFileName = string(abi.encodePacked("./script/output/deployedTokenPool_", chainName, ".json"));
        console.log("Writing deployed token pool address to file:", poolFileName);
        vm.writeJson(finalJson, poolFileName);
    }
}
