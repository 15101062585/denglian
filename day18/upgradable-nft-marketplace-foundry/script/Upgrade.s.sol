// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/NFTMarketplaceV2.sol";
import "../src/upgrades/UpgradeableProxy.sol";

contract UpgradeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address deployer = vm.addr(deployerPrivateKey);
        
        // 从环境变量或部署信息中获取代理地址
        // 这里假设代理地址已经知道，实际使用时可以从文件读取
        string memory proxyAddressStr = vm.envString("PROXY_ADDRESS");
        address proxyAddress = vm.parseAddress(proxyAddressStr);
        
        require(proxyAddress != address(0), "Proxy address not set");

        console.log("Upgrading proxy at:", proxyAddress);
        console.log("Deployer:", deployer);

        // 1. 部署 NFTMarketplaceV2
        console.log("Deploying NFTMarketplaceV2 implementation...");
        NFTMarketplaceV2 marketplaceV2 = new NFTMarketplaceV2();
        console.log("NFTMarketplaceV2 implementation deployed at:", address(marketplaceV2));

        // 2. 升级代理合约
        console.log("Upgrading proxy...");
        UpgradeableProxy proxy = UpgradeableProxy(payable(proxyAddress));
        proxy.upgradeTo(address(marketplaceV2));
        console.log("Proxy upgraded to V2");

        vm.stopBroadcast();

        // 保存升级信息
        _saveUpgradeInfo(address(marketplaceV2), deployer);
    }

    function _saveUpgradeInfo(address implementationV2, address deployer) internal {
        string memory upgradeInfo = string(abi.encodePacked(
            "Upgrade Time: ", vm.toString(block.timestamp), "\n",
            "Deployer: ", vm.toString(deployer), "\n",
            "Marketplace V2 Implementation: ", vm.toString(implementationV2), "\n"
        ));

        vm.writeFile("deployments/upgrade-info.txt", upgradeInfo);
        console.log("Upgrade info saved to deployments/upgrade-info.txt");
    }
}