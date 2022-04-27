// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/ERC20.sol";
import "./lib/Permission.sol";
import "./include/IERC20OP.sol";
import "./include/IERC165.sol";
import "./include/IERC1363Receiver.sol";
import "./include/IERC1363Spender.sol";
import "./include/IERC1363.sol";
import "./lib/Address.sol";
import "./lib/ReentrancyGuard.sol";

contract LGC is ReentrancyGuard, ERC20, Permission, IERC20OP, IERC165, IERC1363 {
    using Address for address;

    //团队份额
    uint256 public team;
    //宣传活动
    uint256 public activity;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _maxSupply
    ) ERC20(_name, _symbol, _decimals, _maxSupply) {
        team = (_maxSupply * 10) / 100;
        activity = (_maxSupply * 25) / 100;
    }

    function mint(address to, uint256 amount) public override CheckPermit3(["equipment", "bonus", "artwork"]) {
        require(to != address(0), "zero address");
        require(remainedSupply >= amount, "mint too much");

        remainedSupply -= amount;
        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function teamClaim(address to, uint256 amount) public CheckPermit("team") {
        require(to != address(0), "zero address");
        require(team >= amount, "mint too much");

        team -= amount;
        remainedSupply -= amount;
        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function activityClaim(address to, uint256 amount) public CheckPermit("team") {
        require(to != address(0), "zero address");
        require(activity >= amount, "mint too much");

        activity -= amount;
        remainedSupply -= amount;
        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public override {
        _burn(msg.sender, amount);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1363).interfaceId;
    }

    function transferAndCall(address recipient, uint256 amount) public override returns (bool) {
        return transferAndCall(recipient, amount, "");
    }

    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public override returns (bool) {
        transfer(recipient, amount);
        require(_checkAndCallTransfer(msg.sender, recipient, amount, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }

    function transferFromAndCall(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        return transferFromAndCall(sender, recipient, amount, "");
    }

    function transferFromAndCall(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) public override returns (bool) {
        transferFrom(sender, recipient, amount);
        require(_checkAndCallTransfer(sender, recipient, amount, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }

    function approveAndCall(address spender, uint256 amount) public override returns (bool) {
        return approveAndCall(spender, amount, "");
    }

    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory data
    ) public override returns (bool) {
        approve(spender, amount);
        require(_checkAndCallApprove(spender, amount, data), "ERC1363: _checkAndCallApprove reverts");
        return true;
    }

    function _checkAndCallTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) internal nonReentrant virtual returns (bool) {
        if (!recipient.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Receiver(recipient).onTransferReceived(msg.sender, sender, amount, data);
        return (retval == IERC1363Receiver(recipient).onTransferReceived.selector);
    }

    function _checkAndCallApprove(
        address spender,
        uint256 amount,
        bytes memory data
    ) internal nonReentrant virtual returns (bool) {
        if (!spender.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(msg.sender, amount, data);
        return (retval == IERC1363Spender(spender).onApprovalReceived.selector);
    }
}
