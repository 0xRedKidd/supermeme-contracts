// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SuperMemeAiBondingCurve.sol";

/// @notice A minimal mock SPR token for testing.
contract MockSPR {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    function mint(address account, uint256 amount) public {
        balanceOf[account] += amount;
        totalSupply += amount;
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[sender] -= amount;
        allowance[sender][msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }
}

contract SuperMemeAiBondingCurveTest is Test {
    SuperMemeAiBondingCurve bondingCurve;
    MockSPR spr;
    address buyer = address(0xABCD);
    
    function setUp() public {
        // Deploy the mock SPR token and mint a large balance to the buyer.
        spr = new MockSPR();
        // Mint 2 million SPR tokens (in wei, 2e24) to the buyer.
        spr.mint(buyer, 5_000_000 * 1e18);
        
        // Deploy the bonding curve contract with the mock SPR token's address.
        bondingCurve = new SuperMemeAiBondingCurve(address(spr));
    }
    
    function testBuyTokens() public {
        // Purchase 1,000,000 tokens.
        uint256 purchaseAmount = 1_000_000;
        
        uint256 cost = bondingCurve.calculateCost(purchaseAmount);
        console.log("Cost to buy 1e6 tokens (in SPR wei):", cost);
        
        // Impersonate the buyer to approve the bonding curve contract.
        vm.prank(buyer);
        spr.approve(address(bondingCurve), cost);
        
        uint256 buyerInitialSPR = spr.balanceOf(buyer);
        console.log("Buyer SPR balance before:", buyerInitialSPR);
        
        // Buyer calls buyTokens.
        vm.prank(buyer);
        bondingCurve.buyTokens(purchaseAmount);
        
        uint256 newScaledSupply = bondingCurve.scaledSupply();
        console.log("Scaled supply after purchase:", newScaledSupply);
        assertEq(newScaledSupply, purchaseAmount, "Scaled supply should equal the purchase amount");
        
        uint256 buyerTokenBalance = bondingCurve.balanceOf(buyer);
        console.log("Buyer SMT token balance after purchase:", buyerTokenBalance);
        assertEq(buyerTokenBalance, purchaseAmount, "Buyer should receive the purchased tokens");
        
        uint256 buyerFinalSPR = spr.balanceOf(buyer);
        uint256 spent = buyerInitialSPR - buyerFinalSPR;
        console.log("SPR spent by buyer:", spent);
        assertEq(spent, cost, "Buyer SPR balance should decrease by the cost amount");
    }
    
    function testIncrementalCostGrowth() public {
        // Purchase tokens in 1,000,000-token increments, and log the price for 1 additional token.
        for (uint256 i = 0; i < 20; i++) {
            uint256 purchaseAmount = 50_000_000;
            vm.startPrank(buyer);
            uint256 cost = bondingCurve.calculateCost(purchaseAmount);
            spr.approve(address(bondingCurve), cost);
            bondingCurve.buyTokens(purchaseAmount);
            uint256 priceForOne = bondingCurve.calculateCost(1);
            console.log("After supply", bondingCurve.scaledSupply(), "price for 1 token is", priceForOne);
            vm.stopPrank();
        }
    }
}
