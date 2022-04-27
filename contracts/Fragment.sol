pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./lib/ERC1155.sol";
import "./lib/Utils.sol";
import "./include/ILockTokens.sol";
import "./lib/Permission.sol";
import "./lib/Uinteger.sol";
import "./include/IERC1155OP.sol";
import "./Structs.sol";
import "./include/IStoreOP.sol";

contract Fragment is ERC1155, Permission, IERC1155OP, ILockTokens, IStoreOP {
    // token id => token per fragment amount,每个类型中每个碎片的Token值
    mapping(uint256 => uint256) public override lockTokens;

    // token id => total supply
    mapping(uint256 => uint256) public totalSupply;

    // address => ids
    mapping(address => uint256[]) internal ownerTokens;

    constructor() {
        uriPrefix = "https://source.legendnft.com/fragment/";
    }

    function getInfo(uint256 tokenId, address owner) public view returns (uint256 tokens, uint256 balance) {
        tokens = lockTokens[tokenId];
        balance = balanceOf(owner, tokenId);
    }

    function tokensOf(
        address owner,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (uint256[] memory) {
        require(owner != address(0), "owner is zero address");

        uint256[] storage tokens = ownerTokens[owner];
        if (endIndex == 0) {
            return tokens;
        }

        require(startIndex < endIndex, "invalid index");

        uint256[] memory result = new uint256[](endIndex - startIndex);
        for (uint256 i = startIndex; i != endIndex; ++i) {
            result[i] = tokens[i];
        }

        return result;
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 perTokens
    ) public override CheckPermit("zoneMine") {
        lockTokens[tokenId] = perTokens;
        totalSupply[tokenId] += amount;
        _addTokenTo(to, tokenId, amount);
        _addToIds(tokenId, to);
        emit TransferSingle(address(0), address(0), to, tokenId, amount);
    }

    function _addToIds(uint256 tokenId, address owner) internal {
        uint256[] storage tokens = ownerTokens[owner];
        bool f;
        for (uint256 i = 0; i != tokens.length; i++) {
            if (tokens[i] == tokenId) f = true;
        }
        if (!f) tokens.push(tokenId);
    }

    function mint(
        address to,
        uint256 quantity,
        bytes calldata data
    ) public override CheckPermit("store") {
        require(data.length == 41, "Invalid data");
        uint8 bigType = Utils.toUint8(data, 0);
        uint64 smallType = Utils.toUint64(data, 1);
        uint256 tokens = Utils.toUint256(data, 9); //token数量(带精度)或者其他业务数据(不带精度)
        uint256 tokenId = (uint256(bigType) << 248) | (uint256(smallType) << 184);
        // assert(tokenId == 0);
        lockTokens[tokenId] = tokens;
        totalSupply[tokenId] += quantity;
        _addTokenTo(to, tokenId, quantity);
        _addToIds(tokenId, to);
        emit TransferSingle(address(0), address(0), to, tokenId, quantity);
    }

    function _removeIdsFrom(address from, uint256 tokenId) private {
        if (balances[tokenId][from] == 0) {
            uint256 index;
            uint256[] storage tokenIds = ownerTokens[from];
            for (uint256 i = 0; i != tokenIds.length; i++) {
                if (tokenIds[i] == tokenId) {
                    index = i;
                    break;
                }
            }
            if (tokenIds.length > 1) {
                uint256 indexLast = tokenIds.length - 1;
                uint256 tokenIdLast = tokenIds[indexLast];
                tokenIds[index] = tokenIdLast;
                tokenIds.pop();
            } else {
                delete ownerTokens[from];
            }
        }
    }

    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) public override {
        require(from == msg.sender || operatorApproval[from][msg.sender] == true, "Need operator approval for 3rd party burn.");
        totalSupply[tokenId] -= amount;
        _removeTokenFrom(from, tokenId, amount);
        _removeIdsFrom(from, tokenId);
        emit TransferSingle(msg.sender, from, address(0), tokenId, amount);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) public virtual override {
        super.safeTransferFrom(_from, _to, _id, _value, _data);
        _removeIdsFrom(_from, _id);
        _addToIds(_id, _to);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) public virtual override {
        super.safeBatchTransferFrom(_from, _to, _ids, _values, _data);
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            _removeIdsFrom(_from, id);
            _addToIds(id, _to);
        }
    }
}
