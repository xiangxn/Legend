pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./lib/Permission.sol";
import "./include/IReferral.sol";
import "./include/IReferralUpdate.sol";
import "./include/IStoreOP.sol";
import "./include/IRole.sol";
import "./Structs.sol";

contract Referral is Permission, IReferral, IReferralUpdate {
    //被邀请人奖励条件
    enum RewardConditions {
        //角色等级
        Level,
        //消费金额
        Amount,
        //角色等级+消费金额
        LevelAmount
    }

    //邀请人奖励配置
    struct RefConfig {
        uint32 id;
        // 推广大师等级
        uint32 level;
        //提成比例 1000表示100%,1表示0.1%
        uint16 ratio;
        //奖励的箱子type
        uint16 boxType;
        //奖励的箱子数量
        uint32 boxAmount;
        //有效消费额(条件,目前只用于增加有效引荐人)
        uint256 validAmount;
        //有效地址数(条件)
        uint32 validUserCount;
    }

    //被邀请人奖励配置
    struct RefUserConfig {
        uint32 id;
        //奖励条件(类型)
        uint8 condition;
        //消费金额
        uint256 consumeAmount;
        //角色等级
        uint32 level;
        //奖励的箱子type
        uint16 boxType;
        //奖励的箱子数量
        uint32 boxAmount;
    }

    //邀请人
    struct RefParent {
        //邀请人地址
        address user;
        //邀请人当前等级
        uint32 level;
        //已经引荐的地址数量
        uint32 count;
        //有效地址数
        uint32 validCount;
        //已经分得的总usdt
        uint256 amount;
        //已经领取等级奖励
        uint32[] withdraw;
    }

    //被邀请人
    struct RefUser {
        //邀请人地址
        address parent;
        //邀请码(邀请人的)
        uint256 parentCode;
        //是否已经为有效
        bool isValid;
        //被邀请人的角色等级(直接使用Hero数据)
        // uint32 roleLevel;
        //记录消费金额
        uint256 consumeAmount;
        //已经领取等级奖励
        uint32[] withdraw;
    }

    //邀请码 => 关联地址
    mapping(uint256 => address) public refCode;
    //邀请人=>邀请人数据
    mapping(address => RefParent) internal refParent;
    //被邀请人数据(被邀请人地址=>被邀请人数据)
    mapping(address => RefUser) internal refUser;
    //邀请人奖励等级配置 推广大师等级=>配置
    mapping(uint256 => RefConfig) public refConfig;
    //邀请人奖励等级配置数量
    uint256 public refConfigCount;
    //被邀请人奖励配置 配置编号=>配置
    mapping(uint256 => RefUserConfig) public refUserConfig;
    //被邀请人奖励配置
    uint256 public refUserConfigCount;
    //推荐有效角色等级
    uint256 public validLevel = 5;
    //推荐有效消费金额
    uint256 public validAmount = 0;

    function getReferral(address addr) public view returns (RefParent memory ref) {
        ref = refParent[addr];
    }

    function getUser(address addr) public view returns (RefUser memory user) {
        user = refUser[addr];
    }

    //获取所有邀请人奖励配置
    function getAllRefConfig() public view returns (RefConfig[] memory) {
        RefConfig[] memory configs = new RefConfig[](refConfigCount);
        for (uint256 id = 1; id <= refConfigCount; id++) {
            configs[id - 1] = refConfig[id];
        }
        return configs;
    }

    //获取所有被邀请人奖励配置
    function getAllRefUserConfig() public view returns (RefUserConfig[] memory) {
        RefUserConfig[] memory configs = new RefUserConfig[](refUserConfigCount);
        for (uint256 id = 1; id <= refUserConfigCount; id++) {
            configs[id - 1] = refUserConfig[id];
        }
        return configs;
    }

    //设置初始有效条件
    function setValid(uint256 level, uint256 amount) public CheckPermit("admin") {
        validLevel = level;
        validAmount = amount;
    }

    //设置邀请人奖励配置
    function setRefConfig(RefConfig calldata config) public CheckPermit("admin") {
        require(config.level > 0, "Invalid level");
        if (refConfig[config.id].id == 0) {
            refConfigCount += 1;
            refConfig[refConfigCount] = config;
            refConfig[refConfigCount].id = uint32(refConfigCount);
        } else {
            refConfig[config.id] = config;
        }
    }

    //设置被邀请人奖励配置
    function setRefUserConfig(RefUserConfig calldata config) public CheckPermit("admin") {
        if (refUserConfig[config.id].id == 0) {
            refUserConfigCount += 1;
            refUserConfig[refUserConfigCount] = config;
            refUserConfig[refUserConfigCount].id = uint32(refUserConfigCount);
        } else {
            refUserConfig[config.id] = config;
        }
    }

    function getCommission(address user, uint256 total) public view override returns (address to, uint256 amount) {
        to = refUser[user].parent;
        RefConfig memory rc = _getRefConfig(user);
        amount = (total * rc.ratio) / 1000;
    }

    //根据被邀请人获取邀请人的等级配置数据
    function _getRefConfig(address user) internal view returns (RefConfig memory rc) {
        uint32 level = refParent[refUser[user].parent].level;
        for (uint256 i = 1; i < refConfigCount; i++) {
            if (level == refConfig[i].level) {
                rc = refConfig[i];
                break;
            }
        }
    }

    //创建推荐码关联
    function create(uint256 _code) public {
        require(_code >= 0, "Invalid code");
        uint256 code;
        if (_code == 0) {
            code = uint32(bytes4(bytes20(msg.sender)));
        }
        if (refCode[code] == address(0)) {
            refCode[code] = msg.sender;
        }
        RefParent storage ref = refParent[msg.sender];
        ref.user = msg.sender;
    }

    //绑定引荐人
    function bind(uint256 code) public {
        address addr = refCode[code];
        require(addr != address(0) && addr != msg.sender, "Invalid code");
        RefUser storage user = refUser[msg.sender];
        user.parent = addr;
        user.parentCode = code;

        RefParent storage parent = refParent[addr];
        parent.count += 1;
    }

    //更新消费(只限限商店权限)
    function updateConsume(address userAddr, uint256 amount) public override CheckPermit("store") {
        RefUser storage user = refUser[userAddr];
        //更新消费额
        user.consumeAmount += amount;

        RefParent storage parent = refParent[user.parent];
        //更新有效引荐
        if (user.isValid == false) {
            bool isValid;
            if (validLevel > 0) {
                IRole role = IRole(getAddress("Role"));
                (, HeroAttrs memory attrs) = role.getHeroInfo(userAddr);
                if (attrs.level >= validLevel) isValid = true;
            } else if (validAmount > 0) {
                if (user.consumeAmount > validAmount) isValid = true;
            }
            if (isValid) {
                parent.validCount += 1;
                user.isValid = true;
            }
        }
        //检查并更新推荐等级
        uint32 level;
        for (uint256 i = 1; i <= refConfigCount; i++) {
            if (parent.validCount >= refConfig[i].validUserCount) {
                level = refConfig[i].level;
            }
        }
        parent.level = level;
        //记录商店消费分成
        (, uint256 comm) = getCommission(userAddr, amount);
        parent.amount += comm;
    }

    function checkDraw(uint256 configId, uint32[] memory withdraw) internal pure returns (bool already) {
        for (uint256 i = 0; i < withdraw.length; i++) {
            if (configId == withdraw[i]) {
                already = true;
                break;
            }
        }
    }

    //引荐人领取奖励箱子
    function refClaim(uint256 rewardId) public {
        RefParent storage parent = refParent[msg.sender];
        require(checkDraw(rewardId, parent.withdraw) == false, "already draw");

        RefConfig storage config = refConfig[rewardId];
        require(parent.level >= config.level, "Unable to claim if the level is not reached");
        parent.withdraw.push(uint32(rewardId));

        //发放箱子
        bytes memory data = new bytes(2);
        data[0] = bytes2(config.boxType)[0];
        data[1] = bytes2(config.boxType)[1];
        IStoreOP(getAddress("Box")).mint(msg.sender, config.boxAmount, data);
    }

    //被邀请人领取奖励
    function userClaim(uint256 configId) public {
        RefUser storage user = refUser[msg.sender];
        require(checkDraw(configId, user.withdraw) == false, "already draw");
        require(user.parentCode != 0, "No inviter is bound");

        RefUserConfig storage config = refUserConfig[configId];
        RewardConditions rc = RewardConditions(config.condition);
        IRole role = IRole(getAddress("Role"));
        (, HeroAttrs memory attrs) = role.getHeroInfo(msg.sender);
        if (rc == RewardConditions.Level) {
            require(attrs.level >= config.level, "Unable to claim if the level is not reached");
        } else if (rc == RewardConditions.Amount) {
            require(user.consumeAmount >= config.consumeAmount, "Unable to claim if the consume amount is not reached");
        } else if (rc == RewardConditions.LevelAmount) {
            require(attrs.level >= config.level, "Unable to claim if the level is not reached");
            require(user.consumeAmount >= config.consumeAmount, "Unable to claim if the consume amount is not reached");
        } else {
            return;
        }
        user.withdraw.push(uint32(configId));

        //发放箱子
        bytes memory data = new bytes(2);
        data[0] = bytes2(config.boxType)[0];
        data[1] = bytes2(config.boxType)[1];
        IStoreOP(getAddress("Box")).mint(msg.sender, config.boxAmount, data);
    }
}
