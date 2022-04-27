pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./Structs.sol";
import "./lib/Permission.sol";
import "./lib/ERC721.sol";
import "./include/IERC20OP.sol";
import "./lib/Uinteger.sol";
import "./include/IConfig.sol";
import "./include/IEquipment.sol";
import "./include/IRandom.sol";
import "./lib/Utils.sol";
import "./include/IFriend.sol";
import "./include/IERC1363Receiver.sol";

contract Equipment is ERC721, Permission, IEquipment, IERC1363Receiver {
    using Uinteger for uint256;

    /***********event ***********/
    event Upgrade(address indexed owner, uint256 equipmentId, uint32 level);

    string public uriPrefix = "https://source.legendnft.com/equipment/";

    // Equipment id => Equipment Attributes
    mapping(uint256 => EquipmentAttr) private equipments;

    /*
        套装属性
        套装id => 套装属性
    */
    mapping(uint256 => SuitAttr) private suits;

    //销毁锁定期
    uint256 public lockDuration = 3600 * 24 * 2;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override {
        require(equipments[tokenId].locked == false, "This equipment is locked");
        require(equipments[tokenId].isEquip == false, "This equipment is already equipped");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        require(equipments[tokenId].locked == false, "This equipment is locked");
        require(equipments[tokenId].isEquip == false, "This equipment is already equipped");
        super.transferFrom(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory uri = string(abi.encodePacked(uriPrefix, uint256(equipments[tokenId].number).toString(), "_", uint256(equipments[tokenId].quality).toString(), ".json"));
        return uri;
    }

    function getEquipment(uint256 tokenId) public view override returns (uint256 id, EquipmentAttr memory attrs) {
        return (tokenId, equipments[tokenId]);
    }

    function mint(address to, EquipmentAttr memory attr) public override CheckPermit2(["zoneMine", "box"]) {
        uint256 eId = (uint256(attr.profession) << 248) | (uint256(attr.category) << 240) | (uint256(attr.quality) << 232) | (uint256(uint64(block.timestamp)) << 64) | uint64(totalSupply + 1);
        _mint(to, eId);
        equipments[eId] = attr;
    }

    function burn(uint256 eId) public {
        require(equipments[eId].locked == false, "This equipment is locked");
        require(equipments[eId].isEquip == false, "This equipment is already equipped");

        address owner = tokenOwners[eId];
        require(msg.sender == owner || msg.sender == tokenApprovals[eId] || approvalForAlls[owner][msg.sender], "msg.sender must be owner or approved");

        uint256 mintTime = uint64(eId >> 64);
        require(mintTime + lockDuration < block.timestamp, "equipment has not unlocked");

        uint256 tokenAmount = equipments[eId].tokens;
        _burn(eId);
        delete equipments[eId];
        if (tokenAmount > 0) IERC20OP(getAddress("Token")).mint(owner, tokenAmount);
    }

    function _equip(
        address operator,
        uint256 eId,
        bool isEquip
    ) internal {
        address owner = tokenOwners[eId];
        require(operator == owner || operator == tokenApprovals[eId] || approvalForAlls[owner][operator], "msg.sender must be owner or approved");
        if (isEquip != equipments[eId].isEquip) equipments[eId].isEquip = isEquip;
    }

    /**
        @notice 修改装备状态
        @param operator 装备的所有者地址
        @param level 角色当前等级
        @param newIds 新装备上角色的装备id组
        @param oldIds 之前装备在角色上的装备id组
        @return power 返回重新装备后的总战力
     */
    function equip(
        address operator,
        uint32 level,
        uint256[] calldata newIds,
        uint256[] calldata oldIds
    ) public override returns (uint32 power) {
        require(msg.sender == getAddress("Role"), "operator must be Role");
        //卸下之前的装备
        for (uint256 i = 0; i != oldIds.length; i++) {
            if (oldIds[i] != 0) {
                _equip(operator, oldIds[i], false);
            }
        }
        // IConfig cfg = IConfig(getAddress("Config"));
        //装备上新的
        for (uint256 i = 0; i != newIds.length; i++) {
            if (newIds[i] != 0) {
                require(equipments[newIds[i]].level <= level, string(abi.encodePacked("Equipment level is too high: ", newIds[i].toString())));
                _equip(operator, newIds[i], true);
                // power += cfg.calcPower(equipments[newIds[i]].level, equipments[newIds[i]].mainAttrs);
                power += equipments[newIds[i]].power;
            }
        }
    }

    /**
        @notice 强化
        @param baseId 被强化的装备id
        @param consumeIds 消耗的装备id组
     */
    function increase(uint256 baseId, uint256[] memory consumeIds) public {
        require(consumeIds.length > 0 && consumeIds.length <= 10, "consumeIds.length must be less than or equal to 10");
        address baseOwner = tokenOwners[baseId];
        require(msg.sender == baseOwner || msg.sender == tokenApprovals[baseId] || approvalForAlls[baseOwner][msg.sender], "msg.sender must be owner or approved");
        for (uint256 i = 0; i < consumeIds.length; i++) {
            uint256 consumeId = consumeIds[i];
            address consumeOwner = tokenOwners[consumeId];
            require(msg.sender == consumeOwner || msg.sender == tokenApprovals[consumeId] || approvalForAlls[consumeOwner][msg.sender], "msg.sender must be owner or approved");

            EquipmentAttr storage base = equipments[baseId];
            EquipmentAttr memory consume = equipments[consumeId];

            if (base.increaseCount >= base.increaseMax) break;
            if (consume.locked || consume.isEquip) continue;

            _burn(consumeId);
            delete equipments[consumeId];

            base.increaseCount += 1;

            // 处理强化后的装备属性与战力
            bytes32 seed = IRandom(getAddress("Random")).getRandom(0);
            IConfig config = IConfig(getAddress("Config"));
            uint32[2] memory interval = config.getIncreaseConfig(base.level, base.quality, Profession(base.profession) == Profession.None);
            uint256 val = Utils.randomUint(abi.encodePacked(seed, block.timestamp, "increase"), interval[0], interval[1]);
            Profession p = Profession(base.profession);
            EquipmentType et = EquipmentType(base.category);
            if (p == Profession.None) {
                //通用
                if (et == EquipmentType.Armor) {
                    //盔甲
                    base.mainAttrs.physicalPower += uint32(val);
                    base.mainAttrs.magicPower = base.mainAttrs.physicalPower;
                    base.mainAttrs.defense += uint32(val);
                    base.mainAttrs.magicDefense = base.mainAttrs.defense;
                } else if (et == EquipmentType.Helmet) {
                    //头盔
                    base.mainAttrs.defense += uint32(val);
                    base.mainAttrs.magicDefense = base.mainAttrs.defense;
                }
            } else {
                if (et == EquipmentType.Arms) {
                    if (p == Profession.Warrior) {
                        base.mainAttrs.attack += uint32(val);
                    } else if (p == Profession.Mage) {
                        base.mainAttrs.magic += uint32(val);
                    } else if (p == Profession.Taoism) {
                        base.mainAttrs.taoism += uint32(val);
                    }
                } else if (et == EquipmentType.Helmet || et == EquipmentType.Bracelet) {
                    base.mainAttrs.defense += uint32(val);
                    base.mainAttrs.magicDefense = base.mainAttrs.defense;
                    if (p == Profession.Warrior) {
                        base.mainAttrs.attack += uint32(val);
                    } else if (p == Profession.Mage) {
                        base.mainAttrs.magic += uint32(val);
                    } else if (p == Profession.Taoism) {
                        base.mainAttrs.taoism += uint32(val);
                    }
                } else if (et == EquipmentType.Armor) {
                    base.mainAttrs.defense += uint32(val);
                    base.mainAttrs.magicDefense = base.mainAttrs.defense;
                    base.mainAttrs.physicalPower += uint32(val);
                    base.mainAttrs.magicPower = base.mainAttrs.physicalPower;
                } else if (et == EquipmentType.Necklace || et == EquipmentType.Ring) {
                    if (p == Profession.Warrior) {
                        base.mainAttrs.attack += uint32(val);
                    } else if (p == Profession.Mage) {
                        base.mainAttrs.magic += uint32(val);
                    } else if (p == Profession.Taoism) {
                        base.mainAttrs.taoism += uint32(val);
                    }
                }
            }
            base.power = config.calcPower(base.level, base.mainAttrs);
            base.tokens += consume.tokens;
        }
    }

    /**
    @notice 赠送
    @param from 发送装备的地址
    @param to 接收装备的地址
    @param ids 要赠送的装备id
    */
    function handsel(
        address from,
        address to,
        uint256[] memory ids
    ) internal {
        bool isFriend = IFriend(getAddress("Friend")).contains(from, to);
        require(true == isFriend, "Can only be given to friends");
        for (uint256 i = 0; i != ids.length; i++) {
            _handsel(from, to, ids[i]);
        }
    }

    function _handsel(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(from != address(0), "from is zero address");
        require(to != address(0), "to is zero address");
        require(equipments[tokenId].locked == false, "This equipment is locked");
        require(equipments[tokenId].isEquip == false, "This equipment is already equipped");
        require(from == tokenOwners[tokenId], "from must be owner");
        if (tokenApprovals[tokenId] != address(0)) {
            delete tokenApprovals[tokenId];
        }
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1363Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onTransferReceived(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        if (msg.sender == getAddress("Token")) {
            (uint256 _op, address to, uint256[] memory ids) = abi.decode(data, (uint256, address, uint256[]));
            Operate op = Operate(uint8(_op));
            if (Operate.Handsel == op) {
                //验证金额
                require(value >= IFriend(getAddress("Friend")).getHandselFee() * ids.length, "Invalid value");
                //赠送
                handsel(from, to, ids);
            } else {
                return 0;
            }
        }
        return IERC1363Receiver(this).onTransferReceived.selector;
    }
}
