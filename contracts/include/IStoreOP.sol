// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//商店用NFT铸造接口
interface IStoreOP {
    function mint(
        address to,
        uint256 quantity,
        bytes calldata data
    ) external;
}
