pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./include/IERC20.sol";
import "./include/IRole.sol";
import "./lib/MultiStakeBase.sol";
import "./include/IERC1155TokenReceiver.sol";
import "./include/IERC1155OP.sol";
import "./include/IERC1155.sol";

contract RoleMine is MultiStakeBase, IERC1155TokenReceiver {
    //鹤嘴锄id
    uint256 internal constant fragmentId = (uint256(3) << 248) | (uint256(1) << 184);

    uint256 public roleCount;

    //角色所属地址=>池地址
    mapping(address => address) public roleInfo;

    event InMine(address indexed user, uint256 indexed roleId);
    event StopMine(address indexed user, uint256 indexed roleId, uint256 power, uint256 reward);

    function _getRoleContract() internal view returns (IRole) {
        return IRole(getAddress("Role"));
    }

    function staking(
        address _from,
        address poolAddr,
        uint256 time
    ) internal {
        if (time > 0) {
            IRole roleContract = _getRoleContract();
            (CurrentHero memory hero, HeroAttrs memory attrs) = roleContract.getHeroInfo(_from);
            require(HeroStatus(hero.status) == HeroStatus.None, "No time for heroes");
            require(attrs.power > 0, "Insufficient power");

            roleInfo[_from] = poolAddr;
            roleContract.inMine(_from, time);
            _staking(poolAddr, _from, int32(attrs.power));
            roleCount++;
            emit InMine(_from, hero.tokenId);
        }
    }

    function withdraw(address poolAddr) public {
        IRole roleContract = _getRoleContract();
        (CurrentHero memory hero, HeroAttrs memory attrs) = roleContract.getHeroInfo(msg.sender);
        require(hero.tokenId != 0, "You did not enter the mine");
        require(HeroStatus(hero.status) == HeroStatus.Mine, "You did not enter the mine");

        roleContract.stopWorking(msg.sender, 0);
        delete roleInfo[msg.sender];

        uint256 endTime = hero.startTime + uint256(uint64(hero.time) * 3600);
        uint256 burnTokens = hero.time;
        address fragmentAddr = getAddress("Fragment");
        if (block.timestamp < endTime) {
            endTime = block.timestamp;
            //处理是否退还矿镐
            burnTokens = ((endTime - hero.startTime) / 3600) + (((endTime - hero.startTime) % 3600) > 0 ? 1 : 0);
            if (hero.time - burnTokens > 0) {
                IERC1155(fragmentAddr).safeTransferFrom(address(this), msg.sender, fragmentId, hero.time - burnTokens, abi.encodePacked("Return items"));
            }
        }
        //销毁矿镐
        IERC1155OP(fragmentAddr).burn(address(this), fragmentId, burnTokens);
        uint256 reward = _withdraw(poolAddr, endTime);
        //退出战力
        MineInfo memory mineInfo = getMineInfo(poolAddr, msg.sender);
        _staking(poolAddr, msg.sender, -(mineInfo.stakingAmounts));
        //发放挖矿收益
        IERC20(getAddress("Token")).transfer(msg.sender, reward);
        roleCount--;
        emit StopMine(msg.sender, hero.tokenId, attrs.power, reward);
    }

    function onERC1155Received(
        address,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes4) {
        if (msg.sender == getAddress("Fragment")) {
            (uint8 op, address poolAddr) = abi.decode(_data, (uint8, address));
            if (Operate.RoleMine == Operate(op) && fragmentId == _id) {
                //进入矿洞
                staking(_from, poolAddr, _value);
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
    ) external override returns (bytes4) {
        //暂不支持多道具
        // return ERC1155_BATCH_ACCEPTED;
    }
}
