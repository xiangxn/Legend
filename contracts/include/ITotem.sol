pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface ITotem {

    function mint(
        address to,
        uint256 tokenId,
        uint256 tokens
    ) external;

    function burn(uint256 tokenId) external;
}
