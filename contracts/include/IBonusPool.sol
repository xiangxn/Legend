// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Structs.sol";

interface IBonusPool {
    // 奖金滚存
    function total() external view returns (uint256);

    // 当前期奖金
    function current() external view returns (uint256);

    // 返奖比例
    function rebateRatio() external view returns (uint32);

    // 返奖周期
    function bonusDuration() external view returns (uint32);

    // 每碎片Token数量
    function perFragmentToken() external view returns (uint256);

    // 注入奖金
    function injectCapital(uint256 value) external;
}
