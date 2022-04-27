const Store = artifacts.require("Store");
const USDT = artifacts.require("USDT");
const Fragment = artifacts.require("Fragment");
const Box = artifacts.require("Box");
const BonusPool = artifacts.require("BonusPool");
const Equipment = artifacts.require("Equipment");

contract("Store test", async accounts => {

    const bigType = 3;
    const smallType = 1;
    const tokens = 10;
    const goodsId = 1;

    it("add goods", async () => {
        let store = await Store.deployed();
        let usdt = await USDT.deployed();
        let fragment = await Fragment.deployed();
        let box = await Box.deployed();
        let result = await store.addGoods({
            "settlementCurrency": usdt.address,
            "contractAddress": fragment.address,
            "quantityCount": 1000,
            "unitPrice": web3.utils.toWei("1", "ether"),
            "quantitySold": 0,
            //"data": "0x03000000000000000a0000000000000000000000000000000000000000000000000de0b6b3a7640000"
            "data": web3.utils.padLeft(web3.utils.toHex(bigType), 2) + web3.utils.padLeft(web3.utils.toHex(smallType).substr(2), 16) + web3.utils.padLeft(web3.utils.toHex(tokens).substr(2), 64)
            // "data": web3.eth.abi.encodeParameters(['uint8', 'uint64', 'uint256'], [3, 10, web3.utils.toWei("10", "ether")])
        }, goodsId);
        console.log("txHash: ", result.tx);
        result = await store.addGoods({
            "settlementCurrency": usdt.address,
            "contractAddress": box.address,
            "quantityCount": 1000,
            "unitPrice": web3.utils.toWei("10", "ether"),
            "quantitySold": 0,
            "data": web3.utils.padLeft(web3.utils.toHex(1), 4)
        }, goodsId + 1);

    });

    it("buy goods", async () => {
        let teller = "0x051B0CFc19489D738C2EDB48d550CcD65843D021";
        let store = await Store.deployed();
        let usdt = await USDT.deployed();
        let bonusPool = await BonusPool.deployed();
        let fragment = await Fragment.deployed();
        let box = await Box.deployed();
        let equipment = await Equipment.deployed();
        //发行usdt
        await usdt.mint(accounts[0], web3.utils.toWei("1000", "ether"));
        //授权usdt给商店
        await usdt.approve(store.address, web3.utils.toWei("12300000", "ether"));
        //购买一个消耗品
        let result = await store.buy(goodsId, 1);
        console.log("txHash: ", result.tx);
        //获取出纳地址余额
        let balance = await usdt.balanceOf(teller);
        //获取奖池地址余额
        let bpBalance = await usdt.balanceOf(bonusPool.address);
        assert.equal(web3.utils.fromWei(balance, "ether"), "0.2");
        assert.equal(web3.utils.fromWei(bpBalance, "ether"), "0.8");
        //计算商品token id
        let tokenId = web3.utils.toBN(bigType).shln(248).or(web3.utils.toBN(smallType).shln(184)).toString()
        console.log("tokenId: ", tokenId);
        //获取tokenId的余额
        let fBalance = await fragment.balanceOf(accounts[0], tokenId);
        assert.equal(fBalance.toString(), "1");
        //获取tokenId的uri
        let uri = await fragment.uri(tokenId);
        console.log("uri: ", uri);

        //购买一个装备箱
        result = await store.buy(2, 2);
        console.log("txHash: ", result.tx);
        //获取出纳地址余额
        balance = await usdt.balanceOf(teller);
        //获取奖池地址余额
        bpBalance = await usdt.balanceOf(bonusPool.address);
        assert.equal(web3.utils.fromWei(balance, "ether"), "4.2");
        assert.equal(web3.utils.fromWei(bpBalance, "ether"), "16.8");
        //获取地址的装备箱数
        fBalance = await box.balanceOf(accounts[0]);
        assert.equal(fBalance.toString(), "2");
        //获取装备箱token id列表
        let ts = await box.tokensOf(accounts[0], 0, 0);
        for (let m = 0; m < ts.length; m++) {
            console.log("item: ", ts[m].toString());
            uri = await box.tokenURI(ts[m].toString());
            console.log("box uri: ", uri);
        };

        //开箱一个装备箱
        if (ts.length > 0) {
            result = await box.open(ts[0]);
            // console.log(result);
            let amount = await equipment.balanceOf(accounts[0]);
            console.log("equipment amount: ", amount);
            let equips = await equipment.tokensOf(accounts[0], 0, 0);
            for (let n = 0; n < equips.length; n++) {
                console.log("equip id: ", equips[n].toString());
                let equip = await equipment.equipments(equips[n]);
                console.log(equip);
            };
        }



    });


});