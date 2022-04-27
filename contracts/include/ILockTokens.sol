pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface ILockTokens {
    function lockTokens(uint256 tokenId) external view returns (uint256 amount);
}
