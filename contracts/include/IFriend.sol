// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFriend {
    function contains(address owner, address friend) external view returns (bool);

    function getHandselFee() external view returns (uint256);
}
