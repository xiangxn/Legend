pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IERC1155OP {
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 perTokens
    ) external;

    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external;
}
