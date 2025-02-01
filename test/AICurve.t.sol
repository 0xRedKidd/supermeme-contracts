// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

// Adjust the path below to where your contract is located.
import "../src/SuperMemeDegenBondingCurve.sol";

contract AICurveTest is Test {
    SuperMemeDegenBondingCurve bondingCurve;

    // For testing purposes, we provide dummy addresses.
    address dummyRevenueCollector = address(0xDEAD);
    address dummyUniswapRouter = address(0xBEEF);

    // setUp is called before each test
    function setUp() public {
        // Deploy the contract.
        // Note: The constructor parameters are:
        //   _name, _symbol, _revenueCollector, _uniswapRouter
        bondingCurve = new SuperMemeDegenBondingCurve("Bonding Token", "BOND", dummyRevenueCollector, dummyUniswapRouter);
    }

    /// @notice Test calling calculateCost with different values.
    function testCalculateCost() public {
        // Call calculateCost with several different amounts.
        uint256 costFor1 = bondingCurve.calculateCost(1);
        uint256 costFor10 = bondingCurve.calculateCost(10);
        uint256 costFor100 = bondingCurve.calculateCost(100);
        uint256 costFor1000 = bondingCurve.calculateCost(1000);

        // Log the costs (using Foundry's console.log).
        console.log("Cost for 1 token unit:", costFor1);
        console.log("Cost for 10 token units:", costFor10);
        console.log("Cost for 100 token units:", costFor100);
        console.log("Cost for 1000 token units:", costFor1000);

        // Basic assertions: since the bonding curve is strictly increasing,
        // each cost should be greater than the previous one.
        assertGt(costFor10, costFor1);
        assertGt(costFor100, costFor10);
        assertGt(costFor1000, costFor100);
    }

    /// @notice Optionally, test calculateCost with a loop of increasing amounts.
    function testCalculateCostLoop() public {
        for (uint256 i = 1; i <= 5; i++) {
            uint256 amount = i * 50; // example values: 50, 100, 150, 200, 250
            uint256 cost = bondingCurve.calculateCost(amount);
            console.log("Cost for", amount, "token units:", cost);
        }
    }
}
