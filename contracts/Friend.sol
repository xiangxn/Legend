// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./include/IFriend.sol";
import "./lib/Permission.sol";

struct FriendItem {
    uint256 keyIndex;
    address user;
    string name;
}
struct KeyFlag {
    address key;
    bool deleted;
}

struct itmap {
    mapping(address => FriendItem) data;
    KeyFlag[] keys;
    uint256 size;
}

contract Friend is Permission, IFriend {
    mapping(address => itmap) private friends;

    uint256 private handselFee;

    function getHandselFee() public view override returns (uint256) {
        return handselFee;
    }

    function setHandselFee(uint256 fee) public CheckPermit("admin") {
        handselFee = fee;
    }

    function insert(FriendItem calldata item) public returns (bool replaced) {
        uint256 keyIndex = friends[msg.sender].data[item.user].keyIndex;
        if (keyIndex > 0) {
            friends[msg.sender].data[item.user] = item;
            friends[msg.sender].data[item.user].keyIndex = keyIndex;
            friends[msg.sender].keys[keyIndex - 1].key = item.user;
            friends[msg.sender].keys[keyIndex - 1].deleted = false;
            return true;
        } else {
            keyIndex = friends[msg.sender].keys.length;
            friends[msg.sender].keys.push();
            friends[msg.sender].data[item.user] = item;
            friends[msg.sender].data[item.user].keyIndex = keyIndex + 1;
            friends[msg.sender].keys[keyIndex].key = item.user;
            friends[msg.sender].size++;
            return false;
        }
    }

    function remove(address user) public returns (bool success) {
        uint256 keyIndex = friends[msg.sender].data[user].keyIndex;
        if (keyIndex == 0) return false;
        delete friends[msg.sender].data[user];
        friends[msg.sender].keys[keyIndex - 1].deleted = true;
        friends[msg.sender].size--;
        return true;
    }

    function contains(address friend) internal view returns (bool) {
        uint256 keyIndex = friends[msg.sender].data[friend].keyIndex;
        return keyIndex > 0 && friends[msg.sender].keys[keyIndex - 1].deleted == false;
    }

    function contains(address owner, address friend) public view override returns (bool) {
        uint256 keyIndex = friends[owner].data[friend].keyIndex;
        return keyIndex > 0 && friends[owner].keys[keyIndex - 1].deleted == false;
    }

    function istart() public view returns (uint256 keyIndex) {
        return next(0);
    }

    function next(uint256 keyIndex) public view returns (uint256 r_keyIndex) {
        keyIndex++;
        while (keyIndex < friends[msg.sender].keys.length && friends[msg.sender].keys[keyIndex].deleted) keyIndex++;
        return keyIndex;
    }

    function valid(uint256 keyIndex) public view returns (bool) {
        return (keyIndex - 1) < friends[msg.sender].keys.length;
    }

    function getFriend(uint256 keyIndex) public view returns (FriendItem memory item) {
        address key = friends[msg.sender].keys[keyIndex - 1].key;
        item = friends[msg.sender].data[key];
    }

    function getFriends() public view returns (FriendItem[] memory list) {
        if (friends[msg.sender].size > 0) {
            list = new FriendItem[](friends[msg.sender].size);
            uint256 j;
            for (uint256 i = istart(); valid(i); i = next(i)) {
                if (friends[msg.sender].keys[i - 1].deleted == false) {
                    list[j] = getFriend(i);
                    j++;
                }
            }
        }
    }
}
