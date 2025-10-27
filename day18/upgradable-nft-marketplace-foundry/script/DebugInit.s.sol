// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarketplaceV1.sol";
import "../src/upgrades/UpgradeableProxy.sol";

contract DebugInitScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Debug Initialization ===");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 测试 MyNFT 初始化
        console.log("\n1. Testing MyNFT initialization...");
        MyNFT nft = new MyNFT("Test NFT", "TNFT");
        
        
        
        // 测试 MarketplaceV1 初始化
        console.log("\n2. Testing MarketplaceV1 initialization...");
        NFTMarketplaceV1 marketV1 = new NFTMarketplaceV1();
        
        try marketV1.initialize(deployer) {
            console.log(" MarketplaceV1 initialized successfully (no owner param)");
        } catch {
            try marketV1.initialize(deployer) {
                console.log(" MarketplaceV1 initialized successfully (with owner param)");
            } catch Error(string memory reason) {
                console.log(" MarketplaceV1 initialization failed:", reason);
            } catch {
                console.log(" MarketplaceV1 initialization failed with unknown error");
            }
        }
        
        vm.stopBroadcast();
    }
}