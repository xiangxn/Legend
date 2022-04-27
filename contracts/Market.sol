pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./lib/Permission.sol";
import "./Structs.sol";
import "./include/IERC721.sol";
import "./include/IERC20.sol";
import "./include/IERC1155.sol";
import "./include/IERC1155TokenReceiver.sol";
import "./include/IERC721TokenReceiver.sol";
import "./include/IERC1363Receiver.sol";
import "./include/IERC165.sol";
import "./include/IEquipment.sol";
import "./include/IERC20OP.sol";
import "./include/IBonusPool.sol";
import "./include/IReferral.sol";
import "./include/IReferralUpdate.sol";

contract Market is Permission, IERC1155TokenReceiver, IERC721TokenReceiver, IERC1363Receiver, IERC165 {
    enum MarketOperate {
        None,
        //上架
        putOn,
        //购买
        buy
    }
    enum GoodsClass {
        None,
        //装备
        Equipment,
        //碎片
        Fragment,
        //艺术品
        Artwork
    }
    enum GoodsStatus {
        //无意义
        None,
        //正常
        Normal,
        //成交
        Deal,
        //下架
        Close
    }
    struct Goods {
        //商品id
        uint256 id;
        //商品类型(1装备,2碎片,3艺术品)
        uint8 class;
        //商品状态GoodsStatus(1正常,2成交,3下架)
        uint8 status;
        //商品价格(商品总价)
        uint256 price;
        //数量
        uint32 amount;
        //卖家
        address seller;
        //买家
        address buyer;
        //道具id(装备id、碎片id、艺术品id)
        uint256 contentId;
        //支付币种合约地址
        address payContract;
    }
    struct KeyFlag {
        uint256 key;
        bool deleted;
    }
    struct listGoods {
        mapping(uint256 => Goods) data;
        KeyFlag[] keys;
        uint256 size;
    }

    event PutOn(address indexed seller, uint256 goodsId);
    event PullOff(address indexed seller, uint256 goodsId);
    event BuyGoods(address indexed seller, address indexed buyer, uint256 goodsId);

    mapping(address => bool) public supportCoin;

    //商品列表
    listGoods private _listGoods;

    //交易手续费(默认20,即2%,最高1000,即100%)
    uint256 public fee = 20;
    //收费比例(usdt)
    uint256 public chargeRatio = 20;

    function setSupportCoin(address _contract) public CheckPermit("admin") {
        supportCoin[_contract] = true;
    }

    function delSupportCoin(address _contract) public CheckPermit("admin") {
        if (supportCoin[_contract]) {
            delete supportCoin[_contract];
        }
    }

    //设置手续费比例
    function setFee(uint256 _fee) public CheckPermit("admin") {
        require(_fee > 0 && _fee <= 1000, "Invalid fee");
        fee = _fee;
    }

    function setChargeRatio(uint256 rate) public CheckPermit("admin") {
        chargeRatio = rate;
    }

    function insert(Goods memory item) internal returns (bool replaced) {
        uint256 goodsId = _listGoods.data[item.id].id;
        if (goodsId > 0) {
            _listGoods.data[item.id] = item;
            _listGoods.data[item.id].id = goodsId;
            _listGoods.keys[goodsId - 1].key = item.id;
            _listGoods.keys[goodsId - 1].deleted = false;
            return true;
        } else {
            goodsId = _listGoods.keys.length;
            _listGoods.keys.push();
            item.id = goodsId + 1;
            _listGoods.data[item.id] = item;
            _listGoods.keys[goodsId].key = item.id;
            _listGoods.size++;
            return false;
        }
    }

    function remove(uint256 goodsId) internal returns (bool success) {
        uint256 keyIndex = _listGoods.data[goodsId].id;
        if (keyIndex == 0) return false;
        delete _listGoods.data[goodsId];
        _listGoods.keys[keyIndex - 1].deleted = true;
        _listGoods.size--;
        return true;
    }

    function contains(uint256 goodsId) public view returns (bool) {
        uint256 keyIndex = _listGoods.data[goodsId].id;
        return keyIndex > 0 && _listGoods.keys[keyIndex - 1].deleted == false;
    }

    function next(uint256 goodsId) public view returns (uint256) {
        goodsId++;
        while (goodsId < _listGoods.keys.length && _listGoods.keys[goodsId - 1].deleted) goodsId++;
        return goodsId;
    }

    function valid(uint256 goodsId) public view returns (bool) {
        return (goodsId - 1) < _listGoods.keys.length;
    }

    function getGoods(uint256 goodsId) public view returns (Goods memory goods) {
        goods = _listGoods.data[goodsId];
    }

    function searchGoods(
        uint8 class,
        uint256 goodsId,
        uint32 count
    ) public view returns (bool more, Goods[] memory list) {
        list = new Goods[](count);
        uint256 j;
        uint256 i = goodsId;
        if (i == 0) i = next(0);
        Goods storage goods;
        for (; j <= count && valid(i); i = next(i)) {
            goods = _listGoods.data[i];
            if (class == 0 || goods.class == class) {
                if (j < count) {
                    list[j] = goods;
                    j++;
                } else {
                    more = true;
                }
            }
        }
    }

    //上架
    function putOn(
        address from,
        uint256 tokenId,
        Goods memory goods
    ) internal virtual {
        require(tokenId == goods.contentId, "Invalid goods contentId");
        require(goods.price > 0, "Invalid goods price");
        require(goods.amount > 0, "Invalid goods amount");
        require(supportCoin[goods.payContract], "Invalid pay mode");
        goods.seller = from;
        goods.status = uint8(GoodsStatus.Normal);
        insert(goods);
        emit PutOn(from, goods.id);
    }

    //下架
    function pullOff(uint256 goodsId) public virtual {
        Goods storage goods = _listGoods.data[goodsId];
        require(goods.seller == msg.sender, "The goods does not belong to you");
        require(goods.id > 0, "Invalid goodsId");
        require(GoodsStatus(goods.status) == GoodsStatus.Normal, "Invalid goods status");

        GoodsClass gc = GoodsClass(goods.class);
        uint256 tokenId = goods.contentId;
        uint256 value = goods.amount;
        goods.status = uint8(GoodsStatus.Close);
        remove(goodsId);
        if (gc == GoodsClass.Equipment) {
            IERC721(getAddress("Equipment")).safeTransferFrom(address(this), msg.sender, tokenId, "pullOff");
        } else if (gc == GoodsClass.Fragment) {
            IERC1155(getAddress("Fragment")).safeTransferFrom(address(this), msg.sender, tokenId, value, "pullOff");
        } else if (gc == GoodsClass.Artwork) {
            IERC721(getAddress("Artwork")).safeTransferFrom(address(this), msg.sender, tokenId, "pullOff");
        }
        emit PullOff(msg.sender, goodsId);
    }

    //erc20购买
    function buy(uint256 goodsId) public virtual {
        Goods storage goods = _listGoods.data[goodsId];
        // require(goods.id != 0, "Invalid goods id");
        // require(goods.price > 0, "Invalid pay price");
        // require(GoodsStatus(goods.status) == GoodsStatus.Normal, "Invalid goods status");
        //扣款
        bool success = IERC20(goods.payContract).transferFrom(msg.sender, address(this), goods.price);
        if (success == true) {
            _buy(goods.payContract, goodsId, goods.price, msg.sender);
        }
    }

    //购买
    function _buy(
        address payContract,
        uint256 goodsId,
        uint256 value,
        address to
    ) internal virtual {
        Goods storage goods = _listGoods.data[goodsId];
        require(goods.id != 0, "Invalid goods id");
        require(payContract == goods.payContract, "Invalid token");
        require(value == goods.price, "Invalid pay price");
        require(GoodsStatus(goods.status) == GoodsStatus.Normal, "Invalid goods status");

        GoodsClass gc = GoodsClass(goods.class);
        goods.status = uint8(GoodsStatus.Deal);
        goods.buyer = to;

        if (gc == GoodsClass.Equipment) {
            IERC721(getAddress("Equipment")).safeTransferFrom(address(this), to, goods.contentId, "buy");
        } else if (gc == GoodsClass.Fragment) {
            IERC1155(getAddress("Fragment")).safeTransferFrom(address(this), to, goods.contentId, goods.amount, "buy");
        } else if (gc == GoodsClass.Artwork) {
            IERC721(getAddress("Artwork")).safeTransferFrom(address(this), to, goods.contentId, "buy");
        }
        uint256 totalFee = (goods.price * fee) / 1000;
        //游戏收费
        uint256 chargeFee = (totalFee * chargeRatio) / 100;
        //推荐佣金
        uint256 comm;
        if (payContract == getAddress("Token")) {
            //销毁
            IERC20OP(payContract).burn(totalFee);
        } else if (payContract == getAddress("USDT")) {
            address refAddr = getAddress("Referral");
            if (refAddr != address(0)) {
                (address ref, uint256 commission) = IReferral(refAddr).getCommission(to, totalFee);
                comm = commission;
                if (ref != address(0) && commission > 0 && commission < totalFee - chargeFee) {
                    //支付佣金
                    IERC20(payContract).transfer(ref, comm);
                }
            }
            //更新消费总额
            IReferralUpdate(refAddr).updateConsume(msg.sender, goods.price);
            //支付给财务
            IERC20(payContract).transfer(getAddress("Teller"), chargeFee);
            //注入奖池
            address bonus = getAddress("Bonus");
            IERC20(payContract).approve(bonus, totalFee - chargeFee - comm);
            IBonusPool(bonus).injectCapital(totalFee - chargeFee - comm);
        } else {
            //支付给财务
            IERC20(payContract).transfer(getAddress("Teller"), totalFee - comm);
        }
        //支付给卖方
        IERC20(payContract).transfer(goods.seller, goods.price - totalFee);
        emit BuyGoods(goods.seller, goods.buyer, goodsId);
        remove(goodsId);
    }

    //LGC或者支持1363的资产支付
    function onTransferReceived(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        (uint8 op, uint256 goodsId) = abi.decode(data, (uint8, uint256));
        if (MarketOperate.buy == MarketOperate(op)) {
            _buy(msg.sender, goodsId, value, from);
        } else {
            return 0;
        }
        return IERC1363Receiver(this).onTransferReceived.selector;
    }

    //上架装备/艺术品
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override returns (bytes4) {
        if (msg.sender == getAddress("Equipment") || msg.sender == getAddress("Artwork")) {
            (uint8 op, Goods memory goods) = abi.decode(_data, (uint8, Goods));
            if (MarketOperate.putOn == MarketOperate(op)) {
                //上架
                require(GoodsClass(goods.class) == GoodsClass.Equipment || GoodsClass(goods.class) == GoodsClass.Artwork, "Invalid goods class");
                putOn(_from, _tokenId, goods);
            } else {
                return 0;
            }
        }
        return IERC721TokenReceiver(this).onERC721Received.selector;
    }

    //上架碎片
    function onERC1155Received(
        address,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        if (msg.sender == getAddress("Fragment")) {
            (uint8 op, Goods memory goods) = abi.decode(_data, (uint8, Goods));
            if (MarketOperate.putOn == MarketOperate(op)) {
                //上架
                FragmentType ftype = FragmentType(_id >> 248);
                //只能上架奖池碎片与艺术品碎片
                require(ftype == FragmentType.BonusPool || ftype == FragmentType.ArtworkPool, "Invalid fragment id");

                require(_id == goods.contentId, "Invalid goods contentId");
                require(GoodsClass(goods.class) == GoodsClass.Fragment, "Invalid goods class");
                goods.amount = uint32(_value);
                putOn(_from, _id, goods);
            } else {
                return 0;
            }
        }
        return IERC1155TokenReceiver(this).onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return IERC1155TokenReceiver(this).onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1155TokenReceiver).interfaceId || interfaceId == type(IERC721TokenReceiver).interfaceId || interfaceId == type(IERC1363Receiver).interfaceId;
    }
}
