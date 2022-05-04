const Totem = artifacts.require("Totem");

module.exports = async (callback) => {
    let totem = await Totem.deployed();
    const accounts = await web3.eth.getAccounts()
    console.log(accounts)
    let balances = await totem.tokensOf(accounts[1], 0, 0);
    console.log(balances)
    callback()
};