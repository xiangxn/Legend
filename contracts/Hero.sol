pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./lib/Permission.sol";
import "./lib/ERC721.sol";
import "./include/IERC20.sol";
import "./lib/Uinteger.sol";
import "./Structs.sol";
import "./include/IConfig.sol";
import "./include/IRole.sol";
import "./include/IEquipment.sol";
import "./include/IERC721.sol";
import "./include/IERC1155TokenReceiver.sol";
import "./lib/Utils.sol";
import "./include/ILockTokens.sol";
import "./include/IERC1363Receiver.sol";
import "./lib/Array.sol";

contract Hero is ERC721, Permission, IRole, IERC1155TokenReceiver, IERC1363Receiver {
    using Uinteger for uint256;

    //经验丹id
    uint256 internal constant fragmentId = (uint256(3) << 248) | (uint256(3) << 184);

    string public uriPrefix = "https://source.legendnft.com/hero/";

    // hero id => Hero Attributes
    mapping(uint256 => HeroAttrs) public heroAttrs;
    // address => heroId,status
    mapping(address => CurrentHero) public currentHeros;

    /***********event ***********/
    event Upgrade(address indexed owner, uint256 heroId, uint32 level);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function getHeroPower(address roleAddr) external view override returns (uint32 power) {
        CurrentHero storage ch = currentHeros[roleAddr];
        if (ch.tokenId != 0) {
            power = heroAttrs[ch.tokenId].power;
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override {
        require(currentHeros[from].tokenId != tokenId, "The role is currently bound");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        require(currentHeros[from].tokenId != tokenId, "The role is currently bound");
        super.transferFrom(from, to, tokenId);
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        string memory uri = string(abi.encodePacked(uriPrefix, _tokenId.toString(), ".json"));
        return uri;
    }

    function getHeroInfo(uint256 id) external view override returns (CurrentHero memory hero, HeroAttrs memory attrs) {
        return (currentHeros[msg.sender], heroAttrs[id]);
    }

    function getHeroInfo(address addr) external view override returns (CurrentHero memory hero, HeroAttrs memory attrs) {
        CurrentHero storage ch = currentHeros[addr];
        return (ch, heroAttrs[ch.tokenId]);
    }

    function getRoleId(address user) public view override returns (uint256 roleId) {
        return currentHeros[user].tokenId;
    }

    function inMine(address user, uint256 time) external override CheckPermit("roleMine") {
        CurrentHero storage ch = currentHeros[user];
        require(ch.tokenId != 0, "This address has no role");
        require(ch.status == 0, "This role cannot be operate");
        ch.status = uint8(HeroStatus.Mine);
        ch.time = uint32(time);
        ch.startTime = uint64(block.timestamp);
    }

    function inZone(address user, uint256 time) external override CheckPermit("zoneMine") {
        CurrentHero storage ch = currentHeros[user];
        require(ch.tokenId != 0, "This address has no role");
        require(ch.status == 0, "This role cannot be operate");
        ch.status = uint8(HeroStatus.Zone);
        ch.time = uint32(time);
        ch.startTime = uint64(block.timestamp);
    }

    function stopWorking(address user, uint32 exp) external override CheckPermit2(["roleMine", "zoneMine"]) {
        CurrentHero storage ch = currentHeros[user];
        require(ch.tokenId != 0, "This address has no role");
        ch.status = uint8(HeroStatus.None);
        ch.startTime = uint64(0);
        HeroAttrs storage ha = heroAttrs[ch.tokenId];
        ha.exp += exp;
    }

    function _create(
        address sender,
        uint256 value,
        bytes calldata _data
    ) internal {
        uint8 gender = uint8(_data[1]);//读取性别
        uint8 profession = Utils.toUint8(_data, 2);//读取职业
        string memory name = string(bytes(_data[3:]));

        require(bytes(name).length > 0, "Hero name cannot be empty");
        CurrentHero storage hero = currentHeros[sender];
        require(hero.tokenId == 0, "Hero already exists at address");

        IConfig cfg = IConfig(getAddress("Config"));
        address payable teller = payable(getAddress("Teller"));
        TokenInfo memory heroFeeInfo = cfg.getTokenInfo(1);
        require(value >= heroFeeInfo.fee, "Fee not enough");

        if (heroFeeInfo.fee > 0) {
            //转给财务
            IERC20 token = IERC20(getAddress("Token"));
            token.transfer(teller, heroFeeInfo.fee);
        }

        hero.tokenId = (uint256(gender) << 248) | (uint256(profession) << 240) | (block.timestamp << 64) | uint64(totalSupply + 1);
        _mint(sender, hero.tokenId);

        LevelInfo memory ma = cfg.getLevelInfo(0);
        HeroAttrs storage heroAttr = heroAttrs[hero.tokenId];
        heroAttr.profession = uint8(Profession(profession));
        heroAttr.gender = uint8(Gender(gender));
        heroAttr.name = name;
        heroAttr.upExp = ma.nextExp;
        heroAttr.level = 0;
    }

    function create(
        string calldata name,
        uint8 gender,
        uint8 profession,
        uint32 tokenType
    ) external payable override {
        require(bytes(name).length > 0, "Hero name cannot be empty");
        CurrentHero storage hero = currentHeros[msg.sender];
        require(hero.tokenId == 0, "Hero already exists at address");

        IConfig cfg = IConfig(getAddress("Config"));
        address payable teller = payable(getAddress("Teller"));
        TokenInfo memory heroFeeInfo = cfg.getTokenInfo(tokenType);
        if (heroFeeInfo.fee > 0) {
            if (tokenType == 0) {
                require(msg.value >= heroFeeInfo.fee, "The payment is too small");
                teller.transfer(msg.value);
            } else {
                IERC20 token = IERC20(getAddress(heroFeeInfo.key));
                token.transferFrom(msg.sender, teller, heroFeeInfo.fee);
            }
        }

        hero.tokenId = (uint256(gender) << 248) | (uint256(profession) << 240) | (block.timestamp << 64) | uint64(totalSupply + 1);
        _mint(msg.sender, hero.tokenId);

        LevelInfo memory ma = cfg.getLevelInfo(0);
        HeroAttrs storage heroAttr = heroAttrs[hero.tokenId];
        heroAttr.profession = uint8(Profession(profession));
        heroAttr.gender = uint8(Gender(gender));
        heroAttr.name = name;
        heroAttr.upExp = ma.nextExp;
        heroAttr.level = 0;
    }

    function _packet(address sender, uint256 heroId) internal {
        delete currentHeros[sender];
        HeroAttrs storage hero = heroAttrs[heroId];
        hero.power = 0;

        IEquipment iEquip = IEquipment(getAddress("Equipment"));
        uint256[] memory newIds = new uint256[](8);
        iEquip.equip(msg.sender, hero.level, newIds, hero.equipmentSlot);

        delete hero.equipmentSlot;
    }

    function packet(uint256 heroId) external override {
        // require(heroId != 0, "Hero id cannot be 0");
        require(msg.sender == ownerOf(heroId), "This hero does not belong to you");
        require(currentHeros[msg.sender].tokenId == heroId, "This hero is not active");
        _packet(msg.sender, heroId);
    }

    function activation(uint256 heroId) external override {
        // require(heroId != 0, "Hero id cannot be 0");
        require(msg.sender == ownerOf(heroId), "This hero does not belong to you");
        CurrentHero storage ch = currentHeros[msg.sender];
        require(ch.tokenId != heroId, "This hero has been activated");
        if (ch.tokenId != 0) {
            _packet(msg.sender, ch.tokenId);
        }
        ch.tokenId = heroId;
    }

    function _upgrade(uint256 heroId) internal {
        HeroAttrs storage heroAttr = heroAttrs[heroId];
        IConfig cfg = IConfig(getAddress("Config"));
        uint32 maxLevel = cfg.maxLevel();
        while (heroAttr.exp >= heroAttr.upExp && heroAttr.level < maxLevel) {
            LevelInfo memory levelInfo = cfg.getLevelInfo(heroAttr.level + 1);
            heroAttr.level += 1;
            heroAttr.upExp = levelInfo.nextExp;
            heroAttr.exp -= levelInfo.exp;
            emit Upgrade(msg.sender, heroId, heroAttr.level);
        }
    }

    function upgrade(uint256 heroId) external override {
        require(msg.sender == ownerOf(heroId), "This hero does not belong to you");
        require(currentHeros[msg.sender].tokenId == heroId, "This hero is not active");
        _upgrade(heroId);
    }

    function burn(uint256 heroId) external override {
        address owner = tokenOwners[heroId];
        require(msg.sender == owner || msg.sender == tokenApprovals[heroId] || approvalForAlls[owner][msg.sender], "msg.sender must be owner or approved");
        require(currentHeros[owner].tokenId != heroId, "The role is currently bound");
        _burn(heroId);
        delete heroAttrs[heroId];
    }

    function equip(uint256 heroId, uint256[] calldata newIds) external override {
        address owner = tokenOwners[heroId];
        require(msg.sender == owner || msg.sender == tokenApprovals[heroId] || approvalForAlls[owner][msg.sender], "msg.sender must be owner or approved");
        require(currentHeros[owner].tokenId == heroId, "The role is currently bound");
        //装备id重复检查
        require(Array.checkRepeat(newIds, true) == false, "Invalid newIds");
        
        //检查装备属性
        address _equip = getAddress("Equipment");
        IEquipment iEquip = IEquipment(_equip);
        HeroAttrs storage heroAttr = heroAttrs[heroId];

        //[头盔，项链，盔甲，武器,手镯L,手镯R,戒指L，戒指R]
        for(uint256 i = 0; i != newIds.length; i++){
            if(newIds[i] != 0){
                (uint256 id, EquipmentAttr memory attrs)=iEquip.getEquipment(newIds[i]);
                require(attrs.profession == 0 || attrs.profession == heroAttr.profession, "Invalid equipment profession");
                EquipmentType et;
                if(i == 0){
                    et = EquipmentType.Helmet;
                }else if(i == 1){
                    et = EquipmentType.Necklace;
                }else if(i == 2){
                    et = EquipmentType.Armor;
                }else if(i == 3){
                    et = EquipmentType.Arms;
                }else if(i == 4 || i == 5){
                    et = EquipmentType.Bracelet;
                }else if(i == 6 || i == 7){
                    et = EquipmentType.Ring;
                }
                require(et == EquipmentType(attrs.category), string(abi.encodePacked("Invalid equipment category: ", id.toString())));
            }
        }
        
        heroAttr.power = iEquip.equip(msg.sender, heroAttr.level, newIds, heroAttr.equipmentSlot);
        if (heroAttr.power > 0) {
            heroAttr.equipmentSlot = newIds;
        } else {
            delete heroAttr.equipmentSlot;
        }
    }

    function expMedicine(
        uint256 heroId,
        uint256 amount,
        address fragment
    ) internal {
        if (heroId != 0) {
            uint256 perExp = ILockTokens(fragment).lockTokens(fragmentId); //这里tokens数据中存的是每个药的经验值
            HeroAttrs storage heroAttr = heroAttrs[heroId];
            heroAttr.exp += uint32(amount * perExp);
            _upgrade(heroId);
        }
    }

    function onTransferReceived(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        if(msg.sender == getAddress("Token")){
            Operate op = Operate(uint8(data[0]));
            if (Operate.CreateHero == op) {
                //创建角色
                _create(from, value, data);
            } else {
                return 0;
            }
        }
        return IERC1363Receiver(this).onTransferReceived.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes4) {
        if (msg.sender == getAddress("Fragment")) {
            Operate op = Operate(uint8(_data[0]));
            uint256 heroId = Utils.toUint256(_data, 1);
            if (Operate.ExpMedicine == op && fragmentId == _id) {
                //使用经验丹
                expMedicine(heroId, _value, msg.sender);
            } else {
                return 0;
            }
        }
        return IERC1155TokenReceiver(this).onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override returns (bytes4) {}

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1363Receiver).interfaceId || interfaceId == type(IERC1155TokenReceiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
