// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Store.sol";

contract PreSale is Store {
    // 单地址限购数量
    uint256 private buyLimit = 10;

    uint256 private endTime = 0;

    //地址购买数量记录
    mapping(address => uint256) private addrBuyCount;

    // 设置限购数量
    function setBuyLimit(uint256 limit) public CheckPermit("admin") {
        buyLimit = limit;
    }

    function setEndTime(uint256 time) public CheckPermit("admin") {
        endTime = time;
    }

    // 获取限制数量与已经购买数量、结束时间
    function getInfo()
        public
        view
        returns (
            uint256 limit,
            uint256 count,
            uint256 time
        )
    {
        limit = buyLimit;
        count = addrBuyCount[msg.sender];
        time = endTime;
    }

    function buy(uint256 goodsId, uint256 quantity) public override {
        require(quantity > 0, "Invalid quantity");
        require(block.timestamp <= endTime, "The purchase period has passed");
        require(quantity <= buyLimit - addrBuyCount[msg.sender], "Purchase limit has been exceeded");
        addrBuyCount[msg.sender] += quantity;
        super.buy(goodsId, quantity);
    }
}
