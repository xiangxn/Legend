
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
const { padLeft, toHex, toWei, fromWei, toBN } = web3.utils;

module.exports = async (deployer, network, accounts) => {

  //收藏品
  let totem = await Totem.deployed();
  let bonusPool = await BonusPool.deployed();

  //获取奖池期号
  console.log("获取奖池期号....");
  let number = await bonusPool.number();
  let info = await bonusPool.getPeriod(number.toNumber());
  let now = Math.floor(Date.now() / 1000);
  if (parseInt(info.endTime) < now) {
    await bonusPool.open();
    number = await bonusPool.number();
  }
  console.log("当前期号:", number.toNumber());

  console.log("发送图腾中....");
  let tokenId = padLeft(toHex(1), 2) + padLeft(toHex(1), 16).substr(2) + padLeft(toHex(number.toNumber()), 8).substr(2) + padLeft("0", 38);
  await totem.mint(accounts[1], tokenId, 0);

  tokenId = padLeft(toHex(1), 2) + padLeft(toHex(2), 16).substr(2) + padLeft(toHex(number.toNumber()), 8).substr(2) + padLeft("0", 38);
  await totem.mint(accounts[1], tokenId, 0);
  await totem.mint(accounts[1], tokenId, 0);

  tokenId = padLeft(toHex(1), 2) + padLeft(toHex(3), 16).substr(2) + padLeft(toHex(number.toNumber()), 8).substr(2) + padLeft("0", 38);
  await totem.mint(accounts[1], tokenId, 0);
  await totem.mint(accounts[1], tokenId, 0);
  await totem.mint(accounts[1], tokenId, 0);
  await totem.mint(accounts[1], tokenId, 0);
  await totem.mint(accounts[1], tokenId, 0);
  console.log("开始兑奖。。。");

  let trs = [];
  let balances = await totem.tokensOf(accounts[1], 0, 0);

  balances.forEach(tId => {trs.push(totem.safeTransferFrom(accounts[1], bonusPool.address, tId.toString(), padLeft(toHex(3), 2), { from: accounts[1] }))});
  Promise.all(trs).then((value) => {
    console.log("兑奖完成！")
    USDT.at("0xa71edc38d189767582c38a3145b5873052c3e47a").then(usdt=>{
      usdt.balanceOf(accounts[1]).then(userb=>{
        usdt.balanceOf(bonusPool.address).then(bpb=>{
          console.log("地址余额:", fromWei(userb, "ether"), "奖池余额:", fromWei(bpb, "ether"));
        });
      });
    });
  });
};