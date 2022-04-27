pragma solidity ^0.8.0;

// SPDX-License-Identifier: Apache-2.0

import "../include/IERC165.sol";
import "../include/IERC721.sol";
import "../include/IERC721Metadata.sol";
import "../include/IERC721TokenReceiver.sol";

import "../lib/Address.sol";

abstract contract ERC721 is IERC165, IERC721, IERC721Metadata {
    using Address for address;

    /*
     * bytes4(keccak256("supportsInterface(bytes4)")) == 0x01ffc9a7
     */
    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    /*
     *     bytes4(keccak256("balanceOf(address)")) == 0x70a08231
     *     bytes4(keccak256("ownerOf(uint256)")) == 0x6352211e
     *     bytes4(keccak256("approve(address,uint256)")) == 0x095ea7b3
     *     bytes4(keccak256("getApproved(uint256)")) == 0x081812fc
     *     bytes4(keccak256("setApprovalForAll(address,bool)")) == 0xa22cb465
     *     bytes4(keccak256("isApprovedForAll(address,address)")) == 0xe985e9c5
     *     bytes4(keccak256("transferFrom(address,address,uint256)")) == 0x23b872dd
     *     bytes4(keccak256("safeTransferFrom(address,address,uint256)")) == 0x42842e0e
     *     bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_SIGNATURE_ERC721Metadata = 0x5b5e139f;
    bytes4 private constant ERC721_RECEIVER_RETURN = 0x150b7a02;

    string public override name;
    string public override symbol;

    //address => ids
    mapping(address => uint256[]) internal ownerTokens;
    mapping(uint256 => uint256) internal tokenIndexs;
    mapping(uint256 => address) internal tokenOwners;

    mapping(uint256 => address) internal tokenApprovals;
    mapping(address => mapping(address => bool)) internal approvalForAlls;

    uint256 public totalSupply = 0;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "owner is zero address");
        return ownerTokens[owner].length;
    }

    // [startIndex, endIndex)
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

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = tokenOwners[tokenId];
        require(owner != address(0), "nobody own the token");
        return owner;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable virtual override {
        _transferFrom(from, to, tokenId);

        if (to.isContract()) {
            require(IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) == ERC721_RECEIVER_RETURN, "onERC721Received() return invalid");
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        _transferFrom(from, to, tokenId);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(from != address(0), "from is zero address");
        require(to != address(0), "to is zero address");

        require(from == tokenOwners[tokenId], "from must be owner");

        require(msg.sender == from || msg.sender == tokenApprovals[tokenId] || approvalForAlls[from][msg.sender], "sender must be owner or approvaled");

        if (tokenApprovals[tokenId] != address(0)) {
            delete tokenApprovals[tokenId];
        }

        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    // ensure everything is ok before call it
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        uint256 index = tokenIndexs[tokenId];

        uint256[] storage tokens = ownerTokens[from];
        uint256 indexLast = tokens.length - 1;

        uint256 tokenIdLast = tokens[indexLast];
        tokens[index] = tokenIdLast;
        tokenIndexs[tokenIdLast] = index;

        tokens.pop();

        // delete tokenIndexs[tokenId]; // save gas
        delete tokenOwners[tokenId];
    }

    // ensure everything is ok before call it
    function _addTokenTo(address to, uint256 tokenId) internal {
        uint256[] storage tokens = ownerTokens[to];
        tokenIndexs[tokenId] = tokens.length;
        tokens.push(tokenId);

        tokenOwners[tokenId] = to;
    }

    function approve(address to, uint256 tokenId) public payable override {
        address owner = tokenOwners[tokenId];

        require(msg.sender == owner || approvalForAlls[owner][msg.sender], "sender must be owner or approved for all");

        tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) public override {
        approvalForAlls[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(tokenOwners[tokenId] != address(0), "nobody own then token");

        return tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return approvalForAlls[owner][operator];
    }

    function supportsInterface(bytes4 interfaceID) public pure virtual override returns (bool) {
        return interfaceID == INTERFACE_SIGNATURE_ERC165 || interfaceID == INTERFACE_SIGNATURE_ERC721 || interfaceID == INTERFACE_SIGNATURE_ERC721Metadata;
    }

    function _burn(uint256 tokenId) internal {
        address owner = tokenOwners[tokenId];
        _removeTokenFrom(owner, tokenId);

        if (tokenApprovals[tokenId] != address(0)) {
            delete tokenApprovals[tokenId];
        }

        emit Transfer(owner, address(0), tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        _addTokenTo(to, tokenId);
        ++totalSupply;
        emit Transfer(address(0), to, tokenId);
    }
}
