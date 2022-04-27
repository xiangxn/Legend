pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../Structs.sol";

interface IRole {
    /**
    @notice 获取角色id
    @param user 角色所有者地址
     */
    function getRoleId(address user) external view returns (uint256 roleId);

    /**
    @notice 进入矿洞
    @param user 角色所有者地址
    @param time 进入的时间(小时)
     */
    function inMine(address user, uint256 time) external;

    /**
    @notice 进入副本
    @param user 角色所有者地址
    @param time 进入的时间(小时)
     */
    function inZone(address user, uint256 time) external;

    /**
    @notice 退出矿洞或者副本
    @param user 角色所有者地址
    @param exp 获得的经验
     */
    function stopWorking(address user, uint32 exp) external;

    /**
    @notice 创建角色
    @param name 角色名
    @param gender 性别
    @param profession 职业
    @param tokenType 创建时所有token类型(1.USDT,2.LGC)
     */
    function create(
        string calldata name,
        uint8 gender,
        uint8 profession,
        uint32 tokenType
    ) external payable;

    function packet(uint256 heroId) external;

    function activation(uint256 heroId) external;

    function upgrade(uint256 heroId) external;

    function burn(uint256 heroId) external;

    /**
    @notice 获取角色信息
    @param id 角色id
     */
    function getHeroInfo(uint256 id) external view returns (CurrentHero memory hero, HeroAttrs memory attrs);
    function getHeroInfo(address addr) external view returns (CurrentHero memory hero, HeroAttrs memory attrs);

    /**
    @notice 获取角色战力(必须为当前绑定角色)
    @param roleAddr 角色绑定的地址(操作人地址)
     */
    function getHeroPower(address roleAddr) external view returns(uint32 power);

    /**
    @notice 更新装备为装备
    @param heroId 角色id
    @param newIds 新装备上的装备id 数组
    */
    function equip(uint256 heroId, uint256[] calldata newIds) external;
}
