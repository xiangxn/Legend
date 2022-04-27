pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IERC721OP {
    function burn(uint256 tokenId) external;

    function mint(address to, uint256 tokenId) external;
}
