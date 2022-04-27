// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Array {
    function checkIn(uint256[] memory data, uint256 m) internal pure returns (bool) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == m) return true;
        }
        return false;
    }

    function checkRepeat(uint256[] calldata data, bool isZero) internal pure returns (bool) {
        uint256[] memory tmps = new uint256[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            if (checkIn(tmps, data[i]) == false || (isZero && data[i] == 0)) {
                tmps[i] = data[i];
            } else {
                return true;
            }
        }
        return false;
    }
}
