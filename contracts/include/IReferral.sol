pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IReferral {
    function getCommission(address user, uint256 total) external returns (address to, uint256 amount);
}
