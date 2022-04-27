pragma solidity ^0.8.0;

// SPDX-License-Identifier: Apache-2.0

import "../include/IRandom.sol";
import "./ContractOwner.sol";

/**
 * Utility library of inline functions on addresses
 */
contract Random is IRandom, ContractOwner {
    uint256 internal constant maskLast8Bits = uint256(0x00000000000000000000000000000000000000000000000000000000000000FF);
    uint256 internal constant maskFirst248Bits = uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00);

    mapping(uint256 => bytes32) public randoms;

    event Register(uint256 blockNumber);

    function register(uint256 blockNumber) external override {
        randoms[blockNumber] = bytes32(0);
        emit Register(blockNumber);
    }

    function getRandom(uint256 blockNumber) external view override returns (bytes32) {
        bytes32 randomN = randoms[blockNumber];
        if (randomN == 0) {
            randomN = blockhash(blockNumber);
            if (randomN == 0) {
                blockNumber = (block.number & maskFirst248Bits) + (blockNumber & maskLast8Bits);
                if (blockNumber >= block.number) blockNumber -= 256;
                randomN = blockhash(blockNumber);
            }
            // randoms[data] = randomN;
        }
        return keccak256(abi.encode(randomN, blockNumber));
    }

    function feed(uint256 blockNumber, bytes32 blockHash) external OwnerOnly {
        require(blockNumber != 0, "zero block number");
        require(blockHash != 0, "zero block hash");
        randoms[blockNumber] = blockHash;
    }

    function setOwner(address newOwner) external OwnerOnly {
        require(newOwner != address(0), "zero address");
        contractOwner = newOwner;
    }
}
