const Random = artifacts.require("Random");

contract("Random test", async accounts => {


    it("get random", async () => {
        let random = await Random.deployed();
        for (let i = 1; i < 10; i++) {
            let result = await random.getRandom(i);
            console.log(result);
        }

    });


});