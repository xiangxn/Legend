
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
  
  //收藏品
  await deployer.deploy(Totem, "Test Totem", "TT");;
  //全局管理
  await deployer.deploy(Manager);
  
  let totem = await Totem.deployed();
  let bonusPool = await BonusPool.at("0x24FE31A6b1CB4b0e5ee3C5c20a1d1f21a652D404");
  let newManager = await Manager.deployed();
  let usdt = await USDT.at("0xa71edc38d189767582c38a3145b5873052c3e47a");
  // let oldManager = await Manager.at("0xB5742521aa6e1297bF46D5a1e95826aF06128F27");
  
  // 奖池合约地址
  await newManager.setMember("Bonus", bonusPool.address);
  // 收藏品合约地址
  await newManager.setMember("Totem", totem.address);
  await newManager.setMember("USDT", usdt.address);

  // admin管理员权限
  await newManager.setPermit(accounts[0], "admin", true);
  await newManager.setPermit(accounts[0], "bonus", true);
  // 奖池权限
  await newManager.setPermit(bonusPool.address, "bonus", true);

  await totem.setManager(newManager.address);
  await bonusPool.setManager(newManager.address);

};