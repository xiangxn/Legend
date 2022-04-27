// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Structs.sol";

interface IPeriod {
    function number() external view returns(uint32);
    function getPeriodFragment() external view returns (FragmentInfo[] memory fragmentInfos);
    function updateFragment(FragmentInfo calldata fi) external;
}
