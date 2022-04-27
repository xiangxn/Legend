pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./include/IERC20.sol";
import "./include/IRole.sol";
import "./lib/Permission.sol";
import "./Structs.sol";
import "./include/IEquipment.sol";
import "./include/IERC1155OP.sol";
import "./include/IBonusPool.sol";
import "./include/IPeriod.sol";
import "./include/IConfig.sol";
import "./lib/Utils.sol";
import "./lib/Uinteger.sol";
import "./include/IRandom.sol";
import "./include/IERC1155TokenReceiver.sol";
import "./include/IERC1155.sol";

contract ZoneMine is Permission, IERC1155TokenReceiver {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81;

    //副本信息
    struct ZoneInfo {
        //副本id
        uint16 id;
        //副本名
        string name;
        //消耗药品的id
        uint256 consumablesId;
        //每小时消耗药品数量
        uint16 consumablesAmount;
        //每小时经验
        uint32 baseExp;
        //角色进入等级限制
        uint32 level;
        //最小角色战力限制
        uint32 minPower;
        //掉落装备编号
        uint32[] equipmentNumber;
        //部位概率[武器2,头盔12,盔甲9,项链20,戒指30,手镯27],总合100
        uint8[] probability;
        /*
        品质概率,可以有1-3个[0普通,1银龙,2金龙],总合100
        如:[72,24,4]、[72,28]、[100]
        */
        uint8[] quality;
        /*
        职业概率，可以有1-3个[战士,法师,道士],总合100
        如:[50,30,20]、[50,50]、[100]
        */
        uint8[] profession;
        //掉率基数
        uint32 dropRateBase;
        //副本当期产出token总量
        uint256 tokenTotal;
        //副本当期token余量
        uint256 tokens;
        //产出装备锁定token的基础值
        uint256 tokenBase;
        //当期开始时间
        uint64 startTime;
        //当期结束时间
        uint64 endTime;
    }

    //副本产出碎片信息
    struct FragmentOutInfo {
        //碎片权重
        uint8 weight;
        //最大产出碎片数量
        uint32 maxAmount;
        //剩余可产出数量
        uint32 lastCount;
    }

    //角色在副本中的信息
    struct RoleInfo {
        //副本id
        uint16 id;
        //角色id
        uint256 roleId;
        //副本期号
        uint256 zoneNumber;
        //奖池期号
        uint64 bonusPoolNumber;
        //艺术品期号
        uint64 artworkPoolNumber;
        //进入副本时间
        uint64 startTime;
        //角色在副本中的有效结束时间
        uint64 endTime;
        //种子块号
        uint256 blockNumber;
    }
    /**
    @notice 进入副本事件
    @param user 进入地址
    @param roleId 进入角色id
    @param zoneId 副本id
    @param number 副本编号
     */
    event InZone(address indexed user, uint256 indexed roleId, uint256 zoneId, uint256 number);
    /**
    @notice 退出副本事件
    @param user 地址
    @param roleId 角色id
     */
    event StopZone(address indexed user, uint256 indexed roleId);

    /**
    @notice 装备掉落事件
    @param user 获得者地址
    @param class 分类(0装备,1碎片)
    @param quality 品质(如果是碎片，则是大类)
    @param number 装备编号(如果是碎片,则是小类)
    @param time 时间
    */
    event Gain(address indexed user, uint256 indexed class, uint256 indexed quality, uint256 number, uint256 time);

    // zone duration
    uint256 public duration = 7 * 24 * 3600;

    // zone id => zone current number
    mapping(uint256 => uint256) public zoneNumbers;
    // zone id => zone number => zone info
    mapping(uint256 => mapping(uint256 => ZoneInfo)) public zones;
    // zone id=> role count
    mapping(uint256 => uint256) public roleCounts;
    // zone id => role id => RoleInfo
    mapping(uint256 => mapping(uint256 => RoleInfo)) public roles;
    // role id => zone id
    mapping(uint256 => uint256) public roleByZone;
    // zone id => FragmentOutInfo
    mapping(uint256 => FragmentOutInfo) public outputInfos;

    //计奖周期
    uint256 public rewardTime = 3600;

    //临时碎片信息
    FragmentInfo[] availableFragments;

    //副本编号 => 副本配置
    mapping(uint256 => ZoneInfo) private zoneConfigs;

    //设置产出数量
    function setOutputInfo(uint256 zoneId, FragmentOutInfo calldata info) public CheckPermit("admin") {
        outputInfos[zoneId] = info;
        outputInfos[zoneId].lastCount = info.maxAmount;
    }

    function _getRoleContract() internal view returns (IRole) {
        return IRole(getAddress("Role"));
    }

    function setRewardTime(uint256 time) external CheckPermit("admin") {
        require(time > 0);
        rewardTime = time;
    }

    function addZone(ZoneInfo calldata zone) external CheckPermit("admin") {
        zoneConfigs[zone.id] = zone;
        if (zoneNumbers[zone.id] == 0) {
            _newPeriod(zone.id);
        }
    }

    function getZoneInfo(uint256 zoneId) public view returns (ZoneInfo memory) {
        return zones[zoneId][zoneNumbers[zoneId]];
    }

    function getRoleInfo(uint256 roleId) public view returns (RoleInfo memory roleInfo) {
        uint256 zoneId = roleByZone[roleId];
        if (zoneId != 0) {
            roleInfo = roles[zoneId][roleId];
        }
    }

    function getRoleByAddr(address owner) public view returns (RoleInfo memory roleInfo) {
        uint256 roleId = _getRoleContract().getRoleId(owner);
        uint256 zoneId = roleByZone[roleId];
        if (zoneId != 0) {
            roleInfo = roles[zoneId][roleId];
        }
    }

    function _newPeriod(uint256 zoneId) internal {
        uint256 _now = block.timestamp;
        uint256 number = zoneNumbers[zoneId];
        ZoneInfo storage config = zoneConfigs[zoneId];
        ZoneInfo storage info = zones[zoneId][number + 1];
        info.id = config.id;
        info.name = config.name;
        info.consumablesId = config.consumablesId;
        info.consumablesAmount = config.consumablesAmount;
        info.baseExp = config.baseExp;
        info.level = config.level;
        info.minPower = config.minPower;
        info.equipmentNumber = config.equipmentNumber;
        info.startTime = uint64(_now);
        info.endTime = uint64(_now + duration);
        info.probability = config.probability;
        info.quality = config.quality;
        info.profession = config.profession;
        info.dropRateBase = config.dropRateBase;
        info.tokenTotal = config.tokenTotal;
        info.tokens = config.tokenTotal;
        info.tokenBase = config.tokenBase;

        number += 1;
        zoneNumbers[zoneId] = number;
    }

    function staking(
        address _from,
        uint256 zoneId,
        uint256 time
    ) internal {
        require(zoneId == zoneConfigs[zoneId].id, "Invalid zone id");
        uint256 number = zoneNumbers[zoneId];
        require(number > 0, "This zoneId does not exist");
        uint256 _now = block.timestamp;
        uint256 start = zones[zoneId][number].startTime;
        uint256 end = zones[zoneId][number].endTime;
        require(start > 0 && _now >= start, "The zone did not start");
        if (_now >= end) {
            _newPeriod(zoneId);
        }

        IRole roleContract = _getRoleContract();
        //检查条件
        ZoneInfo storage zoneInfo = zones[zoneId][number];
        (CurrentHero memory hero, HeroAttrs memory attrs) = roleContract.getHeroInfo(_from);
        time = time / zoneInfo.consumablesAmount; //计算消耗品可用时间(小时)
        require(time > 0, "Time cannot be 0");
        require(HeroStatus(hero.status) == HeroStatus.None, "No time for heroes");
        require(attrs.power >= zoneInfo.minPower, "Insufficient power");
        require(attrs.level >= zoneInfo.level, "Insufficient level");

        roleContract.inZone(_from, time);

        roleCounts[zoneId] += 1;
        roleByZone[hero.tokenId] = zoneId;

        RoleInfo storage roleInfo = roles[zoneId][hero.tokenId];
        roleInfo.id = uint16(zoneId);
        roleInfo.roleId = hero.tokenId;
        roleInfo.zoneNumber = number;
        roleInfo.bonusPoolNumber = IPeriod(getAddress("Bonus")).number();
        address artwork = getAddress("Artwork");
        if (artwork != address(0)) roleInfo.artworkPoolNumber = IPeriod(getAddress("Artwork")).number();
        roleInfo.startTime = uint64(block.timestamp);
        roleInfo.endTime = uint64(roleInfo.startTime + time * rewardTime);
        roleInfo.blockNumber = block.number + 1;
        emit InZone(_from, hero.tokenId, zoneId, number);
    }

    function _getFragments(RoleInfo storage role) private {
        delete availableFragments;
        IPeriod bonusPool = IPeriod(getAddress("Bonus")); //获取奖池
        IPeriod artworkPool = IPeriod(getAddress("Artwork")); //获取艺术品
        uint256 i;
        if (bonusPool.number() == role.bonusPoolNumber) {
            FragmentInfo[] memory bonusPoolFs = bonusPool.getPeriodFragment(); //获取奖池可产碎片
            for (i = 0; i != bonusPoolFs.length; i++) {
                availableFragments.push(bonusPoolFs[i]);
            }
        }
        if (role.artworkPoolNumber != 0 && artworkPool.number() == role.artworkPoolNumber) {
            FragmentInfo[] memory artworkPoolFs = artworkPool.getPeriodFragment(); //获取艺术品可产碎片(TODO:暂未实现)
            for (i = 0; i != artworkPoolFs.length; i++) {
                availableFragments.push(artworkPoolFs[i]);
            }
        }
    }

    function _updateFragments(FragmentInfo memory fi) internal {
        // fi.lastFragmentCount -= 1;
        if (FragmentType(fi.fType) == FragmentType.BonusPool) {
            IPeriod bonusPool = IPeriod(getAddress("Bonus")); //获取奖池
            bonusPool.updateFragment(fi);
        } else if (FragmentType(fi.fType) == FragmentType.ArtworkPool) {
            IPeriod artworkPool = IPeriod(getAddress("Artwork")); //获取艺术品
            artworkPool.updateFragment(fi);
        }
    }

    function _calcReward(
        ZoneInfo storage zoneInfo,
        RoleInfo storage role,
        HeroAttrs memory roleAttr,
        uint256 roleDuration
    ) internal returns (EquipmentAttr[] memory equipments, FragmentInfo[] memory fragments) {
        if (roleDuration < 1) return (equipments, fragments);
        bytes32 seed = IRandom(getAddress("Random")).getRandom(role.blockNumber);
        equipments = new EquipmentAttr[](roleDuration);
        fragments = new FragmentInfo[](roleDuration);
        _getFragments(role);
        FragmentOutInfo storage foInfo = outputInfos[zoneInfo.id];
        //计算奖励,更新对应的碎片信息
        //循环处理每个小时
        uint256 powerRate = _calcPowerRate(roleAttr.power, zoneInfo.dropRateBase);
        uint256 random;
        uint256 index;
        for (uint256 i = 0; i != roleDuration; i++) {
            random = Utils.randomUint(abi.encodePacked(seed, i, "powerRate"), 1, 100);
            //随机碎片产出
            if (availableFragments.length > 0 && foInfo.lastCount > 0) {
                if (random <= powerRate) {
                    random = Utils.randomUint(abi.encodePacked(seed, i, "fragmentRate"), 1, 100);
                    if (random <= outputInfos[zoneInfo.id].weight) {
                        //产出碎片
                        index = Utils.randomUint(abi.encodePacked(seed, i, "fragment"), 0, availableFragments.length - 1);
                        availableFragments[index].lastFragmentCount -= 1;
                        fragments[i] = availableFragments[index];
                        _updateFragments(fragments[i]);
                        foInfo.lastCount -= 1;
                        continue;
                    }
                }
            }
            if (random <= powerRate) {
                //产出装备
                equipments[i] = _randomEquipment(seed, zoneInfo, i, role.zoneNumber, true);
                //计算token
                equipments[i].tokens = _calcToken(zoneInfo);
                if (zoneInfo.tokens >= equipments[i].tokens) zoneInfo.tokens -= equipments[i].tokens;
            } else {
                //保底装备
                equipments[i] = _randomEquipment(seed, zoneInfo, i, role.zoneNumber, false);
                equipments[i].tokens = _calcToken(zoneInfo);
                if (zoneInfo.tokens >= equipments[i].tokens) zoneInfo.tokens -= equipments[i].tokens;
            }
        }
    }

    function _randomEquipment(
        bytes32 seed,
        ZoneInfo storage category,
        uint256 index,
        uint256 number,
        bool randQuality
    ) internal view returns (EquipmentAttr memory attr) {
        IConfig config = IConfig(getAddress("Config"));
        // //随机职业
        // attr.profession = uint8(_randomWeight(abi.encodePacked(seed, index, number, "profession"), category.profession, 100));
        // //随机部位
        // attr.category = uint8(_randomWeight(abi.encodePacked(seed, index, number, "category"), category.probability, 100));
        //随机品质
        if (randQuality) attr.quality = uint8(_randomWeight(abi.encodePacked(seed, index, number, "quality"), category.quality, 100));

        attr = config.searchEquipment(attr.quality, category.equipmentNumber, abi.encodePacked(seed, index, number, "number"));
        // attr.tokens = 0;
    }

    function _calcPowerRate(uint256 power, uint256 dropRateBase) internal pure returns (uint256 pr) {
        // power/dropRateBase*100
        pr = Uinteger.toUInt(Uinteger.mul(Uinteger.div(Uinteger.fromUInt(power), Uinteger.fromUInt(dropRateBase)), Uinteger.fromUInt(100)));
    }

    function _calcToken(ZoneInfo storage zoneInfo) internal view returns (uint256) {
        uint256 m = zoneInfo.tokens / (10**18);
        uint256 n = zoneInfo.tokenTotal / (10**18);
        int128 bs = Uinteger.div(Uinteger.fromUInt(m), Uinteger.fromUInt(n));
        int128 tmp = Uinteger.add(Uinteger.fromUInt(1), bs);
        tmp = Uinteger.mul(Uinteger.fromUInt(zoneInfo.tokenBase), tmp);
        tmp = Uinteger.mul(Uinteger.mul(tmp, bs), Uinteger.fromUInt(10000));
        return (uint256(Uinteger.toUInt(tmp)) * (10**18)) / 10000;
    }

    function withdraw() external {
        IRole roleContract = _getRoleContract();
        (CurrentHero memory hero, HeroAttrs memory attrs) = roleContract.getHeroInfo(msg.sender);
        require(hero.tokenId != 0, "Role does not exist");

        uint256 zoneId = roleByZone[hero.tokenId];
        require(zoneId != 0, "zoneId does not exist");

        RoleInfo storage roleInfo = roles[zoneId][hero.tokenId];
        ZoneInfo storage zoneInfo = zones[zoneId][roleInfo.zoneNumber];
        uint256 times = hero.time;
        uint256 bonusTimes = times;
        uint256 burnTokens = times * zoneInfo.consumablesAmount;
        uint256 allTokens = burnTokens;
        if (block.timestamp < roleInfo.endTime) {
            bonusTimes = (block.timestamp - roleInfo.startTime) / rewardTime;
            times = bonusTimes + (((block.timestamp - roleInfo.startTime) % rewardTime) > 0 ? 1 : 0);
            burnTokens = times * zoneInfo.consumablesAmount;
        }

        (EquipmentAttr[] memory equipments, FragmentInfo[] memory fragments) = _calcReward(zoneInfo, roleInfo, attrs, bonusTimes);

        delete roles[zoneId][hero.tokenId];
        delete roleByZone[hero.tokenId];
        roleCounts[zoneId] -= 1;

        address fragmentAddr = getAddress("Fragment");
        // 角色经验
        roleContract.stopWorking(msg.sender, uint32(zoneInfo.baseExp * bonusTimes));

        //退还消耗品
        if (allTokens - burnTokens > 0) {
            IERC1155(fragmentAddr).safeTransferFrom(address(this), msg.sender, zoneInfo.consumablesId, allTokens - burnTokens, abi.encodePacked("Return items"));
        }
        //销毁消耗品
        IERC1155OP(fragmentAddr).burn(address(this), zoneInfo.consumablesId, burnTokens);

        // 发放装备
        IEquipment equip = IEquipment(getAddress("Equipment"));
        for (uint256 i = 0; i != equipments.length; i++) {
            if (equipments[i].number != 0) {
                equip.mint(msg.sender, equipments[i]);
                emit Gain(msg.sender, 0, equipments[i].quality, equipments[i].number, block.timestamp);
            }
        }
        // 发放碎片
        for (uint256 i = 0; i != fragments.length; i++) {
            if (fragments[i].number != 0) {
                uint256 fId = (uint256(fragments[i].fType) << 248) | (uint256(fragments[i].id) << 184) | (uint256(fragments[i].number) << 152);
                IERC1155OP(fragmentAddr).mint(msg.sender, fId, 1, fragments[i].tokens);
                emit Gain(msg.sender, 1, fragments[i].fType, fragments[i].id, block.timestamp);
            }
        }

        emit StopZone(msg.sender, hero.tokenId);
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

    function onERC1155Received(
        address,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes4) {
        if (msg.sender == getAddress("Fragment")) {
            Operate op = Operate(uint8(_data[0]));
            uint256 zoneId = Utils.toUint256(_data, 1);
            if (Operate.ZoneMine == op && zoneConfigs[zoneId].consumablesId == _id) {
                //进入副本
                staking(_from, zoneId, _value);
            } else {
                return 0;
            }
        }
        return ERC1155_ACCEPTED;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override returns (bytes4) {
        //暂不支持多道具
        // return ERC1155_BATCH_ACCEPTED;
    }
}
