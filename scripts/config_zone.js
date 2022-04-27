const ZoneMine = artifacts.require("ZoneMine");

module.exports = async (callback) => {

    let zoneMine = await ZoneMine.deployed();

    // 添加副本配置
    await zoneMine.addZone({
        "id": 1001,
        "name": "骷髅洞",
        "consumablesAmount": 2,
        "baseExp": 200,
        "level": 0,
        "fragmentWeight": 1,
        "minPower": 0,
        "equipmentNumber": [10028, 10066, 10071, 10076, 10001, 10010, 10019, 10057, 10042, 10047, 10052, 10081, 10086, 10091, 10002, 10011, 10020],
        "probability": [2, 12, 9, 20, 30, 27],
        "quality": [72, 24, 4],
        "profession": [30, 30, 40],
        "dropRateBase": 40000,
        "tokenTotal": web3.utils.toWei("50000", "ether"),
        "tokens": 0,
        "tokenBase": 1,
        "startTime": Math.floor(Date.now() / 1000),
        "endTime": Math.floor(Date.now() / 1000) + 604800
    });

    await zoneMine.addZone({
        "id": 1002,
        "name": "僵尸洞",
        "consumablesAmount": 2,
        "baseExp": 1000,
        "level": 10,
        "fragmentWeight": 5,
        "minPower": 5000,
        "equipmentNumber": [10029, 10067, 10072, 10077, 10003, 10012, 10021, 10058, 10043, 10048, 10053, 10082, 10087, 10092, 10004, 10013, 10022],
        "probability": [2, 12, 9, 20, 30, 27],
        "quality": [72, 24, 4],
        "profession": [30, 30, 40],
        "dropRateBase": 130000,
        "tokenTotal": web3.utils.toWei("100000", "ether"),
        "tokens": 0,
        "tokenBase": 2,
        "startTime": Math.floor(Date.now() / 1000),
        "endTime": Math.floor(Date.now() / 1000) + 604800
    });

    await zoneMine.addZone({
        "id": 1003,
        "name": "蜈蚣洞",
        "consumablesAmount": 3,
        "baseExp": 10000,
        "level": 20,
        "fragmentWeight": 10,
        "minPower": 10000,
        "equipmentNumber": [10030, 10034, 10038, 10068, 10073, 10078, 10005, 10014, 10023, 10059, 10044, 10049, 10054, 10083, 10088, 10093, 10006, 10015, 10024],
        "probability": [2, 12, 9, 20, 30, 27],
        "quality": [72, 24, 4],
        "profession": [30, 40, 30],
        "dropRateBase": 320000,
        "tokenTotal": web3.utils.toWei("150000", "ether"),
        "tokens": 0,
        "tokenBase": 3,
        "startTime": Math.floor(Date.now() / 1000),
        "endTime": Math.floor(Date.now() / 1000) + 604800
    });
}


