pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./ContractOwner.sol";
import "./Manager.sol";

abstract contract Permission is ContractOwner {
    modifier CheckPermit(string memory permit) {
        require(manager.permits(msg.sender, permit), "no permit");
        _;
    }

    modifier CheckPermit2(string[2] memory permits) {
        bool flag = false;
        for (uint256 i = 0; i != permits.length; i++) {
            flag = manager.permits(msg.sender, permits[i]);
            if (flag) break;
        }
        require(flag, "no permit");
        _;
    }
    modifier CheckPermit3(string[3] memory permits) {
        bool flag = false;
        for (uint256 i = 0; i != permits.length; i++) {
            flag = manager.permits(msg.sender, permits[i]);
            if (flag) break;
        }
        require(flag, "no permit");
        _;
    }

    modifier CheckPermit4(string[4] memory permits) {
        bool flag = false;
        for (uint256 i = 0; i != permits.length; i++) {
            flag = manager.permits(msg.sender, permits[i]);
            if (flag) break;
        }
        require(flag, "no permit");
        _;
    }

    Manager public manager;

    function setManager(address addr) external OwnerOnly {
        require(addr != address(0), "zero address");
        manager = Manager(addr);
    }

    function getAddress(string memory key) public view returns (address) {
        return manager.members(key);
    }
}
