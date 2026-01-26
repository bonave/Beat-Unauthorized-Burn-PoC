// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    function testInitialNumberIsZero() public { 
        assertEq(counter.getNumber(), 0);
    }

    function testIncrementIncreasesNumber() public { 
        counter.increment();
        assertEq(counter.getNumber(), 1);
        counter.increment();
        assertEq(counter.getNumber(), 2);

        for (uint256 i=0; i<8; i++) {
            counter.increment();
        }
        assertEq(counter.getNumber(), 10);
    }
}
