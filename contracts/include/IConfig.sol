pragma solidity ^0.8.0;

// SPDX-License-Identifier: Apache-2.0

import "../Structs.sol";

interface IConfig {
    /**
        The highest possible hero level
     */
    function maxLevel() external view returns (uint32);

    /**
        @notice Get information about supported currencies
        @param tokenType Index of currencies that can be used to create heroes    
     */
    function getTokenInfo(uint32 tokenType) external view returns (TokenInfo memory);

    /**
        @notice Array subscript meaning: [hp,mp,defense, magicDefense, attack, magic, taoism, time, exp]
        @param level the hero current level
     */
    function getLevelInfo(uint32 level) external view returns (LevelInfo memory levelInfo);

    /**
        @notice 根据属性与等级计算装备战力
        @param level 等级
        @param mainAttrs 属性
    */
    function calcPower(uint32 level, MainAttrs memory mainAttrs) external view returns (uint32 power);

    //装备最高可强化等级[普通10,银龙20,金龙30]
    function getEquipMaxLevel() external view returns (uint32[3] memory);

    /**
    @notice 生成装备
    @param number 装备编号
    @param quality 装备品质
    */
    function getEquipmentInfo(uint32 number, uint8 quality) external view returns (EquipmentAttr memory attrs);

    /**
    @notice 在给定的编号范围中随机出装备
    @param quality 品质
    @param equipmentIds 装备编号范围列表
    @param seed 出现多个时随机用的种子
     */
    function searchEquipment(
        uint8 quality,
        uint32[] calldata equipmentIds,
        bytes calldata seed
    ) external view returns (EquipmentAttr memory equipment);

    /**
    @notice 获取装备强化属性区间
    @param level 等级区间
    @param quality 装备品质
    @param universal 是否为职业通用装备
     */
    function getIncreaseConfig(
        uint256 level,
        uint256 quality,
        bool universal
    ) external view returns (uint32[2] memory);
}
