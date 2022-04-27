pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IERC20OP {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}
