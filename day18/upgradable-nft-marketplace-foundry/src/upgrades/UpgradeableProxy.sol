// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract UpgradeableProxy {
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    constructor(address _implementation, address _admin, bytes memory _data) {
        _setImplementation(_implementation);
        _setAdmin(_admin);
        
        if (_data.length > 0) {
            (bool success, ) = _implementation.delegatecall(_data);
            require(success, "Initialization call failed");
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "Caller is not the admin");
        _;
    }

    function _getImplementation() internal view returns (address) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        address implementation;
        assembly {
            implementation := sload(slot)
        }
        return implementation;
    }

    function _setImplementation(address _implementation) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _implementation)
        }
    }

    function _getAdmin() internal view returns (address) {
        bytes32 slot = ADMIN_SLOT;
        address admin;
        assembly {
            admin := sload(slot)
        }
        return admin;
    }

    function _setAdmin(address _admin) internal {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, _admin)
        }
    }

    function upgradeTo(address _implementation) external onlyAdmin {
        _setImplementation(_implementation);
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    fallback() external payable {
        address implementation = _getImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}