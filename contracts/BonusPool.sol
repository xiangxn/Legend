pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./lib/Permission.sol";
import "./include/IERC20.sol";
import "./include/IERC20OP.sol";
import "./include/ITotem.sol";
import "./include/IERC721.sol";
import "./include/IBonusPool.sol";
import "./include/ILockTokens.sol";
import "./include/IPeriod.sol";
import "./Structs.sol";
import "./include/IERC1155OP.sol";
import "./include/IERC1155TokenReceiver.sol";
import "./include/IERC721TokenReceiver.sol";

contract BonusPool is Permission, IBonusPool, IPeriod, IERC1155TokenReceiver, IERC721TokenReceiver {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 private constant ERC721_RECEIVER_RETURN = 0x150b7a02;
    // 奖金滚存
    uint256 public override total;
    // 当前期未领取奖金
    uint256 public override current;
    // 当前期号
    uint32 public override number = 1;
    // 返奖比例
    uint32 public override rebateRatio = 20;
    // 返奖周期
    uint32 public override bonusDuration = 7 * 24 * 3600;
    // 每碎片Token数量(不包含精度信息，计算时必须带入精度)
    uint256 public override perFragmentToken = 50;
    // 返奖期列表
    mapping(uint256 => Period) private periods;

    struct Period {
        //开始时间
        uint64 startTime;
        //结束时间
        uint64 endTime;
        //奖项信息
        AwardsInfo[] awardsInfos;
    }

    struct AwardsInfo {
        //奖项类型:1 一等奖, 2 二等奖, 3 三等奖
        uint8 types;
        //奖项的个数
        uint32 count;
        //已经兑换个数
        uint32 redeemedCount;
        //奖项的总碎片数
        uint32 fragmentCount;
        //剩余的碎片数
        uint32 lastFragmentCount;
        //奖项占比
        uint8 ratio;
        //每个奖项的奖金
        uint256 bonus;
    }
    AwardsInfo[] public awardsInfos;

    function setParams(
        uint256 rate,
        uint256 duartion,
        uint256 perToken
    ) public CheckPermit("admin") {
        rebateRatio = uint32(rate);
        bonusDuration = uint32(duartion);
        perFragmentToken = perToken;
    }

    function getInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint32,
            uint32,
            uint32,
            uint256,
            Period memory
        )
    {
        return (total, current, number, rebateRatio, bonusDuration, perFragmentToken, periods[number]);
    }

    function getPeriod(uint256 _number) public view returns (Period memory period) {
        period = periods[_number];
    }

    function addAwards(uint256 index, AwardsInfo calldata awardsInfo) external CheckPermit("admin") {
        require(index >= 0, "Invalid index");
        uint8 ratio;
        for (uint256 i = 0; i != awardsInfos.length; i++) {
            ratio += awardsInfos[i].ratio;
        }
        require(awardsInfo.ratio <= 100 - ratio, "Invalid ratio");
        if (index < awardsInfos.length) {
            awardsInfos[index] = awardsInfo;
        } else {
            awardsInfos.push(awardsInfo);
        }
    }

    function getPeriodFragment() public view override returns (FragmentInfo[] memory fragmentInfos) {
        Period storage period = periods[number];
        uint256 length;
        for (uint256 i = 0; i != period.awardsInfos.length; i++) {
            if (period.awardsInfos[i].lastFragmentCount >= 1) length += 1;
        }
        if (length > 0) {
            fragmentInfos = new FragmentInfo[](length);
            uint256 j = 0;
            for (uint256 i = 0; i != period.awardsInfos.length; i++) {
                if (period.awardsInfos[i].lastFragmentCount >= 1) {
                    fragmentInfos[j] = FragmentInfo(uint8(FragmentType.BonusPool), uint64(period.awardsInfos[i].types), number, period.awardsInfos[i].lastFragmentCount, perFragmentToken);
                    j++;
                }
            }
        }
    }

    function updateFragment(FragmentInfo calldata fi) external override CheckPermit("zoneMine") {
        Period storage period = periods[fi.number];
        for (uint256 i = 0; i != period.awardsInfos.length; i++) {
            if (period.awardsInfos[i].types == uint8(fi.id)) {
                period.awardsInfos[i].lastFragmentCount = fi.lastFragmentCount;
                break;
            }
        }
    }

    function _getTokenContract() internal view returns (IERC20) {
        return IERC20(getAddress("USDT"));
    }

    function injectCapital(uint256 value) external override {
        if (msg.sender != getAddress("Store") && msg.sender != getAddress("PreSale")) {
            IERC20 token = _getTokenContract();
            bool success = token.transferFrom(msg.sender, address(this), value);
            require(success, "Payment failed");
        }
        total += value;
    }

    function open() external CheckPermit("admin") {
        uint256 award;
        uint256 start = block.timestamp;
        require(start >= periods[number].endTime, "start must be greater than or equal to endTime");
        if (current > 0) total += current;
        uint256 end = start + bonusDuration;
        number += 1;
        if (award > 0) {
            current = award;
            total = 0;
        } else {
            current = (total * uint256(rebateRatio)) / 100;
            total -= current;
        }

        Period storage period = periods[number];
        period.startTime = uint64(start);
        period.endTime = uint64(end);
        for (uint256 i = 0; i != awardsInfos.length; i++) {
            AwardsInfo memory ai = awardsInfos[i];
            ai.bonus = (current * ai.ratio) / 100 / ai.count;
            period.awardsInfos.push(ai);
        }
    }

    function _getAwardsInfo(uint256 tokenId) internal view returns (AwardsInfo memory ai) {
        Period storage period = periods[number];
        uint8 types = uint8((tokenId << 8) >> 192);
        for (uint256 i = 0; i != period.awardsInfos.length; i++) {
            if (period.awardsInfos[i].types == types) {
                ai = period.awardsInfos[i];
                break;
            }
        }
    }

    function redeemTotem(
        address totem,
        address from,
        uint256 tokenId
    ) internal {
        uint8 fType = uint8(tokenId >> 248);
        uint32 num = uint32((tokenId << 72) >> 224);
        require(fType == 1, "Invalid tokenId");
        require(num == number, "Invalid tokenId");
        Period storage period = periods[number];
        uint256 _now = block.timestamp;
        require(_now >= period.startTime && _now < period.endTime, "Can't redeem anymore");

        //销毁图腾
        ITotem iTotem = ITotem(totem);
        iTotem.burn(tokenId);
        //更新领取信息
        AwardsInfo memory ai = _getAwardsInfo(tokenId);
        current -= ai.bonus;
        for (uint256 i = 0; i != period.awardsInfos.length; i++) {
            if (period.awardsInfos[i].types == ai.types) {
                period.awardsInfos[i].redeemedCount += 1;
                break;
            }
        }
        //发放奖金
        IERC20 token = _getTokenContract();
        token.transfer(from, ai.bonus);
    }

    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external override returns (bytes4) {
        if (msg.sender == getAddress("Totem")) {
            Operate op = Operate(uint8(_data[0]));
            if (Operate.Redeem == op) {
                redeemTotem(msg.sender, _from, _tokenId);
            } else if (Operate.Burn == op) {
                burnTotem(msg.sender, _from, _tokenId);
            } else {
                return 0;
            }
        }
        return ERC721_RECEIVER_RETURN;
    }

    function burnTotem(
        address totem,
        address from,
        uint256 tokenId
    ) internal {
        uint8 fType = uint8(tokenId >> 248);
        uint32 num = uint32((tokenId << 72) >> 224);
        require(fType == 1, "Invalid tokenId");
        require(num != number, "Unexpired totem cannot be burn");
        uint256 tokens = ILockTokens(totem).lockTokens(tokenId);
        ITotem(totem).burn(tokenId);
        IERC20OP(getAddress("Token")).mint(from, tokens);
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
            if (Operate.Composite == op) {
                composite(_from, _id, _value);
            } else if (Operate.Burn == op) {
                burnFragment(_from, _id, _value);
            } else {
                return 0;
            }
        }
        return ERC1155_ACCEPTED;
    }

    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override returns (bytes4) {
        if (msg.sender == getAddress("Fragment")) {
            Operate op = Operate(uint8(_data[0]));
            if (Operate.Composite == op) {
                for (uint256 i = 0; i != _ids.length; i++) {
                    composite(_from, _ids[i], _values[i]);
                }
            } else if (Operate.Burn == op) {
                for (uint256 i = 0; i != _ids.length; i++) {
                    burnFragment(_from, _ids[i], _values[i]);
                }
            } else {
                return 0;
            }
        }
        return ERC1155_BATCH_ACCEPTED;
    }

    function burnFragment(
        address from,
        uint256 tokenId,
        uint256 value
    ) internal {
        uint8 fType = uint8(tokenId >> 248);
        uint32 num = uint32((tokenId << 72) >> 224);
        require(fType == 1, "Invalid tokenId");
        require(num != number, "Not expired, cannot be burn");
        IERC1155OP(getAddress("Fragment")).burn(address(this), tokenId, value);
        address lgc = getAddress("Token");
        uint256 val = perFragmentToken * (10**IERC20(lgc).decimals()) * value;
        IERC20OP(lgc).mint(from, val);
    }

    function composite(
        address from,
        uint256 tokenId,
        uint256 _value
    ) internal {
        uint8 fType = uint8(tokenId >> 248);
        require(fType == 1, "Invalid tokenId");
        AwardsInfo memory ai = _getAwardsInfo(tokenId);
        require(ai.count - ai.redeemedCount > 0, "There is nothing to composite");
        address fragment = getAddress("Fragment");
        //碎片数量
        uint256 value = ai.fragmentCount / ai.count;
        require(value == _value, "Invalid value");
        ai.redeemedCount += 1;
        //销毁碎片
        IERC1155OP(fragment).burn(address(this), tokenId, value);
        //发放图腾
        address lgc = getAddress("Token");
        uint256 totalValue = perFragmentToken * (10**IERC20(lgc).decimals()) * value;
        ITotem(getAddress("Totem")).mint(from, tokenId, totalValue);
    }
}
