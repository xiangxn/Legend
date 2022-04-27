// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/ERC20.sol";
import "./include/IERC20OP.sol";

contract USDT is ERC20, IERC20OP {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _maxSupply
    ) ERC20(_name, _symbol, _decimals, _maxSupply) {}

    function mint(address to, uint256 amount) external override OwnerOnly {
        require(to != address(0), "zero address");
        require(remainedSupply >= amount, "mint too much");

        remainedSupply -= amount;
        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }
}
