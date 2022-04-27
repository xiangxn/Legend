const Hero = artifacts.require("Hero");

contract("Hero test", async accounts => {
    let heroInfo;
    let curAcc = accounts[6];

    it("create hero", async () => {
        let instance = await Hero.deployed();
        let result = await instance.create("英雄", 1, 1, 0, { "from": curAcc, "value": "1000000000000000000" });
        console.log("txHash: ", result.tx);
        heroInfo = await instance.getHeroInfo(curAcc);
        console.log("heroId: ", heroInfo.heroId.toString());
    });

    it("packet hero", async () => {
        let instance = await Hero.deployed();
        let result = await instance.packet(heroInfo.heroId, { "from": curAcc });
        console.log("txHash: ", result.tx);
        //currentHeros
        let hId = await instance.currentHeros(curAcc);
        assert.equal(hId.valueOf(), 0);
    });

    it("transfer hero", async () => {
        let instance = await Hero.deployed();
        let result = await instance.approve(instance.address, heroInfo.heroId, { "from": curAcc });
        console.log("txHash: ", result.tx);
        await instance.transferFrom(curAcc, accounts[7], heroInfo.heroId, { "from": curAcc });
    });

    it("activation hero", async () => {
        let instance = await Hero.deployed();
        let result = await instance.activation(heroInfo.heroId, { "from": accounts[7] });
        console.log("txHash: ", result.tx);
        let hId = await instance.currentHeros(accounts[7]);
        assert.equal(hId.toString(), heroInfo.heroId.toString());
        let hero = await instance.getHeroInfo(accounts[7]);
        console.log("hero: ", hero);
    });
});