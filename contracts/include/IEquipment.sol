pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../Structs.sol";

interface IEquipment {
    /**
    @notice 发行装备
    @param to 目标地址
    @param attr 装备属性
    */
    function mint(address to, EquipmentAttr memory attr) external;

    /**
    @notice 更新装备为装备状态
    @param operator 操作者地址
    @param level 角色当前等级
    @param newIds 新装备上的装备id 数组
    @param oldIds 之前装备上的装备id数组
    */
    function equip(
        address operator,
        uint32 level,
        uint256[] calldata newIds,
        uint256[] calldata oldIds
    ) external returns(uint32 power);

    function getEquipment(uint256 tokenId) external view returns (uint256 id, EquipmentAttr memory attrs);
}
