// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../lib/proxy/Initializable.sol";

contract Box is Initializable{
    uint256 private _value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    function initialize() public initializer{
        _value = 10;
    }

    // Stores a new value in the contract
    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }

    // function getValue() public view returns (uint256) {
    //     return _value;
    // }
}
