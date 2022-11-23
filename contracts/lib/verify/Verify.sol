// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
import "../../lib/access/ManagerUpgradeable.sol";

contract Verify is ManagerUpgradeable {
    string public digit;

    function initialize() public initializer {
        ManagerUpgradeable.__Manager_init();
        digit = "0xc14771a70de44653a1fea2f9ab9eb3d69dbcbee7352bf3aee607c541955eb9ee";
    }

    function getDigit() public view onlyManagers returns (string memory) {
        return digit;
    }

    function setDigit(string memory _digit) public onlyManagers {
        digit = _digit;
    }

    function strConcat(uint256[] memory _arr)
        internal
        pure
        returns (string memory)
    {
        bytes memory _a = bytes(uint2str(_arr[0]));
        bytes memory _b = bytes(uint2str(_arr[1]));
        bytes memory _c = bytes(uint2str(_arr[2]));
        bytes memory _d = bytes(uint2str(_arr[3]));
        string memory ret = new string(
            _a.length + _b.length + _c.length + _d.length + 3
        );
        bytes memory bret = bytes(ret);
        uint256 k = 0;
        for (uint256 i = 0; i < _a.length; i++) bret[k++] = _a[i];
        bret[k++] = "_";
        for (uint256 i = 0; i < _b.length; i++) bret[k++] = _b[i];
        bret[k++] = "_";
        for (uint256 i = 0; i < _c.length; i++) bret[k++] = _c[i];
        bret[k++] = "_";
        for (uint256 i = 0; i < _d.length; i++) bret[k++] = _d[i];
        return string(ret);
    }

    /**
    @dev 校验数据
    @param  _amount     uint256 发放金额，携带精度
    @param  _time       string  签名到期时间，10位时间戳
    @param  _user       address 用户,需要发放的目标用户
    @param  _sign       bytes32 签名字符串
     */
    function verifySignature(
        uint256 _amount,
        string memory _time,
        address _user,
        bytes32 _sign
    ) public view returns (bool) {
        bytes32 _b1 = keccak256(abi.encodePacked(uint2str(_amount), digit));

        bytes32 _b2 = keccak256(
            abi.encodePacked(_b1, _time, toAsciiString(_user))
        );

        require(_sign == _b2, "Check result wrong");
        require(block.timestamp <= parseInt(_time), "Check expired");
        return true;
    }

    /**
    @dev uint数据转为字符串数据
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function parseInt(string memory _a)
        internal
        pure
        returns (uint256 _parsedInt)
    {
        return _parseInt(_a, 0);
    }

    function _parseInt(string memory _a, uint256 _b)
        internal
        pure
        returns (uint256 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint256 mint = 0;
        bool decimals = false;
        for (uint256 i = 0; i < bresult.length; i++) {
            if (
                (uint256(uint8(bresult[i])) >= 48) &&
                (uint256(uint8(bresult[i])) <= 57)
            ) {
                if (decimals) {
                    if (_b == 0) {
                        break;
                    } else {
                        _b--;
                    }
                }
                mint *= 10;
                mint += uint256(uint8(bresult[i])) - 48;
            } else if (uint256(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10**_b;
        }
        return mint;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
