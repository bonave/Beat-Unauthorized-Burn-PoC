// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Counter {
    uint256 private number;

    function increment() public {
        number++;
    }

    function decrement() public {
        number--;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }
}
