pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

library Uinteger {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require (result >= MIN_64x64 && result <= MAX_64x64);
            return int128 (result);
        }
    }

    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require (result >= MIN_64x64 && result <= MAX_64x64);
            return int128 (result);
        }
    }

    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) * y >> 64;
            require (result >= MIN_64x64 && result <= MAX_64x64);
            return int128 (result);
        }
    }

    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require (y != 0);
            int256 result = (int256 (x) << 64) / y;
            require (result >= MIN_64x64 && result <= MAX_64x64);
            return int128 (result);
        }
    }

    function toString(uint256 a, uint256 radix) internal pure returns (string memory) {
        if (a == 0) {
            return "0";
        }
        uint256 j = a;
        uint256 length;
        while (j != 0) {
            length++;
            j /= radix;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = a;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % radix)));
            j /= radix;
        }
        return string(bstr);
    }

    function toString(uint256 self) internal pure returns (string memory) {
        return Uinteger.toString(self, 10);
    }

    function pow(int128 x, uint256 y) internal pure returns(int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;
            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = absResult * absX >> 127;
                    }
                    absX = absX * absX >> 127;

                    if (y & 0x2 != 0) {
                        absResult = absResult * absX >> 127;
                    }
                    absX = absX * absX >> 127;

                    if (y & 0x4 != 0) {
                        absResult = absResult * absX >> 127;
                    }
                    absX = absX * absX >> 127;

                    if (y & 0x8 != 0) {
                        absResult = absResult * absX >> 127;
                    }
                    absX = absX * absX >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
                if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
                if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
                if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
                if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
                if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = absResult * absX >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = absX * absX >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require (x <= 0x7FFFFFFFFFFFFFFF);
            return int128 (int256 (x << 64));
        }
    }
}
