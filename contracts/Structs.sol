pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

//角色职业
enum Profession {
    //角色上无意义，装备上为通用
    None,
    //战士
    Warrior,
    //法师
    Mage,
    //道士
    Taoism
}
//角色性别
enum Gender {
    //男
    Men,
    //女
    Women
}

//角色状态
enum HeroStatus {
    //空闲
    None,
    //矿洞
    Mine,
    //副本
    Zone
}
//支付操作类型
enum Operate {
    //空白值无意义
    None,
    //合成收藏品
    Composite,
    //销毁收藏品/碎片
    Burn,
    //兑换收藏品
    Redeem,
    //进入角色矿洞
    RoleMine,
    //进入副本
    ZoneMine,
    //使用经验丹
    ExpMedicine,
    //创建角色
    CreateHero,
    //买道具
    BuyProps,
    //赠送
    Handsel
}

//创建英雄的Token配置
struct TokenInfo {
    //创建英雄的费用
    uint256 fee;
    //币种地址配置Key
    string key;
}

//角色状态信息
struct CurrentHero {
    //角色id
    uint256 tokenId;
    //角色状态
    uint8 status;
    //进入时间
    uint64 startTime;
    //进入时的消耗道具购买的时间(单位：小时)
    uint32 time;
}

struct MainAttrs {
    //物理攻击
    uint32 attack;
    //道术攻击
    uint32 taoism;
    //魔法攻击
    uint32 magic;
    //物理防御
    uint32 defense;
    //魔法防御
    uint32 magicDefense;
    //体力值
    uint32 physicalPower;
    //魔力值
    uint32 magicPower;
}

struct HeroAttrs {
    //职业
    uint8 profession;
    //性别
    uint8 gender;
    //名字
    string name;
    //经验
    uint32 exp;
    //下一级所需经验
    uint32 upExp;
    //当前等级
    uint32 level;
    //战斗力
    uint32 power;
    //装备槽,目前length=8,依次为[头盔，项链，盔甲，武器,手镯L,手镯R,戒指L，戒指R]
    uint256[] equipmentSlot;
    //主属性
    MainAttrs mainAttrs;
}

//装备类型/部位
enum EquipmentType {
    //武器
    Arms,
    //头盔
    Helmet,
    //盔甲
    Armor,
    //项链
    Necklace,
    //戒指
    Ring,
    //手镯
    Bracelet
}
//装备品质
enum EquipQuality {
    //普通
    General,
    //银龙
    Silver,
    //金龙
    Gold
}
//碎片类型
enum FragmentType {
    None,
    //奖池碎片
    BonusPool,
    //艺术品碎片
    ArtworkPool
}

//装备属性
struct EquipmentAttr {
    //装备编号
    uint32 number;
    //职业
    uint8 profession;
    //装备类型/部位
    uint8 category;
    //装备品质
    uint8 quality;
    //是否锁定
    bool locked;
    //是否装备
    bool isEquip;
    //锁定的token数量
    uint256 tokens;
    //战力
    uint32 power;
    //等级
    uint32 level;
    //当前强化次数
    uint32 increaseCount;
    //最高强化次数
    uint32 increaseMax;
    //套装Id
    uint32 suitId;
    //套装编号
    uint32 suitNumber;
    //主属性
    MainAttrs mainAttrs;
}

//套装属性
struct SuitAttr {
    //套装编号组
    uint32[] numbers;
    //套装装备属性
    MainAttrs mainAttrs;
}

//角色等级信息
struct LevelInfo {
    //当前等级经验
    uint32 exp;
    //升下一级所需经验
    uint32 nextExp;
}

//碎片信息
struct FragmentInfo {
    //大类：奖池、艺术品
    uint8 fType;
    //类型/艺术品编号
    uint64 id;
    //期号
    uint32 number;
    //剩余的碎片数
    uint32 lastFragmentCount;
    //每个碎片锁定的tokens
    uint256 tokens;
}
