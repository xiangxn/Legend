pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./lib/Uinteger.sol";
import "./lib/Permission.sol";
import "./lib/ERC721.sol";
import "./include/ILockTokens.sol";
import "./include/IERC20OP.sol";
import "./include/ITotem.sol";

contract Totem is ERC721, Permission, ILockTokens, ITotem {
    using Uinteger for uint256;

    string public uriPrefix = "https://source.legendnft.com/totem/";

    // token id => erc20 token value
    mapping(uint256 => uint256) public override lockTokens;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        string memory uri = string(abi.encodePacked(uriPrefix, tokenId.toString(), ".json"));
        return uri;
    }

    //用户不要直接调用此方法
    function burn(uint256 tokenId) public override {
        address owner = tokenOwners[tokenId];
        require(msg.sender == owner || msg.sender == tokenApprovals[tokenId] || approvalForAlls[owner][msg.sender], "msg.sender must be owner or approved");
        _burn(tokenId);
        delete lockTokens[tokenId];
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 tokens
    ) external override CheckPermit2(["bonus", "artwork"]) {
        uint256 id = tokenId | uint128(totalSupply + 1);
        lockTokens[id] = tokens;
        _mint(to, id);
    }
}
