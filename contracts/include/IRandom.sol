pragma solidity ^0.8.0;

// SPDX-License-Identifier: Apache-2.0

interface IRandom {
    function register(uint256 data) external;
    function getRandom(uint256 data) external view returns(bytes32);
}