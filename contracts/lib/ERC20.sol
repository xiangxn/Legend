pragma solidity ^0.8.0;

// SPDX-License-Identifier: Apache-2.0

import "../include/IERC20.sol";
import "./ContractOwner.sol";

contract ERC20 is IERC20, ContractOwner {
    string public override name;
    string public override symbol;
    uint8 public override decimals;

    uint256 public override totalSupply;
    uint256 public remainedSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _maxSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        remainedSupply = _maxSupply;
    }

    function _burn(address from, uint256 amount) internal {
        require(balanceOf[from] >= amount, "balance not enough");

        balanceOf[from] -= amount;
        totalSupply -= amount;
        remainedSupply += amount;

        emit Transfer(from, address(0), amount);
    }

    function burnFrom(address from, uint256 amount) public {
        require(allowance[from][msg.sender] >= amount, "allowance not enough");

        allowance[from][msg.sender] -= amount;
        _burn(from, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(to != address(0), "zero address");
        require(balanceOf[from] >= amount, "balance not enough");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(allowance[from][msg.sender] >= amount, "allowance not enough");

        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "zero address");

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }
}
