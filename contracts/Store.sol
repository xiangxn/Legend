// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./lib/Permission.sol";
import "./include/IERC20.sol";
import "./include/IERC20OP.sol";
import "./include/IBonusPool.sol";
import "./include/IStoreOP.sol";
import "./include/IERC1363Receiver.sol";
import "./include/IERC165.sol";
import "./lib/Utils.sol";
import "./include/IReferral.sol";
import "./include/IReferralUpdate.sol";

contract Store is Permission, IERC1363Receiver, IERC165 {
    struct GoodsInfo {
        //结算货币
        address settlementCurrency;
        //商品合约地址
        address contractAddress;
        //上架数量
        uint32 quantityCount;
        //已售出数量
        uint32 quantitySold;
        //单价
        uint256 unitPrice;
        //逻辑数据
        bytes data;
    }

    // 商品id => 商品信息
    mapping(uint256 => GoodsInfo) public goods;

    //收费比例
    uint256 public chargeRatio = 20;

    function setChargeRatio(uint256 rate) public CheckPermit("admin") {
        chargeRatio = rate;
    }

    function addGoods(GoodsInfo calldata goodsInfo, uint256 goodsId) external CheckPermit("admin") {
        require(goodsId > 0, "Invalid goodsId");
        goods[goodsId] = goodsInfo;
    }

    function delGoods(uint256 goodsId) external CheckPermit("admin") {
        require(goodsId > 0, "Invalid goodsId");
        delete goods[goodsId];
    }

    function buy(uint256 goodsId, uint256 quantity) public virtual {
        require(quantity <= goods[goodsId].quantityCount - goods[goodsId].quantitySold, "Invalid quantity");
        address tokenAddress = goods[goodsId].settlementCurrency;
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = goods[goodsId].unitPrice * quantity;
        bool success;
        if (tokenAddress == getAddress("Token")) {
            success = token.transferFrom(msg.sender, address(this), amount);
            if (success) {
                //销毁
                IERC20OP(tokenAddress).burn(amount);
                //发放商品
                IStoreOP(goods[goodsId].contractAddress).mint(msg.sender, quantity, goods[goodsId].data);
                goods[goodsId].quantitySold += uint32(quantity);
            }
        } else {
            address bonus = getAddress("Bonus");
            //推荐佣金
            uint256 comm;
            //收取运维费用
            uint256 fee = (amount * chargeRatio) / 100;
            success = token.transferFrom(msg.sender, getAddress("Teller"), fee);
            if (success) {
                //推荐分佣
                address refAddr = getAddress("Referral");
                if (refAddr != address(0)) {
                    (address ref, uint256 commission) = IReferral(refAddr).getCommission(msg.sender, amount);
                    if (ref != address(0) && commission > 0 && commission < amount - fee) {
                        comm = commission;
                        //支付佣金
                        success = token.transferFrom(msg.sender, ref, commission);
                    }
                }
                if (success) {
                    //转入奖池
                    success = token.transferFrom(msg.sender, bonus, amount - fee - comm);
                    if (success) {
                        //更新消费总额
                        IReferralUpdate(refAddr).updateConsume(msg.sender, amount);
                        //注入奖池
                        IBonusPool(bonus).injectCapital(amount - fee - comm);
                        //发放商品
                        IStoreOP(goods[goodsId].contractAddress).mint(msg.sender, quantity, goods[goodsId].data);
                        goods[goodsId].quantitySold += uint32(quantity);
                    }
                }
            }
        }
    }

    function _buy(
        address sender,
        uint256 value,
        address tokenAddr,
        bytes calldata data
    ) internal virtual {
        uint256 goodsId = Utils.toUint256(data, 1);
        uint256 quantity = Utils.toUint256(data, 33);
        require(quantity <= goods[goodsId].quantityCount - goods[goodsId].quantitySold, "Invalid quantity");
        require(tokenAddr == goods[goodsId].settlementCurrency, "Invalid token for goods");

        uint256 amount = goods[goodsId].unitPrice * quantity;
        require(value >= amount, "Insufficient amount token");

        //销毁
        IERC20OP(tokenAddr).burn(amount);
        //发放商品
        IStoreOP(goods[goodsId].contractAddress).mint(sender, quantity, goods[goodsId].data);
        goods[goodsId].quantitySold += uint32(quantity);
    }

    function onTransferReceived(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        if (msg.sender == getAddress("Token")) {
            Operate op = Operate(uint8(data[0]));
            if (Operate.BuyProps == op) {
                //买道具
                _buy(from, value, msg.sender, data);
            } else {
                return 0;
            }
        }
        return IERC1363Receiver(this).onTransferReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1363Receiver).interfaceId;
    }
}
