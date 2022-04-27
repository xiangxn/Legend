pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IReferralUpdate {
    //更新消费
    function updateConsume(address userAddr, uint256 amount) external;
}
