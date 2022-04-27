
const Random = artifacts.require("Random");
const LGC = artifacts.require("LGC");
const USDT = artifacts.require("USDT");
const Uinteger = artifacts.require("Uinteger");
const Manager = artifacts.require("Manager");
const Configuration = artifacts.require("Configuration");
const Hero = artifacts.require("Hero");
const Equipment = artifacts.require("Equipment");

const StakeMine = artifacts.require("StakeMine");
const RoleMine = artifacts.require("RoleMine");
const ZoneMine = artifacts.require("ZoneMine");
const BonusPool = artifacts.require("BonusPool");
const Fragment = artifacts.require("Fragment");
const Totem = artifacts.require("Totem");
const Store = artifacts.require("Store");
const Box = artifacts.require("Box");
const PreSale = artifacts.require("PreSale");
const Friend = artifacts.require("Friend");
const Market = artifacts.require("Market");
const Referral = artifacts.require("Referral");
const { padLeft, toHex, toWei } = web3.utils;

module.exports = async (deployer, network, accounts) => {
  //随机数合约
  await deployer.deploy(Random);
  //uint类库
  await deployer.deploy(Uinteger);
  await deployer.link(Uinteger, Hero);
  //配置
  await deployer.deploy(Configuration);
  if (network == "development" || network == "testnet" || network == "hsctest") {
    //usdt
    await deployer.deploy(USDT, "test usdt", "USDT", 18, toWei("10000000000", "ether"));
  }
  //角色
  await deployer.deploy(Hero, "Legend Role", "ROLE");
  //装备
  await deployer.deploy(Equipment, "Legend Equipment", "LE");
  //主token
  await deployer.deploy(LGC, "Legend Game Coin", "LGC", 18, toWei("100000000", "ether"));
  //质押矿洞
  await deployer.deploy(StakeMine);
  //角色矿洞
  await deployer.deploy(RoleMine);
  //副本
  await deployer.deploy(ZoneMine);
  //奖池
  await deployer.deploy(BonusPool);
  //碎片
  await deployer.deploy(Fragment);
  //收藏品
  await deployer.deploy(Totem, "Legend Totem", "LT");
  //商店
  await deployer.deploy(Store);
  //装备箱
  await deployer.deploy(Box, "Legend Box", "LB");
  //全局管理
  await deployer.deploy(Manager);

  //预售
  await deployer.deploy(PreSale);

  //好友
  await deployer.deploy(Friend);

  //市场
  await deployer.deploy(Market);

  //推荐
  await deployer.deploy(Referral);


  let random = await Random.deployed();
  let usdt;
  if (network == "development" || network == "testnet" || network == "hsctest") {
    usdt = await USDT.deployed();
  } else if (network == "hecomain") {
    usdt = await USDT.at("0xa71edc38d189767582c38a3145b5873052c3e47a");//heco主网的USDT
  }

  let config = await Configuration.deployed();
  let lgc = await LGC.deployed();
  let hero = await Hero.deployed();
  let equipment = await Equipment.deployed();
  let stakeMine = await StakeMine.deployed();
  let roleMine = await RoleMine.deployed();
  let zoneMine = await ZoneMine.deployed();
  let bonusPool = await BonusPool.deployed();
  let fragment = await Fragment.deployed();
  let totem = await Totem.deployed();
  let store = await Store.deployed();
  let box = await Box.deployed();
  let manager = await Manager.deployed();
  let preSale = await PreSale.deployed();
  let friend = await Friend.deployed();
  let market = await Market.deployed();
  let referral = await Referral.deployed();

  // 全局管理
  // 随机数合约地址
  await manager.setMember("Random", random.address);
  // usdt contract address
  await manager.setMember("USDT", usdt.address);
  // config contract address
  await manager.setMember("Config", config.address);
  // LGC token
  await manager.setMember("Token", lgc.address);
  // Teller account
  if (network == "development") {
    await manager.setMember("Teller", accounts[1]);
  } else if (network == "hecomain" || network == "testnet" || network == "hsctest") {
    await manager.setMember("Teller", "0x30a10D380C13eC1558F2460eC2aA0BD16F06E771");
  }

  // role contract address
  await manager.setMember("Role", hero.address);
  // 装备合约地址
  await manager.setMember("Equipment", equipment.address);
  // 奖池合约地址
  await manager.setMember("Bonus", bonusPool.address);
  // 碎片/消耗品合约地址
  await manager.setMember("Fragment", fragment.address);
  // 收藏品合约地址
  await manager.setMember("Totem", totem.address);
  // 商店地址
  await manager.setMember("Store", store.address);
  // 装备箱地址
  await manager.setMember("Box", box.address);
  // 预售合约地址
  await manager.setMember("PreSale", preSale.address);
  // 好友合约地址
  await manager.setMember("Friend", friend.address);
  // 市场合约地址
  await manager.setMember("Market", market.address);
  // 推荐合约地址
  await manager.setMember("Referral", referral.address);

  // admin管理员权限
  await manager.setPermit(accounts[0], "admin", true);
  // team团队权限
  await manager.setPermit(accounts[0], "team", true);
  // 角色矿洞权限
  await manager.setPermit(roleMine.address, "roleMine", true);
  // 副本权限
  await manager.setPermit(zoneMine.address, "zoneMine", true);
  // 奖池权限
  await manager.setPermit(bonusPool.address, "bonus", true);
  // 商店权限
  await manager.setPermit(store.address, "store", true);
  // 装备箱权限（用于开箱装备）
  await manager.setPermit(box.address, "box", true);
  // 装备权限
  await manager.setPermit(equipment.address, "equipment", true);
  // 预售(权限同store)
  await manager.setPermit(preSale.address, "store", true);
  // 推荐(权限同store)
  await manager.setPermit(referral.address, "store", true);

  await hero.setManager(manager.address);
  await config.setManager(manager.address);
  await stakeMine.setManager(manager.address);
  await roleMine.setManager(manager.address);
  await zoneMine.setManager(manager.address);
  await bonusPool.setManager(manager.address);
  await fragment.setManager(manager.address);
  await totem.setManager(manager.address);
  await equipment.setManager(manager.address);
  await lgc.setManager(manager.address);
  await store.setManager(manager.address);
  await box.setManager(manager.address);
  await preSale.setManager(manager.address);
  await friend.setManager(manager.address);
  await market.setManager(manager.address);
  await referral.setManager(manager.address);

  //初始化基础数据
  const bigType = 3;//大类3(1奖池碎片,2艺术品碎片,3消耗品)
  const smallType = 1;//小类1(1.矿镐，2.万年雪霜,3.经验丹,4.金疮药)
  const tokens = 10;//装备箱中每个装备锁定的token
  const goodsId = 1;
  //添加奖池的奖项
  //一等奖一个占总奖金的50%
  await bonusPool.addAwards(0, {
    "types": 1,
    "count": 1,
    "redeemedCount": 0,
    "fragmentCount": 10,
    "lastFragmentCount": 10,
    "ratio": 35,
    "bonus": 0
  });
  //二等奖两个占总奖金的30%
  await bonusPool.addAwards(1, {
    "types": 2,
    "count": 2,
    "redeemedCount": 0,
    "fragmentCount": 10,
    "lastFragmentCount": 10,
    "ratio": 30,
    "bonus": 0
  });
  //三等奖五个占总奖金的20%
  await bonusPool.addAwards(2, {
    "types": 3,
    "count": 5,
    "redeemedCount": 0,
    "fragmentCount": 15,
    "lastFragmentCount": 15,
    "ratio": 15,
    "bonus": 0
  });
  //四等奖20个占总奖金的20%
  await bonusPool.addAwards(3, {
    "types": 4,
    "count": 20,
    "redeemedCount": 0,
    "fragmentCount": 40,
    "lastFragmentCount": 40,
    "ratio": 20,
    "bonus": 0
  });
  //添加装备箱类别配置
  //(入门武器箱)
  await box.addCategories(1, {
    "equipmentIds": [[10001, 10002, 10010, 10011, 10019, 10020], [], [], [], [], []],  //配置的装备编号列表
    "quality": [72, 24, 4],//装备品质随机权重:[普通,银龙,金龙],总合100
    "categoryQuality": [100, 0, 0, 0, 0, 0],
    "minQuantity": 1,//每个装备箱的最少装备件数
    "maxQuantity": 1,//每个装备箱的最多装备件数
    "tokens": toWei(tokens.toString(), "ether")//装备中锁定的token数量
  });
  //(普通武器箱)
  await box.addCategories(2, {
    "equipmentIds": [[10003, 10004, 10012, 10013, 10021, 10022], [], [], [], [], []],
    "quality": [72, 24, 4],
    "categoryQuality": [100, 0, 0, 0, 0, 0],
    "minQuantity": 1,
    "maxQuantity": 1,
    "tokens": toWei(tokens.toString(), "ether")
  });
  //(稀有武器箱)
  await box.addCategories(3, {
    "equipmentIds": [[10005, 10006, 10014, 10015, 10023, 10024], [], [], [], [], []],
    "quality": [72, 24, 4],
    "categoryQuality": [100, 0, 0, 0, 0, 0],
    "minQuantity": 1,
    "maxQuantity": 1,
    "tokens": toWei(tokens.toString(), "ether")
  });
  //(入门甲胄箱)
  await box.addCategories(4, {
    // [10028, 10042, 10047, 10052, 10057, 10066, 10071, 10076, 10081, 10086, 10091],
    "equipmentIds": [[], [10057], [10028], [10042, 10047, 10052], [10081, 10086, 10091], [10066, 10071, 10076]],
    "quality": [100],
    "categoryQuality": [0, 14, 9, 20, 30, 27],//[武器,头盔,盔甲,项链,戒指,手镯]
    "minQuantity": 1,
    "maxQuantity": 1,
    "tokens": toWei("5", "ether")
  });
  //(普通甲胄箱)
  await box.addCategories(5, {
    // [10029, 10043, 10048, 10053, 10058, 10067, 10072, 10077, 10082, 10087, 10092],
    "equipmentIds": [[], [10058], [10029], [10043, 10048, 10053], [10082, 10087, 10092], [10067, 10072, 10077]],
    "quality": [90, 10],
    "categoryQuality": [0, 14, 9, 20, 30, 27],
    "minQuantity": 1,
    "maxQuantity": 1,
    "tokens": toWei("10", "ether")
  });
  //(稀有甲胄箱)
  await box.addCategories(6, {
    // [10030, 10034, 10038, 10044, 10049, 10054, 10059, 10068, 10073, 10078, 10083, 10088, 10093],
    "equipmentIds": [[], [10059], [10030, 10034, 10038], [10044, 10049, 10054], [10083, 10088, 10093], [10068, 10073, 10078]],
    "quality": [72, 28],
    "categoryQuality": [0, 14, 9, 20, 30, 27],
    "minQuantity": 1,
    "maxQuantity": 1,
    "tokens": toWei("25", "ether")
  });
  //预售箱子
  await box.addCategories(7, {
    "equipmentIds": [[10001, 10010, 10019, 10002, 10011, 10020, 10003, 10012, 10021, 10004, 10013, 10022], [10057, 10058], [10028, 10029], [10042, 10047, 10052, 10043, 10048, 10053], [10081, 10086, 10091, 10082, 10087, 10092], [10066, 10071, 10076, 10067, 10072, 10077]],
    "quality": [72, 24, 4],
    "categoryQuality": [2, 9, 12, 20, 27, 30],
    "minQuantity": 3,
    "maxQuantity": 3,
    "tokens": toWei("32.5", "ether")
  });
  //赤月武器箱子
  await box.addCategories(8, {
    "equipmentIds": [[10007, 10016, 10025, 10008, 10017, 10026, 10009, 10018, 10027], [], [], [], [], []],
    "quality": [72, 24, 4],
    "categoryQuality": [2, 9, 12, 20, 27, 30],
    "minQuantity": 1,
    "maxQuantity": 1,
    "tokens": toWei("1", "ether")
  });

  //添加商店商品
  //添加矿镐
  await store.addGoods({
    "settlementCurrency": usdt.address,
    "contractAddress": fragment.address,
    "quantityCount": 100000,
    "unitPrice": toWei("1", "ether"),//单价
    "quantitySold": 0,
    "data": padLeft(toHex(bigType), 2) + padLeft(toHex(smallType).substr(2), 16) + padLeft(toHex(0).substr(2), 64)
  }, goodsId);
  //添加万年雪霜
  await store.addGoods({
    "settlementCurrency": usdt.address,
    "contractAddress": fragment.address,
    "quantityCount": 100000,
    "unitPrice": toWei("1", "ether"),//单价
    "quantitySold": 0,
    "data": padLeft(toHex(bigType), 2) + padLeft(toHex(smallType + 1).substr(2), 16) + padLeft(toHex(0).substr(2), 64)
  }, goodsId + 1);
  //添加入门武器箱
  await store.addGoods({
    "settlementCurrency": usdt.address,
    "contractAddress": box.address,
    "quantityCount": 100000,
    "unitPrice": toWei("10", "ether"),
    "quantitySold": 0,
    "data": padLeft(toHex(1), 4)//装备箱类别
  }, goodsId + 2);
  //普通武器箱
  await store.addGoods({
    "settlementCurrency": usdt.address,
    "contractAddress": box.address,
    "quantityCount": 100000,
    "unitPrice": toWei("20", "ether"),
    "quantitySold": 0,
    "data": padLeft(toHex(2), 4)//装备箱类别
  }, goodsId + 3);
  //稀有武器箱
  await store.addGoods({
    "settlementCurrency": usdt.address,
    "contractAddress": box.address,
    "quantityCount": 100000,
    "unitPrice": toWei("30", "ether"),
    "quantitySold": 0,
    "data": padLeft(toHex(3), 4)//装备箱类别
  }, goodsId + 4);
  //入门甲胄箱
  await store.addGoods({
    "settlementCurrency": lgc.address,
    "contractAddress": box.address,
    "quantityCount": 100000,
    "unitPrice": toWei("10", "ether"),
    "quantitySold": 0,
    "data": padLeft(toHex(4), 4)//装备箱类别
  }, goodsId + 5);
  //普通甲胄箱
  await store.addGoods({
    "settlementCurrency": lgc.address,
    "contractAddress": box.address,
    "quantityCount": 100000,
    "unitPrice": toWei("20", "ether"),
    "quantitySold": 0,
    "data": padLeft(toHex(5), 4)//装备箱类别
  }, goodsId + 6);
  //稀有甲胄箱
  await store.addGoods({
    "settlementCurrency": lgc.address,
    "contractAddress": box.address,
    "quantityCount": 100000,
    "unitPrice": toWei("50", "ether"),
    "quantitySold": 0,
    "data": padLeft(toHex(6), 4)//装备箱类别
  }, goodsId + 7);

  //添加经验丹
  await store.addGoods({
    "settlementCurrency": lgc.address,
    "contractAddress": fragment.address,
    "quantityCount": 100000,
    "unitPrice": toWei("1", "ether"),//单价
    "quantitySold": 0,
    "data": padLeft(toHex(bigType), 2) + padLeft(toHex(smallType + 2).substr(2), 16) + padLeft(toHex(100).substr(2), 64)//每颗增加的经验值
  }, goodsId + 8);

  //添加金疮药
  await store.addGoods({
    "settlementCurrency": lgc.address,
    "contractAddress": fragment.address,
    "quantityCount": 100000,
    "unitPrice": toWei("5", "ether"),//单价
    "quantitySold": 0,
    "data": padLeft(toHex(bigType), 2) + padLeft(toHex(smallType + 3).substr(2), 16) + padLeft(toHex(0).substr(2), 64)
  }, goodsId + 10);

  //预售箱
  await preSale.addGoods({
    "settlementCurrency": usdt.address,//USDT支付
    "contractAddress": box.address,
    "quantityCount": 2000,
    "unitPrice": toWei("30", "ether"),
    "quantitySold": 0,
    "data": padLeft(toHex(7), 4)//装备箱类别
  }, 10);

  // 添加副本配置
  let fragmentId2 = padLeft(toHex(3), 2) + padLeft(toHex(2), 16).substr(2) + padLeft("0", 46); //万年雪霜
  let fragmentId4 = padLeft(toHex(3), 2) + padLeft(toHex(4), 16).substr(2) + padLeft("0", 46); //金疮药
  await zoneMine.setOutputInfo(1000, { "weight": 0, "maxAmount": 0, "lastCount": 0 });
  await zoneMine.addZone({
    "id": 1000,
    "name": "比奇森林",
    "consumablesId": fragmentId4,//门票id
    "consumablesAmount": 1,
    "baseExp": 50,
    "level": 0,
    "minPower": 0,
    "equipmentNumber": [10028, 10066, 10071, 10076, 10001, 10010, 10019, 10057],
    "probability": [2, 12, 9, 20, 30, 27],
    "quality": [72, 24, 4],
    "profession": [33, 33, 34],
    "dropRateBase": 15000,
    "tokenTotal": toWei("10000", "ether"),
    "tokens": 0,
    "tokenBase": 1,
    "startTime": Math.floor(Date.now() / 1000),
    "endTime": Math.floor(Date.now() / 1000) + 604800
  });

  await zoneMine.setOutputInfo(1001, { "weight": 20, "maxAmount": 4, "lastCount": 0 });
  await zoneMine.addZone({
    "id": 1001,
    "name": "骷髅洞",
    "consumablesId": fragmentId2,//门票id
    "consumablesAmount": 1,
    "baseExp": 200,
    "level": 5,
    "minPower": 1500,
    "equipmentNumber": [10042, 10047, 10052, 10081, 10086, 10091, 10002, 10011, 10020],
    "probability": [2, 12, 9, 20, 30, 27],
    "quality": [72, 24, 4],
    "profession": [33, 34, 33],
    "dropRateBase": 40000,
    "tokenTotal": toWei("50000", "ether"),
    "tokens": 0,
    "tokenBase": 1,
    "startTime": Math.floor(Date.now() / 1000),
    "endTime": Math.floor(Date.now() / 1000) + 604800
  });

  await zoneMine.setOutputInfo(1002, { "weight": 20, "maxAmount": 7, "lastCount": 0 });
  await zoneMine.addZone({
    "id": 1002,
    "name": "僵尸洞",
    "consumablesId": fragmentId2,//门票id
    "consumablesAmount": 2,
    "baseExp": 1000,
    "level": 10,
    "minPower": 5600,
    "equipmentNumber": [10029, 10067, 10072, 10077, 10003, 10012, 10021, 10058, 10043, 10048, 10053, 10082, 10087, 10092, 10004, 10013, 10022],
    "probability": [2, 12, 9, 20, 30, 27],
    "quality": [72, 24, 4],
    "profession": [34, 33, 33],
    "dropRateBase": 130000,
    "tokenTotal": toWei("50000", "ether"),
    "tokens": 0,
    "tokenBase": 1,
    "startTime": Math.floor(Date.now() / 1000),
    "endTime": Math.floor(Date.now() / 1000) + 604800
  });

  await zoneMine.setOutputInfo(1003, { "weight": 20, "maxAmount": 12, "lastCount": 0 });
  await zoneMine.addZone({
    "id": 1003,
    "name": "蜈蚣洞",
    "consumablesId": fragmentId2,//门票id
    "consumablesAmount": 3,
    "baseExp": 10000,
    "level": 20,
    "minPower": 18000,
    "equipmentNumber": [10030, 10034, 10038, 10068, 10073, 10078, 10005, 10014, 10023, 10059, 10044, 10049, 10054, 10083, 10088, 10093],
    "probability": [2, 12, 9, 20, 30, 27],
    "quality": [72, 24, 4],
    "profession": [33, 33, 34],
    "dropRateBase": 320000,
    "tokenTotal": toWei("50000", "ether"),
    "tokens": 0,
    "tokenBase": 1,
    "startTime": Math.floor(Date.now() / 1000),
    "endTime": Math.floor(Date.now() / 1000) + 604800
  });

  await zoneMine.setOutputInfo(1004, { "weight": 20, "maxAmount": 19, "lastCount": 0 });
  await zoneMine.addZone({
    "id": 1004,
    "name": "石墓阵",
    "consumablesId": fragmentId2,//门票id
    "consumablesAmount": 4,
    "baseExp": 100000,
    "level": 30,
    "minPower": 50000,
    "equipmentNumber": [10006, 10015, 10024, 10031, 10035, 10039, 10069, 10074, 10079, 10007, 10016, 10025, 10060, 10062, 10064, 10045, 10050, 10055, 10084, 10089, 10094],
    "probability": [2, 12, 9, 20, 30, 27],
    "quality": [72, 24, 4],
    "profession": [33, 34, 33],
    "dropRateBase": 900000,
    "tokenTotal": toWei("80000", "ether"),
    "tokens": 0,
    "tokenBase": 2,
    "startTime": Math.floor(Date.now() / 1000),
    "endTime": Math.floor(Date.now() / 1000) + 604800
  });

  await zoneMine.setOutputInfo(1005, { "weight": 20, "maxAmount": 33, "lastCount": 0 });
  await zoneMine.addZone({
    "id": 1005,
    "name": "赤月洞穴",
    "consumablesId": fragmentId2,//门票id
    "consumablesAmount": 5,
    "baseExp": 2000000,
    "level": 40,
    "minPower": 150000,
    "equipmentNumber": [10008, 10017, 10026, 10032, 10036, 10040, 10070, 10075, 10080, 10061, 10063, 10065, 10046, 10051, 10056, 10085, 10090, 10095],
    "probability": [2, 12, 9, 20, 30, 27],
    "quality": [72, 24, 4],
    "profession": [34, 33, 33],
    "dropRateBase": 2000000,
    "tokenTotal": toWei("80000", "ether"),
    "tokens": 0,
    "tokenBase": 2,
    "startTime": Math.floor(Date.now() / 1000),
    "endTime": Math.floor(Date.now() / 1000) + 604800
  });

  //设置市场支持的token合约
  await market.setSupportCoin(usdt.address);
  await market.setSupportCoin(lgc.address);

  if (network == "development" || network == "testnet" || network == "hsctest") {
    //发行usdt
    await usdt.mint(accounts[0], toWei("1000000", "ether"));
    //授权给奖池
    await usdt.approve(bonusPool.address, toWei("100000", "ether"));
    //注入奖池
    await bonusPool.injectCapital(toWei("100000", "ether"));
    //开启一期奖池
    await bonusPool.open(0);
    //发行lgc
    await lgc.activityClaim(accounts[0], toWei("10000", "ether"));

    //添加一个usdt单币池
    let reward = toWei("50000", "ether");
    // await stakeMine.addPool(usdt.address, parseInt(Date.now() / 1000), 604800, reward);
    await stakeMine.addPool("0x0000000000000000000000000000000000000001", usdt.address, parseInt(Date.now() / 1000), 604800, reward);
    //发行lgc给stakemine合约
    await lgc.activityClaim(stakeMine.address, reward);
    //开启一期角色矿洞
    reward = toWei("100000", "ether");
    await roleMine.addPool("0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", parseInt(Date.now() / 1000), 2592000, reward);
    //rm .addPool("0x0000000000000000000000000000000000000000",1621612799,2592000,"99242911978851034757002")
    //发行lgc给rolemine合约
    await lgc.activityClaim(roleMine.address, reward);
  }

  await preSale.setEndTime(parseInt(Date.now() / 1000) + 86400);

  //设置推荐系统
  //设置引荐人配置
  await referral.setRefConfig({ "id": 0, "level": 1, "ratio": 50, "boxType": 4, "boxAmount": 1, "validAmount": toWei("10", "ether"), "validUserCount": 5 });
  await referral.setRefConfig({ "id": 0, "level": 2, "ratio": 80, "boxType": 5, "boxAmount": 1, "validAmount": toWei("10", "ether"), "validUserCount": 20 });
  await referral.setRefConfig({ "id": 0, "level": 3, "ratio": 100, "boxType": 5, "boxAmount": 3, "validAmount": toWei("10", "ether"), "validUserCount": 50 });
  await referral.setRefConfig({ "id": 0, "level": 4, "ratio": 120, "boxType": 6, "boxAmount": 1, "validAmount": toWei("10", "ether"), "validUserCount": 100 });
  await referral.setRefConfig({ "id": 0, "level": 5, "ratio": 160, "boxType": 6, "boxAmount": 2, "validAmount": toWei("10", "ether"), "validUserCount": 150 });
  await referral.setRefConfig({ "id": 0, "level": 6, "ratio": 200, "boxType": 6, "boxAmount": 3, "validAmount": toWei("10", "ether"), "validUserCount": 200 });
  await referral.setRefConfig({ "id": 0, "level": 7, "ratio": 250, "boxType": 3, "boxAmount": 1, "validAmount": toWei("10", "ether"), "validUserCount": 250 });
  await referral.setRefConfig({ "id": 0, "level": 8, "ratio": 300, "boxType": 3, "boxAmount": 3, "validAmount": toWei("10", "ether"), "validUserCount": 300 });
  await referral.setRefConfig({ "id": 0, "level": 9, "ratio": 400, "boxType": 3, "boxAmount": 5, "validAmount": toWei("10", "ether"), "validUserCount": 400 });
  await referral.setRefConfig({ "id": 0, "level": 10, "ratio": 500, "boxType": 3, "boxAmount": 10, "validAmount": toWei("10", "ether"), "validUserCount": 500 });
  //设置被引荐人配置
  await referral.setRefUserConfig({ "id": 0, "condition": 1, "consumeAmount": toWei("10", "ether"), "level": 10, "boxType": 1, "boxAmount": 1 });
  await referral.setRefUserConfig({ "id": 0, "condition": 1, "consumeAmount": toWei("30", "ether"), "level": 20, "boxType": 2, "boxAmount": 1 });
  await referral.setRefUserConfig({ "id": 0, "condition": 1, "consumeAmount": toWei("50", "ether"), "level": 30, "boxType": 3, "boxAmount": 1 });
  await referral.setRefUserConfig({ "id": 0, "condition": 1, "consumeAmount": toWei("300", "ether"), "level": 40, "boxType": 8, "boxAmount": 1 });
  await referral.setRefUserConfig({ "id": 0, "condition": 1, "consumeAmount": toWei("1000", "ether"), "level": 50, "boxType": 8, "boxAmount": 3 });

  if (network == "development") {
    zoneMine.setRewardTime(6);
  }
};