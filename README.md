碎片合约：Fragment
    大类：1奖池碎片,2艺术品碎片,3消耗品
消耗品类型(碎片合约小类):1.矿镐，2.万年雪霜,3.经验丹,4.金疮药
消耗品ID规则:uint8(大类型) + uint64（小类型）

碎片/收藏品类型:1奖池,2艺术品,3消耗品...
奖池碎片编号: 1开始
碎片ID规则：uint8(大类型:奖池、艺术品、消耗品) + uint64（小类型、编号） + uint32(期号,消耗品无)

收藏品ID规则：uint8(大类型:奖池、艺术品) + uint64（小类型、编号） + uint32(期号) + uint128(发行编号)

装备ID规则：uint8(职业)+uint8(部位)+uint8(品质)...uint64(发行时间)+uint64(发行编号)

members: 账号/权限小写，合约大写
    "admin" 管理链上数据配置权限 setPermit(address,"admin",true)
    "roleMine" 角色矿洞权限
    "zoneMine" 副本权限
    "bonus" 奖池权限
    "store" 商店权限
    "box" 装备箱权限
    "artwork" 艺术品权限
    "equipment" 装备权限
    "system" 系统权限(业务逻辑)


    "Random" 随机数合约地址
    "Config" 全局配置合约地址
    "Token"  LE币合约地址
    "USDT" USDT币合约地址
    "Teller" 出纳账号地址
    "Role" 角色合约地址
    "Totem" 图腾合约地址
    "Fragment" 碎片合约地址
    "Bonus" 奖池合约地址
    "Equipment" 装备合约地址
    "Artwork" 艺术品合约地址
    "Store" 商店合约地址
    "Box" 装备箱合约地址
    "PreSale" 预售合约地址
    "Referral" 推荐合约地址


英雄 ID构造:
    uint8 + uint8 ... uint64 + uint64
    gender  profession ... timestamp  totalSupply

一、全局配置项: 
    1.角色最高等级(maxlevel)
    2.经验配置(experience)


testnet
address: {
        USDT: "0xEB5a311D4c3bE8bFa307e3DaD0C8873A3E42B354",
        Hero: "0x33c0483158E780E9b3d8d986BB499dFcCB6EfB11",
        Equipment: "0x726f37505093De917dcafFcd477BCDCD71b0692A",
        LGC: "0x51857e3111eEF80429445F32A8cc341B735e2a52",
        StakeMine: "0x51A70b92879D1BC5EA388b10B3385C78C5BD1C46",
        RoleMine: "0xEd7CD4bE790038Df8be95Db37A62AA9656B826BB",
        ZoneMine: "0xd6C10A624A217Da98B95082F58A5AbB003FC0223",
        BonusPool: "0x745Ae5D363B939Dd4A19E032273d881AAa35e726",
        Fragment: "0x49c77052fF4BfBB6532A9172c5DD6D045c1C7493",
        Totem: "0xE3eBaAB7C8550b511dE47ac7D73b4b24f7Ed647F",
        Store: "0x18ac3133376Ee5D851Ee57ac902f4085f856BC32",
        Box: "0x23Ad2898ACD93AFBab43b24679B5fF6FBacD9976",
        PreSale: "0x90834f1e7CAcB5200a714d7394BfF482b525353A",
        Friend: "0x022A52330aEBC38735F72c4aE07E5588251494B0",
        Market: "0xFcbD99A497C4ebeC62dA06d8beeB94Be737bb7C3"
    }
local
    address: {
        USDT: "0x79Cb0Ef35Cb7c1ae503b151aB9881B07Bf4285bd",
        Hero: "0x690dc0C346eC7383d96Bd196a45d512EBFC248B4",
        Equipment: "0xE54851E0EaC0DECccE0F6eeE59AE051c28C89491",
        LGC: "0x33A51564b8Ae4546eAD1673E6CDB2d31518A7e5E",
        StakeMine: "0x9FcfF1AfFc676BE3D085f17DBF4314616c9d172d",
        RoleMine: "0x96474a61fD54cbCd26497e423Ff4993611b3ab56",
        ZoneMine: "0xFE3dF1c7d1663956968602051ad849eC76231fe5",
        BonusPool: "0x2BA211242bdFd2205e3b6Aae86fa1aa46c3FBa6A",
        Fragment: "0x6A0beaf5aaAe5A66282788f5e44552B3Dd3eB0F9",
        Totem: "0x0c91c0Ad6204e5e551A703e7bdCE60712619657e",
        Store: "0xc3826119150B035eC9171B5A5fbf9C484Adb460E",
        Box: "0x733BE9e827723ec33CeF00956E19a05e3bd0C07a",
        PreSale: "0xAe1674205056e7FA0C45197E82290570859A4F49",
        Friend: "0x9d7d52DA48e7ee2a3e608F9607561524451E00C8",
        Market: "0xdA816F2e628E3e0d261445282C6ce582C5E48147"
    },

hecoMain
    address:{
        USDT: "0xa71edc38d189767582c38a3145b5873052c3e47a",
        Hero: "0xef349B6b61F7BEABB061ae2B0bF50F06c262d718",
        Equipment: "0xfd52bE427836f31259D8D347AB9410Bf390c8A04",
        LGC: "0xb7A819D170e59D79f6289b91cA1D1a9D0C788A2a",
        StakeMine: "0x6C234aE7E4beaa7816Dfe89efa45094CCDFbA19D",
        RoleMine: "0x672B71f169AbF20448aaC3acA6C0BAaD337C2fF5",
        ZoneMine: "0x6528eB45D88a25dB650953F6986Cde9bbfba9219",
        BonusPool: "0x13368543dc96195Dc564048DFd598F12AbbC7662",
        Fragment: "0x6C5aD71809c8fA3b6dB9dcC02efe825A33869C33",
        Totem: "0x49De5A35ee679Ea1BF9C27a2CFF85AA220be1527",
        Store: "0xB4BE2df64ca360F0aA5cf6EDFbB58bF5F39182D1",
        Box: "0xAEe308fAb21D185691Fe4ec7dd503a601383586E",
        PreSale: "0x275eeC0aF74F3c5c0562807E57D4cC4625F9a7b9",
        Friend: "0x8C6492E2d9D5404D2b46ffc9f7E6342ADE4602a1",
        Market: "0x18Beb70Ec025fdDc084C3c0E6d6cB30615dE3113"
    }

原奖池地址：0x24FE31A6b1CB4b0e5ee3C5c20a1d1f21a652D404

    : 0xDeE245EbB9C4A9553CE1579b7412Eb6E223daAA3
    usdt.mint("0xDeE245EbB9C4A9553CE1579b7412Eb6E223daAA3",web3.utils.toWei("100000","ether"))

    : 0x2Cb313963e3a3441f31D9E123972167e26CF44A0
    usdt.mint("0x2Cb313963e3a3441f31D9E123972167e26CF44A0",web3.utils.toWei("100000","ether"))

    : 0x03296472B69e23388162882546a279707fC51d35
    usdt.mint("0x03296472B69e23388162882546a279707fC51d35",web3.utils.toWei("100000","ether"))

    : 0xe79D177265528793d945924f4a1fC7FEC4d00ffC
    usdt.mint("0xe79D177265528793d945924f4a1fC7FEC4d00ffC",web3.utils.toWei("100000","ether"))

    : 0x408fA5883b54DF198Aac1A47D3cBF85a17087d63
    usdt.mint("0x408fA5883b54DF198Aac1A47D3cBF85a17087d63",web3.utils.toWei("100000","ether"))

    jianan: 0x14CB9C551EA696BBb2200c6e172eF3E0d27bedeA
    usdt.mint("0x14CB9C551EA696BBb2200c6e172eF3E0d27bedeA",web3.utils.toWei("100000","ether"))




    预售装备配置
    [10001,10010,10019,10002,10011,10020,10003,10012,10021,10004,10013,10022,10005,10014,10023,10006,10015,10024],[10057,10058,10059],[10028,10029,10030,10034,10038],[10042,10047,10052,10043,10048,10053,10044,10049,10054],[10081,10086,10091,10082,10087,10092,10083,10088,10093],[10066,10071,10076,10067,10072,10077,10068,10073,10078]



    store.addGoods({"settlementCurrency": lgc.address,"contractAddress": fragment.address,"quantityCount": 200000,"unitPrice": web3.utils.toWei("0.5", "ether"),"quantitySold": 0,"data": web3.utils.padLeft(web3.utils.toHex(3), 2) + web3.utils.padLeft(web3.utils.toHex(3).substr(2), 16)+ web3.utils.padLeft(web3.utils.toHex(100).substr(2), 64)}, 9)


    store.addGoods({"settlementCurrency": usdt.address,"contractAddress": box.address,"quantityCount": 2000,"unitPrice": web3.utils.toWei("30", "ether"),"quantitySold": 0,"data":web3.utils.padLeft(web3.utils.toHex(7), 4)}, 10)



    let putOn=web3.eth.abi.encodeParameters(['uint8',{"Goods":{"id":"uint256","class":"uint8","status":"uint8","price":"uint256","amount":"uint32","seller":"address","buyer":"address","contentId":"uint256","payContract":"address"}}],[1,{"id":0,"class":1,"status":1,"price":web3.utils.toWei("10","ether"),"amount":1,"seller":accounts[1],"buyer":"0x0000000000000000000000000000000000000000","contentId":"1365772781073691086767888968074276012734645052314782234890092273563559002115","payContract":"0xb895492c775e9448B1a45519F3ba8Cd8B76304e7"}])

    equip.safeTransferFrom(accounts[0],"0xF9A3997897d13A8F1cc4AdD95BE2eC1bf2E492fF","1365772781073691086767888968074276012734645052314782234890092273563559002115",putOn)

    let buyPars=web3.eth.abi.encodeParameters(["uint8","uint256"],[2,2])

    stakeMine.addPool("0x0000000000000000000000000000000000000002", "0xc4cc2edb6039b11280b1D09cf49775Da7fA10F71", 1622562586, 604800, reward);

    store.addGoods({"settlementCurrency":lgc.address,"contractAddress":fragment.address,"quantityCount":100000,"unitPrice":toWei("5","ether"),"quantitySold":0,"data":padLeft(toHex(3),2)+padLeft(toHex(4).substr(2),16)+padLeft(toHex(0).substr(2),64)}, 11);