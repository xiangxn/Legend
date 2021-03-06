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
        //??????usdt
        await usdt.mint(accounts[0], web3.utils.toWei("1000", "ether"));
        //??????usdt?????????
        await usdt.approve(store.address, web3.utils.toWei("12300000", "ether"));
        //?????????????????????
        let result = await store.buy(goodsId, 1);
        console.log("txHash: ", result.tx);
        //????????????????????????
        let balance = await usdt.balanceOf(teller);
        //????????????????????????
        let bpBalance = await usdt.balanceOf(bonusPool.address);
        assert.equal(web3.utils.fromWei(balance, "ether"), "0.2");
        assert.equal(web3.utils.fromWei(bpBalance, "ether"), "0.8");
        //????????????token id
        let tokenId = web3.utils.toBN(bigType).shln(248).or(web3.utils.toBN(smallType).shln(184)).toString()
        console.log("tokenId: ", tokenId);
        //??????tokenId?????????
        let fBalance = await fragment.balanceOf(accounts[0], tokenId);
        assert.equal(fBalance.toString(), "1");
        //??????tokenId???uri
        let uri = await fragment.uri(tokenId);
        console.log("uri: ", uri);

        //?????????????????????
        result = await store.buy(2, 2);
        console.log("txHash: ", result.tx);
        //????????????????????????
        balance = await usdt.balanceOf(teller);
        //????????????????????????
        bpBalance = await usdt.balanceOf(bonusPool.address);
        assert.equal(web3.utils.fromWei(balance, "ether"), "4.2");
        assert.equal(web3.utils.fromWei(bpBalance, "ether"), "16.8");
        //???????????????????????????
        fBalance = await box.balanceOf(accounts[0]);
        assert.equal(fBalance.toString(), "2");
        //???????????????token id??????
        let ts = await box.tokensOf(accounts[0], 0, 0);
        for (let m = 0; m < ts.length; m++) {
            console.log("item: ", ts[m].toString());
            uri = await box.tokenURI(ts[m].toString());
            console.log("box uri: ", uri);
        };

        //?????????????????????
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