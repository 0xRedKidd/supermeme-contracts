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
    MockSPR spr;
    address buyer = address(0xABCD);
    address recipient = address(0x1234); // Non-contract (EOA) recipient.

    function setUp() public {
        spr = new MockSPR();
        // Mint 5,000,000 SPR tokens (in wei) to the buyer.
        spr.mint(buyer, 5_000_000 * 1e18);
    }
    
    /// @notice Helper functions for formatting numbers for logging (with 6 decimals).
    function uint2str(uint256 _i) internal pure returns (string memory) {
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
        uint256 k = len;
        j = _i;
        while (j != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + j % 10);
            bstr[k] = bytes1(temp);
            j /= 10;
        }
        return string(bstr);
    }
    function padFraction(string memory frac) internal pure returns (string memory) {
        bytes memory b = bytes(frac);
        if (b.length >= 6) {
            return frac;
        }
        bytes memory padded = new bytes(6);
        uint256 zeros = 6 - b.length;
        uint256 i;
        for (i = 0; i < zeros; i++) {
            padded[i] = "0";
        }
        for (uint256 j = 0; j < b.length; j++) {
            padded[i + j] = b[j];
        }
        return string(padded);
    }
    function formatSPR(uint256 amount) internal pure returns (string memory) {
        uint256 integerPart = amount / 1e18;
        uint256 fractionalPart = (amount % 1e18) / 1e12; // yields 6 decimals
        return string(abi.encodePacked(uint2str(integerPart), ".", padFraction(uint2str(fractionalPart))));
    }
    
    /// @notice Test that SMT token transfers between users are disallowed before the sale is complete.
    function testTransferRestrictionBeforeSaleComplete() public {
        // Use a relatively small total SPR requirement so that a purchase does not complete the sale.
        uint256 totalSprRequired = 1e6 * 1e18; // 1,000,000 SPR tokens required (in wei)
        SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(address(spr), totalSprRequired);
        
        // Buyer purchases some SMT tokens.
        uint256 purchaseAmount = 1_000_000; // tokens purchased
        uint256 cost = bondingCurve.calculateCost(purchaseAmount);
        vm.prank(buyer);
        spr.approve(address(bondingCurve), cost);
        vm.prank(buyer);
        bondingCurve.buyTokens(purchaseAmount);
        
        // At this point the SPR balance in the bonding curve is less than totalSprRequired.
        uint256 contractSprBalance = spr.balanceOf(address(bondingCurve));
        console.log("Contract SPR balance (SPR):", formatSPR(contractSprBalance));
        assertLt(contractSprBalance, totalSprRequired);
        
        // Buyer now attempts to transfer SMT tokens to a different address.
        vm.prank(buyer);
        vm.expectRevert("Transfers disabled until sale complete");
        bondingCurve.transfer(recipient, 100);
    }
    
    /// @notice Test that SMT token transfers are allowed after the bonding curve has collected the required SPR tokens.
    function testTransferAllowedAfterSaleComplete() public {
        // Use a relatively small total SPR requirement.
        uint256 totalSprRequired = 1e6 * 1e18; // 1,000,000 SPR tokens required (in wei)
        SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(address(spr), totalSprRequired);
        
        // Buyer purchases SMT tokens.
        uint256 purchaseAmount = 1_000_000; // tokens purchased
        uint256 cost = bondingCurve.calculateCost(purchaseAmount);
        vm.prank(buyer);
        spr.approve(address(bondingCurve), cost);
        vm.prank(buyer);
        bondingCurve.buyTokens(purchaseAmount);
        
        // At this point, the SPR balance in the bonding curve is less than required.
        uint256 contractSprBalance = spr.balanceOf(address(bondingCurve));
        console.log("Contract SPR balance before manual top-up (SPR):", formatSPR(contractSprBalance));
        assertLt(contractSprBalance, totalSprRequired);
        
        // Simulate sale complete by transferring extra SPR tokens from buyer directly to the bonding curve.
        uint256 extraNeeded = totalSprRequired - contractSprBalance;
        vm.prank(buyer);
        spr.transfer(address(bondingCurve), extraNeeded);
        
        // Verify that the bonding curve's SPR balance is now at least the required amount.
        uint256 newContractSprBalance = spr.balanceOf(address(bondingCurve));
        console.log("Contract SPR balance after manual top-up (SPR):", formatSPR(newContractSprBalance));
        assertGe(newContractSprBalance, totalSprRequired);
        
        // Now the buyer transfers some SMT tokens to the recipient.
        vm.prank(buyer);
        bool success = bondingCurve.transfer(recipient, 100);
        require(success, "Transfer should succeed after sale complete");
        
        // Verify that the recipient received the SMT tokens.
        uint256 recipientBalance = bondingCurve.balanceOf(recipient);
        console.log("Recipient SMT token balance:", uint2str(recipientBalance));
        assertEq(recipientBalance, 100);
    }
    
    /// @notice Test that SMT tokens cannot be transferred to an arbitrary (non-contract) address before the sale is complete.
    function testCannotTransferToNonContractBeforeSaleComplete() public {
        // Use a relatively small total SPR requirement.
        uint256 totalSprRequired = 1e6 * 1e18; // ,000,000 SPR tokens required (in wei)
        SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(address(spr), totalSprRequired);
        
        // Buyer purchases SMT tokens.
        uint256 purchaseAmount = 1_000_00; // tokens purchased
        uint256 cost = bondingCurve.calculateCost(purchaseAmount);
        vm.prank(buyer);
        spr.approve(address(bondingCurve), cost);
        vm.prank(buyer);
        bondingCurve.buyTokens(purchaseAmount);
        
        // Check the contract's SPR balance is below the required amount.
        uint256 contractSprBalance = spr.balanceOf(address(bondingCurve));
        console.log("Contract SPR balance (SPR):", formatSPR(contractSprBalance));
        assertLt(contractSprBalance, totalSprRequired);
        
        // Buyer attempts to transfer SMT tokens to a random EOA (recipient).
        vm.prank(buyer);
        vm.expectRevert("Transfers disabled until sale complete");
        bondingCurve.transfer(recipient, 50);
    }
    
    // (Other tests such as testBuyTokensForDifferentTotalSpr, testIncrementalCostGrowthForDifferentTotalSpr,
    //  testSellTokensForDifferentTotalSpr, and testCurveUpAndDown would remain unchanged.)
}
