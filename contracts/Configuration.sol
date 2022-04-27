pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./lib/Permission.sol";
import "./Structs.sol";
import "./include/IConfig.sol";
import "./lib/Uinteger.sol";
import "./lib/Utils.sol";

contract Configuration is Permission, IConfig {
    //装备配置信息
    struct EquipmentConfig {
        //装备编号
        uint32 number;
        //装备等级
        uint16 level;
        //装备职业
        uint8 profession;
        //装备部位
        uint8 category;
    }
    //角色经验系数(1.35)
    int128 constant expCoe = 0x1599999999999a000;
    //角色战力系数(1.05)
    int128 constant powerCoe = 0x10cccccccccccd000;

    //属性基础系数(1.05)
    int128 constant attrCoe = 0x10cccccccccccd000;
    //武器物攻系数(0.5)
    int128 constant armsCoe = 0x8000000000000000;
    //盔甲物防系数(0.6)
    int128 constant armorCoe = 0x9999999999999800;
    //盔甲血量系数(1)
    int128 constant armorPhCoe = 0x10000000000000000;
    //头盔攻击系数(0.03)
    int128 constant helmetCeo = 0x7ae147ae147ae00;
    //头盔防御系数(0.2)
    int128 constant helmetDefenseCeo = 0x3333333333333400;
    //项链物攻系数(0.15)
    int128 constant necklaceCeo = 0x2666666666666600;
    //手镯攻击系数(0.06)
    int128 constant braceletCeo = 0xf5c28f5c28f5c00;
    //手镯防御系数(0.1)
    int128 constant braceletDefenseCeo = 0x1999999999999a00;
    //戒指攻击系数(0.06)
    int128 constant ringCeo = 0xf5c28f5c28f5c00;

    //角色最高等级
    uint32 public override maxLevel = 50;
    //创建角色的token配置
    mapping(uint32 => TokenInfo) private tokenInfos;

    //装备最高可强化次数[普通10,银龙30,金龙50]
    uint32[3] private equipMaxLevel = [uint32(10), 30, 50];

    //装备强化配置 等级区间(1-10为1,11-20为2,21-30为3,31-40为4,41-50为5)=>品质(普通1,银龙2,金龙3)=>属性区间
    mapping(uint256 => mapping(uint256 => uint32[2])) private increaseConfig;
    //通用装备强化配置
    mapping(uint256 => mapping(uint256 => uint32[2])) private increaseUniversalConfig;

    /*
    装备配置表
    装备编号 => 装备配置
    */
    mapping(uint256 => EquipmentConfig) private equipmentConfigs;

    constructor() {
        //创建角色费用配置
        tokenInfos[0] = TokenInfo({fee: 5 * (10**17), key: ""});
        tokenInfos[1] = TokenInfo({fee: 10 * (10**18), key: "Token"});
        tokenInfos[2] = TokenInfo({fee: 1 * (10**18), key: "USDT"});
        
        //装备属性配置
        for (uint256 i = 1; i != 10; i++) {
            equipmentConfigs[10000 + i] = EquipmentConfig(uint32(10000 + i), uint16(i * 5), 1, 0);
            equipmentConfigs[10009 + i] = EquipmentConfig(uint32(10009 + i), uint16(i * 5), 2, 0);
            equipmentConfigs[10018 + i] = EquipmentConfig(uint32(10018 + i), uint16(i * 5), 3, 0);
        }
        equipmentConfigs[10028] = EquipmentConfig(10028, 2, 0, 2);
        equipmentConfigs[10029] = EquipmentConfig(10029, 12, 0, 2);
        for (uint256 i = 1; i != 5; i++) {
            equipmentConfigs[10029 + i] = EquipmentConfig(uint32(10029 + i), uint16(12 + i * 10), 1, 2);
            equipmentConfigs[10033 + i] = EquipmentConfig(uint32(10033 + i), uint16(12 + i * 10), 3, 2);
            equipmentConfigs[10037 + i] = EquipmentConfig(uint32(10037 + i), uint16(12 + i * 10), 2, 2);
        }
        for (uint256 i = 1; i != 6; i++) {
            equipmentConfigs[10041 + i] = EquipmentConfig(uint32(10041 + i), uint16(7 + (i - 1) * 10), 1, 3);
            equipmentConfigs[10046 + i] = EquipmentConfig(uint32(10046 + i), uint16(7 + (i - 1) * 10), 3, 3);
            equipmentConfigs[10051 + i] = EquipmentConfig(uint32(10051 + i), uint16(7 + (i - 1) * 10), 2, 3);
        }
        equipmentConfigs[10057] = EquipmentConfig(10057, 6, 0, 1);
        equipmentConfigs[10058] = EquipmentConfig(10058, 16, 0, 1);
        equipmentConfigs[10059] = EquipmentConfig(10059, 26, 0, 1);
        equipmentConfigs[10060] = EquipmentConfig(10060, 36, 1, 1);
        equipmentConfigs[10061] = EquipmentConfig(10061, 46, 1, 1);
        equipmentConfigs[10062] = EquipmentConfig(10062, 36, 3, 1);
        equipmentConfigs[10063] = EquipmentConfig(10063, 46, 3, 1);
        equipmentConfigs[10064] = EquipmentConfig(10064, 36, 2, 1);
        equipmentConfigs[10065] = EquipmentConfig(10065, 46, 2, 1);
        for (uint256 i = 1; i != 6; i++) {
            equipmentConfigs[10065 + i] = EquipmentConfig(uint32(10065 + i), uint16(4 + (i - 1) * 10), 1, 5);
            equipmentConfigs[10070 + i] = EquipmentConfig(uint32(10070 + i), uint16(4 + (i - 1) * 10), 2, 5);
            equipmentConfigs[10075 + i] = EquipmentConfig(uint32(10075 + i), uint16(4 + (i - 1) * 10), 3, 5);
        }
        for (uint256 i = 1; i != 6; i++) {
            equipmentConfigs[10080 + i] = EquipmentConfig(uint32(10080 + i), uint16(9 + (i - 1) * 10), 1, 4);
            equipmentConfigs[10085 + i] = EquipmentConfig(uint32(10085 + i), uint16(9 + (i - 1) * 10), 3, 4);
            equipmentConfigs[10090 + i] = EquipmentConfig(uint32(10090 + i), uint16(9 + (i - 1) * 10), 2, 4);
        }
        //装备强化配置
        increaseConfig[1][1] = [1, 3];
        increaseConfig[2][1] = [3, 6];
        increaseConfig[3][1] = [5, 9];
        increaseConfig[4][1] = [8, 16];
        increaseConfig[5][1] = [15, 26];

        increaseConfig[1][2] = [3, 9];
        increaseConfig[2][2] = [9, 18];
        increaseConfig[3][2] = [15, 27];
        increaseConfig[4][2] = [24, 54];
        increaseConfig[5][2] = [45, 75];

        increaseConfig[1][3] = [6, 18];
        increaseConfig[2][3] = [18, 36];
        increaseConfig[3][3] = [30, 54];
        increaseConfig[4][3] = [48, 96];
        increaseConfig[5][3] = [90, 150];

        increaseUniversalConfig[1][1] = [1, 5];
        increaseUniversalConfig[2][1] = [3, 10];
        increaseUniversalConfig[3][1] = [6, 15];

        increaseUniversalConfig[1][2] = [3, 15];
        increaseUniversalConfig[2][2] = [12, 30];
        increaseUniversalConfig[3][2] = [18, 45];

        increaseUniversalConfig[1][3] = [6, 30];
        increaseUniversalConfig[2][3] = [18, 60];
        increaseUniversalConfig[3][3] = [36, 90];
    }

    //设置创建角色的费用与token
    function setTokenInfo(
        uint32 tokenType,
        string memory key,
        uint256 fee
    ) external CheckPermit("admin") {
        TokenInfo storage t = tokenInfos[tokenType];
        t.key = key;
        t.fee = fee;
    }

    /**
    @notice 设置装备配置
    @param number 装备编号
    @param config 装备配置信息
     */
    function setEquipmentConfig(uint256 number, EquipmentConfig calldata config) external CheckPermit("admin") {
        equipmentConfigs[number] = config;
    }

    function getEquipmentConfig(uint256 number) public view returns (EquipmentConfig memory) {
        return equipmentConfigs[number];
    }

    function getTokenInfo(uint32 tokenType) external view override returns (TokenInfo memory) {
        return tokenInfos[tokenType];
    }

    function setMaxLevel(uint32 value) external CheckPermit("admin") {
        maxLevel = value;
    }

    /**
        @notice 获取角色等级经验配置
        @param level 当前等级
     */
    function getLevelInfo(uint32 level) public pure override returns (LevelInfo memory levelInfo) {
        if (level > 0) {
            levelInfo.exp = uint32(((100 * level + level * Uinteger.toUInt(Uinteger.pow(expCoe, level))) / 100) * 100);
        }
        uint32 nl = level + 1;
        levelInfo.nextExp = uint32(((100 * nl + nl * Uinteger.toUInt(Uinteger.pow(expCoe, nl))) / 100) * 100);
    }

    //计算角色战力
    function calcPower(uint32 level, MainAttrs memory mainAttrs) public pure override returns (uint32 power) {
        int128 basePower =
            Uinteger.fromUInt((mainAttrs.physicalPower + mainAttrs.magicPower) / 100 + (mainAttrs.defense + mainAttrs.magicDefense + mainAttrs.attack + mainAttrs.magic + mainAttrs.taoism) * 3);
        // power = uint32(basePower * Uinteger.toUInt(Uinteger.pow(powerCoe, level)));
        power = uint32(Uinteger.toUInt(Uinteger.mul(basePower, Uinteger.pow(powerCoe, level))));
    }

    function getEquipMaxLevel() external view override returns (uint32[3] memory) {
        return equipMaxLevel;
    }

    function getEquipmentInfo(uint32 number, uint8 quality) public view override returns (EquipmentAttr memory attrs) {
        EquipmentConfig storage ec = equipmentConfigs[number];
        attrs.number = ec.number;
        attrs.profession = ec.profession;
        attrs.category = ec.category;
        attrs.quality = quality;
        attrs.level = ec.level;
        attrs.increaseMax = equipMaxLevel[quality];
        //计算主属性
        int128 base = Uinteger.pow(attrCoe, attrs.level);
        int128 b2 = Uinteger.fromUInt(20 * 20);
        EquipmentType et = EquipmentType(attrs.category);
        Profession p = Profession(attrs.profession);
        uint32 a1;
        uint32 a2;
        if (et == EquipmentType.Arms) {
            a1 = uint32(Uinteger.toUInt(Uinteger.mul(b2, Uinteger.mul(armsCoe, base))));
        } else if (et == EquipmentType.Armor) {
            b2 = Uinteger.fromUInt(10 * 20);
            a2 = uint32(Uinteger.toUInt(Uinteger.mul(b2, Uinteger.mul(armorCoe, base))));
            attrs.mainAttrs.defense = a2;
            attrs.mainAttrs.magicDefense = a2;
            b2 = Uinteger.fromUInt(100 * 20);
            attrs.mainAttrs.physicalPower = uint32(Uinteger.toUInt(Uinteger.mul(b2, Uinteger.mul(armorPhCoe, base))));
            attrs.mainAttrs.magicPower = attrs.mainAttrs.physicalPower;
        } else if (et == EquipmentType.Helmet) {
            a1 = uint32(Uinteger.toUInt(Uinteger.mul(b2, Uinteger.mul(helmetCeo, base))));
            b2 = Uinteger.fromUInt(10 * 20);
            a2 = uint32(Uinteger.toUInt(Uinteger.mul(b2, Uinteger.mul(helmetDefenseCeo, base))));
            attrs.mainAttrs.defense = a2;
            attrs.mainAttrs.magicDefense = a2;
        } else if (et == EquipmentType.Necklace) {
            a1 = uint32(Uinteger.toUInt(Uinteger.mul(b2, Uinteger.mul(necklaceCeo, base))));
        } else if (et == EquipmentType.Bracelet) {
            a1 = uint32(Uinteger.toUInt(Uinteger.mul(b2, Uinteger.mul(braceletCeo, base))));
            b2 = Uinteger.fromUInt(10 * 20);
            a2 = uint32(Uinteger.toUInt(Uinteger.mul(b2, Uinteger.mul(braceletDefenseCeo, base))));
            attrs.mainAttrs.defense = a2;
            attrs.mainAttrs.magicDefense = a2;
        } else if (et == EquipmentType.Ring) {
            a1 = uint32(Uinteger.toUInt(Uinteger.mul(b2, Uinteger.mul(ringCeo, base))));
        }
        if (p == Profession.Warrior) {
            attrs.mainAttrs.attack = a1;
        } else if (p == Profession.Mage) {
            attrs.mainAttrs.magic = a1;
        } else if (p == Profession.Taoism) {
            attrs.mainAttrs.taoism = a1;
        }
        attrs.power = calcPower(attrs.level, attrs.mainAttrs);
    }

    function searchEquipment(
        uint8 quality,
        uint32[] calldata equipmentIds,
        bytes calldata seed
    ) external view override returns (EquipmentAttr memory equipment) {
        uint256 index = Utils.randomUint(seed, 0, equipmentIds.length - 1);
        equipment = getEquipmentInfo(equipmentIds[index], quality);
    }

    function getIncreaseConfig(
        uint256 level,
        uint256 quality,
        bool universal
    ) public view override returns (uint32[2] memory) {
        if (universal) {
            if (level <= 10) return increaseUniversalConfig[1][quality + 1];
            else if (level > 10 && level <= 20) return increaseUniversalConfig[2][quality + 1];
            else return increaseUniversalConfig[3][quality + 1];
        } else {
            if (level <= 10) return increaseConfig[1][quality + 1];
            else if (level > 10 && level <= 20) return increaseConfig[2][quality + 1];
            else if (level > 20 && level <= 30) return increaseConfig[3][quality + 1];
            else if (level > 30 && level <= 40) return increaseConfig[4][quality + 1];
            else return increaseConfig[5][quality + 1];
        }
    }

    function setIncreaseConfig(
        uint256 level,
        uint256 quality,
        bool universal,
        uint32[2] calldata data
    ) public CheckPermit("admin") {
        if (universal) {
            increaseUniversalConfig[level][quality + 1] = data;
        } else {
            increaseConfig[level][quality + 1] = data;
        }
    }
}
