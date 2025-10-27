// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract DebugScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        console.log("Block number:", block.number);
        console.log("Chain ID:", block.chainid);
        
        // 测试基础功能
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署简单的测试合约来验证环境
        SimpleTest test = new SimpleTest();
        console.log("SimpleTest deployed at:", address(test));
        
        vm.stopBroadcast();
    }
}

contract SimpleTest {
    uint256 public value;
    
    constructor() {
        value = 42;
    }
    
    function getValue() public view returns (uint256) {
        return value;
    }
}