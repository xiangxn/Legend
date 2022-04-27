// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./lib/ERC721.sol";
import "./lib/Permission.sol";
import "./include/IERC721OP.sol";
import "./include/IStoreOP.sol";
import "./lib/Utils.sol";
import "./lib/Uinteger.sol";
import "./include/IRandom.sol";
import "./Structs.sol";
import "./include/IEquipment.sol";
import "./include/IConfig.sol";

/**
装备箱
*/
contract Box is ERC721, Permission, IERC721OP, IStoreOP {
    using Uinteger for uint256;

    string public uriPrefix = "https://source.legendnft.com/box/";
    struct BoxCategory {
        //配置的装备编号列表;第一维为部位对应EquipmentType值,第二维为装备编号
        uint32[][6] equipmentIds;
        /*
        品质概率,可以有1-3个[0普通,1银龙,2金龙],总合100
        如:[50,30,20]、[50,50]、[100]
        */
        uint8[] quality;
        /*
        部位概率
        */
        uint8[] categoryQuality;
        //最小可开装备数量
        uint16 minQuantity;
        //最大可开装备数量
        uint16 maxQuantity;
        //每件装备的锁定token数量
        uint256 tokens;
    }

    struct BoxInfo {
        uint16 classId;
        uint256 blockNumber;
    }

    /**
    @notice 装备掉落事件
    @param user 获得者地址
    @param class 分类(0装备,1碎片)
    @param quality 品质(如果是碎片，则是大类)
    @param number 装备编号(如果是碎片,则是小类)
    @param time 时间
    */
    event Gain(address indexed user, uint256 indexed class, uint256 indexed quality, uint256 number, uint256 time);

    //分类配置: 分类id(classId) => 类型信息
    mapping(uint256 => BoxCategory) public categories;

    //boxId => BoxInfo
    mapping(uint256 => BoxInfo) public boxInfos;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function tokenURI(uint256 boxId) external view override returns (string memory) {
        string memory uri = string(abi.encodePacked(uriPrefix, uint256(boxInfos[boxId].classId).toString(), ".json"));
        return uri;
    }

    function addCategories(uint256 classId, BoxCategory calldata category) external CheckPermit("admin") {
        categories[classId] = category;
    }

    /*
    发行装备箱
    @to 接收人地址
    @quantity 装备箱数量
    @data 装备箱类别(classId)
    */
    function mint(
        address to,
        uint256 quantity,
        bytes calldata data
    ) external override CheckPermit("store") {
        require(data.length == 2, "Invalid data");
        uint16 classId = Utils.toUint16(data, 0);
        require(categories[classId].quality.length > 0, "Invalid data");
        for (uint256 i = 0; i != quantity; i++) {
            uint256 id = (uint256(classId) << 240) | (uint256(uint128(totalSupply + 1)) << 112);
            BoxInfo storage bi = boxInfos[id];
            bi.classId = classId;
            bi.blockNumber = block.number + 1;
            _mint(to, id);
        }
        IRandom(getAddress("Random")).register(block.number + 1);
    }

    function mint(address to, uint256 boxId) external override {}

    /*
    销毁装备箱
    */
    function burn(uint256 boxId) public override {
        address owner = tokenOwners[boxId];
        require(msg.sender == owner || msg.sender == tokenApprovals[boxId] || approvalForAlls[owner][msg.sender], "msg.sender must be owner or approved");
        _burn(boxId);
        delete boxInfos[boxId];
    }

    /*
    开箱
    @boxId 装备箱ID
     */
    function open(uint256 boxId) public {
        BoxInfo memory boxInfo = boxInfos[boxId];
        require(boxInfo.classId != 0, "Invalid boxId");
        burn(boxId);
        BoxCategory storage category = categories[boxInfo.classId];
        uint128 number = uint128((boxId << 16) >> 128);
        bytes32 seed = IRandom(getAddress("Random")).getRandom(boxInfo.blockNumber);
        //随机装备数量
        uint256 quantity;
        if (category.maxQuantity == 1) {
            quantity = 1;
        } else {
            quantity = Utils.randomUint(abi.encodePacked(boxInfo.classId, number, seed), category.minQuantity, category.maxQuantity);
        }
        for (uint256 i = 0; i != quantity; i++) {
            EquipmentAttr memory attr = _calcProperty(seed, category, i, number);
            IEquipment(getAddress("Equipment")).mint(msg.sender, attr);
            emit Gain(msg.sender, 0, attr.quality, attr.number, block.timestamp);
        }
    }

    function open(uint256[] calldata boxIds) public {
        for (uint256 i = 0; i != boxIds.length; i++) {
            open(boxIds[i]);
        }
    }

    function _calcProperty(
        bytes32 seed,
        BoxCategory storage category,
        uint256 index,
        uint128 number
    ) internal view returns (EquipmentAttr memory attr) {
        IConfig config = IConfig(getAddress("Config"));
        //随机品质
        attr.quality = uint8(_randomWeightR(abi.encodePacked(seed, index, number, "quality"), category.quality, 100));
        //随机部位
        uint8 cIndex = uint8(_randomWeight(abi.encodePacked(seed, index, number, "category"), category.categoryQuality, 100));
        //随机装备编号
        uint256 eIndex = Utils.randomUint(abi.encodePacked(seed, index, number, "eIndex"), 0, category.equipmentIds[cIndex].length - 1);
        attr = config.getEquipmentInfo(category.equipmentIds[cIndex][eIndex], attr.quality);
        attr.tokens = category.tokens;
    }

    function _randomWeight(
        bytes memory seed,
        uint8[] memory weights,
        uint8 totalWeight
    ) internal pure returns (uint256) {
        uint256[] memory ws = new uint256[](weights.length);
        for (uint256 i = 0; i != weights.length; i++) {
            ws[i] = weights[i];
        }
        return Utils.randomWeight(seed, ws, totalWeight);
    }
    function _randomWeightR(
        bytes memory seed,
        uint8[] memory weights,
        uint8 totalWeight
    ) internal pure returns (uint256) {
        uint256[] memory ws = new uint256[](weights.length);
        for (uint256 i = 0; i != weights.length; i++) {
            ws[i] = weights[i];
        }
        return Utils.randomWeightR(seed, ws, totalWeight);
    }
}
