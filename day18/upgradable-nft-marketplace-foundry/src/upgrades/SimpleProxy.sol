// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleProxy {
    address public implementation;
    address public admin;
    
    event Upgraded(address indexed implementation);

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
        
        // 直接调用初始化
        (bool success, ) = _implementation.delegatecall(
            abi.encodeWithSignature("initialize()")
        );
        require(success, "Initialization failed");
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function upgradeTo(address _implementation) external onlyAdmin {
        implementation = _implementation;
        emit Upgraded(_implementation);
    }

    fallback() external payable {
        address _implementation = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}