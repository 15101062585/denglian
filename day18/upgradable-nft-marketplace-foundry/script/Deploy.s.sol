// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarketplaceV1.sol";
import "../src/upgrades/SimpleProxy.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with address:", deployer);

        // 1. 部署 MyNFT
        console.log("Deploying MyNFT...");
        MyNFT nft = new MyNFT("Test NFT", "TNFT");
        console.log("MyNFT deployed at:", address(nft));

        // 2. 部署 NFTMarketplaceV1 实现合约
        console.log("Deploying NFTMarketplaceV1 implementation...");
        NFTMarketplaceV1 marketplaceV1 = new NFTMarketplaceV1();
        console.log("NFTMarketplaceV1 implementation deployed at:", address(marketplaceV1));

        // 3. 部署代理合约
        console.log("Deploying Proxy...");
        SimpleProxy proxy = new SimpleProxy(address(marketplaceV1));
        console.log("Proxy deployed at:", address(proxy));

        // 获取代理合约实例
        marketplaceV1 = NFTMarketplaceV1(address(proxy));

        // 铸造测试 NFT
        console.log("Minting test NFTs...");
        nft.mint(deployer);
        nft.mint(deployer);
        console.log("Test NFTs minted");

        // 授权市场合约
        console.log("Approving marketplace...");
        nft.setApprovalForAll(address(proxy), true);
        console.log("Marketplace approved");

        vm.stopBroadcast();

        // 保存部署信息
        _saveDeploymentInfo(
            address(nft),
            address(marketplaceV1),
            address(proxy),
            deployer
        );
    }

    function _saveDeploymentInfo(
        address nftAddress,
        address implementationV1,
        address proxy,
        address deployer
    ) internal {
        string memory deploymentInfo = string(abi.encodePacked(
            "Network: ", vm.toString(block.chainid), "\n",
            "Deployer: ", vm.toString(deployer), "\n",
            "Deployment Time: ", vm.toString(block.timestamp), "\n\n",
            "MyNFT: ", vm.toString(nftAddress), "\n",
            "Marketplace V1 Implementation: ", vm.toString(implementationV1), "\n",
            "Proxy: ", vm.toString(proxy), "\n"
        ));

        vm.writeFile("deployments/deployment-info.txt", deploymentInfo);
        console.log("Deployment info saved to deployments/deployment-info.txt");
    }
}