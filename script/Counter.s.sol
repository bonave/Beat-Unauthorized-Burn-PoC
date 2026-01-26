// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

  contract CounterScript is Script {
    Counter public counter;
    

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
    
        counter = new Counter();
        counter.increment();
        counter.increment();
        uint256 currentNumber = counter.getNumber();
        console.log("currentNumber is:", currentNumber);
        
         vm.stopBroadcast();
    }
}
