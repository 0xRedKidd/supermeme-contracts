// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SuperMemeAiBondingCurve.sol";
import "../src/SuperMemeToken/SuperMeme.sol";

/// @notice Minimal mock Uniswap V2 Router for testing purposes.
contract MockUniswapV2Router is IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint, // amountAMin
        uint, // amountBMin
        address, // to
        uint // deadline
    ) external override returns (uint amountA, uint amountB, uint liquidity) {
        return (amountADesired, amountBDesired, 123456);
    }
}

contract SuperMemeAiBondingCurveTest is Test {
    // Our mocks.
    SuperMeme spr;
    MockUniswapV2Router router;
    // The constant addresses from the contract.
    address constant SPR_TOKEN_ADDRESS = 0x77184100237e46b06cd7649aBf37435F5D5e678B;
    address constant UNISWAP_V2_ROUTER_ADDRESS = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    
    // Use the provided buyer address (has sufficient SPR balance in the fork).
    address buyer = 0x6F69C5363dd8c21256d40d47caBFf5242AD14e3E;
    address recipient = address(0x1234); // EOA for transfer tests.
    
    // =========================================================================
    // Helper functions for formatting numbers for logging (6 decimals)
    // =========================================================================
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
    // =========================================================================

    function setUp() public {
        spr = SuperMeme(0x77184100237e46b06cd7649aBf37435F5D5e678B);
        router = new MockUniswapV2Router();
        // "Place" our mocks at the constant addresses.
        vm.etch(SPR_TOKEN_ADDRESS, address(spr).code);
        vm.etch(UNISWAP_V2_ROUTER_ADDRESS, address(router).code);
        // In a forked environment, the buyer already has sufficient SPR balance.
        // Optionally, you could mint additional SPR tokens if needed.
    }
    
    /// @notice Test buying tokens for bonding curves that collect 800k, 1M, and 1.2M SPR tokens.
    function testBuyTokensForDifferentTotalSpr() public {
        uint256 purchaseAmount = 1_000_000;
        uint256[] memory totalSprValues = new uint256[](3);
        totalSprValues[0] = 800e3 * 1e18;
        totalSprValues[1] = 1e6 * 1e18;
        totalSprValues[2] = 1.2e6 * 1e18;

        // Check the SPR balance of the buyer.
        uint256 buyerSprBalance = spr.balanceOf(buyer);
        console.log("Buyer SPR balance before purchase (SPR):", formatSPR(buyerSprBalance));
        
        for (uint256 i = 0; i < totalSprValues.length; i++) {
            SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(totalSprValues[i]);
            console.log("========================================");
            console.log("Testing with total SPR required (SPR):", uint2str(totalSprValues[i] / 1e18));
            
            uint256 cost = bondingCurve.calculateCost(purchaseAmount);
            console.log("Cost to buy 1e6 tokens (SPR):", formatSPR(cost));
            
            vm.prank(buyer);
            IERC20(SPR_TOKEN_ADDRESS).approve(address(bondingCurve), cost);
            
            uint256 buyerInitialSPR = spr.balanceOf(buyer);
            console.log("Buyer SPR balance before purchase (SPR):", formatSPR(buyerInitialSPR));
            
            vm.prank(buyer);
            bondingCurve.buyTokens(purchaseAmount);
            
            uint256 newScaledSupply = bondingCurve.scaledSupply();
            console.log("Scaled supply after purchase:", uint2str(newScaledSupply));
            assertEq(newScaledSupply, purchaseAmount, "Scaled supply should equal the purchase amount");
            
            uint256 buyerTokenBalance = bondingCurve.balanceOf(buyer);
            console.log("Buyer SMT token balance after purchase:", uint2str(buyerTokenBalance));
            assertEq(buyerTokenBalance, purchaseAmount, "Buyer should receive the purchased tokens");
            
            uint256 buyerFinalSPR = spr.balanceOf(buyer);
            uint256 spent = buyerInitialSPR - buyerFinalSPR;
            console.log("SPR spent by buyer (SPR):", formatSPR(spent));
            assertEq(spent, cost, "Buyer SPR balance should decrease by the cost amount");
        }
    }
    
    /// @notice Test the incremental cost growth behavior for each total SPR target.
    function testIncrementalCostGrowthForDifferentTotalSpr() public {
        uint256[] memory totalSprValues = new uint256[](3);
        totalSprValues[0] = 800e3 * 1e18;
        totalSprValues[1] = 1e6 * 1e18;
        totalSprValues[2] = 1.2e6 * 1e18;
        
        for (uint256 j = 0; j < totalSprValues.length; j++) {
            SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(totalSprValues[j]);
            console.log("========================================");
            console.log("Testing incremental cost growth with total SPR required (SPR):", uint2str(totalSprValues[j] / 1e18));
            
            uint256 firstPrice = bondingCurve.calculateCost(1);
            console.log("Initial price for 1 token (SPR):", formatSPR(firstPrice));
            
            for (uint256 i = 0; i < 20; i++) {
                uint256 purchaseAmount = 50_000_000;
                vm.startPrank(buyer);
                uint256 cost = bondingCurve.calculateCost(purchaseAmount);
                IERC20(SPR_TOKEN_ADDRESS).approve(address(bondingCurve), cost);
                bondingCurve.buyTokens(purchaseAmount);
                uint256 priceForOne = bondingCurve.calculateCost(1);
                console.log(
                    "After supply", 
                    uint2str(bondingCurve.scaledSupply()), 
                    "price for 1 token (SPR):", 
                    formatSPR(priceForOne)
                );
                vm.stopPrank();
            }
        }
    }
    
    /// @notice Test selling tokens for bonding curves that collect 800k, 1M, and 1.2M SPR tokens.
    function testSellTokensForDifferentTotalSpr() public {
        uint256 purchaseAmount = 1_000_000;
        uint256 saleAmount = 500_000;
        
        uint256[] memory totalSprValues = new uint256[](3);
        totalSprValues[0] = 800e3 * 1e18;
        totalSprValues[1] = 1e6 * 1e18;
        totalSprValues[2] = 1.2e6 * 1e18;
        
        for (uint256 i = 0; i < totalSprValues.length; i++) {
            SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(totalSprValues[i]);
            console.log("========================================");
            console.log("Testing sell tokens with total SPR required (SPR):", uint2str(totalSprValues[i] / 1e18));
            
            uint256 buyCost = bondingCurve.calculateCost(purchaseAmount);
            vm.prank(buyer);
            IERC20(SPR_TOKEN_ADDRESS).approve(address(bondingCurve), buyCost);
            vm.prank(buyer);
            bondingCurve.buyTokens(purchaseAmount);
            uint256 buyerSMTAfterBuy = bondingCurve.balanceOf(buyer);
            assertEq(buyerSMTAfterBuy, purchaseAmount, "Buyer SMT balance mismatch after purchase");

            uint256 expectedRefund = bondingCurve.calculateSellTokenAmount(saleAmount);
            
            uint256 buyerSPRBeforeSell = spr.balanceOf(buyer);
            
            vm.prank(buyer);
            bondingCurve.sellTokens(saleAmount);
            
            uint256 buyerSMTAfterSell = bondingCurve.balanceOf(buyer);
            assertEq(buyerSMTAfterSell, purchaseAmount - saleAmount, "Buyer SMT balance mismatch after sell");
            
            uint256 newScaledSupply = bondingCurve.scaledSupply();
            assertEq(newScaledSupply, purchaseAmount - saleAmount, "Scaled supply not updated correctly");
            
            uint256 buyerSPRAfterSell = spr.balanceOf(buyer);
            assertEq(buyerSPRAfterSell, buyerSPRBeforeSell + expectedRefund, "Buyer SPR balance did not increase by refund amount");
            
            console.log("Expected refund for selling", uint2str(saleAmount), "tokens (SPR):", formatSPR(expectedRefund));
        }
    }
    
    /// @notice Test that SMT token transfers are disallowed before the sale is complete.
    function testTransferRestrictionBeforeSaleComplete() public {
        uint256 totalSprRequired = 1e6 * 1e18;
        SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(totalSprRequired);
        
        uint256 purchaseAmount = 1_000_000;
        uint256 cost = bondingCurve.calculateCost(purchaseAmount);
        vm.prank(buyer);
        IERC20(SPR_TOKEN_ADDRESS).approve(address(bondingCurve), cost);
        vm.prank(buyer);
        bondingCurve.buyTokens(purchaseAmount);
        
        uint256 contractSprBalance = IERC20(SPR_TOKEN_ADDRESS).balanceOf(address(bondingCurve));
        console.log("Contract SPR balance (SPR):", formatSPR(contractSprBalance));
        assertLt(contractSprBalance, totalSprRequired);
        
        vm.prank(buyer);
        vm.expectRevert("Transfers disabled until sale complete");
        bondingCurve.transfer(recipient, 100);
    }
    
    /// @notice Test that SMT token transfers are allowed after the bonding curve collects the required SPR tokens.
    function testTransferAllowedAfterSaleComplete() public {
        uint256 totalSprRequired = 1e6 * 1e18;
        SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(totalSprRequired);
        
        uint256 purchaseAmount = 1_000_000;
        uint256 cost = bondingCurve.calculateCost(purchaseAmount);
        vm.prank(buyer);
        IERC20(SPR_TOKEN_ADDRESS).approve(address(bondingCurve), cost);
        vm.prank(buyer);
        bondingCurve.buyTokens(purchaseAmount);
        
        uint256 contractSprBalance = IERC20(SPR_TOKEN_ADDRESS).balanceOf(address(bondingCurve));
        console.log("Contract SPR balance before manual top-up (SPR):", formatSPR(contractSprBalance));
        assertLt(contractSprBalance, totalSprRequired);
        
        uint256 extraNeeded = totalSprRequired - contractSprBalance;
        vm.prank(buyer);
        spr.transfer(address(bondingCurve), extraNeeded);
        
        uint256 newContractSprBalance = IERC20(SPR_TOKEN_ADDRESS).balanceOf(address(bondingCurve));
        console.log("Contract SPR balance after manual top-up (SPR):", formatSPR(newContractSprBalance));
        assertGe(newContractSprBalance, totalSprRequired);
        
        vm.prank(buyer);
        bool success = bondingCurve.transfer(recipient, 100);
        require(success, "Transfer should succeed after sale complete");
        
        uint256 recipientBalance = bondingCurve.balanceOf(recipient);
        console.log("Recipient SMT token balance:", uint2str(recipientBalance));
        assertEq(recipientBalance, 100);
    }
    
    /// @notice Test that SMT tokens cannot be transferred to an arbitrary address before sale is complete.
    function testCannotTransferToNonContractBeforeSaleComplete() public {
        uint256 totalSprRequired = 1e6 * 1e18;
        SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(totalSprRequired);
        
        uint256 purchaseAmount = 1_000_000;
        uint256 cost = bondingCurve.calculateCost(purchaseAmount);
        vm.prank(buyer);
        IERC20(SPR_TOKEN_ADDRESS).approve(address(bondingCurve), cost);
        vm.prank(buyer);
        bondingCurve.buyTokens(purchaseAmount);
        
        uint256 contractSprBalance = IERC20(SPR_TOKEN_ADDRESS).balanceOf(address(bondingCurve));
        console.log("Contract SPR balance (SPR):", formatSPR(contractSprBalance));
        assertLt(contractSprBalance, totalSprRequired);
        
        vm.prank(buyer);
        vm.expectRevert("Transfers disabled until sale complete");
        bondingCurve.transfer(recipient, 50);
    }
    
    /// @notice Test sendToDex.
    /// The test buys the full supply (1e9 tokens), triggers sendToDex, and then simulates a trade
    /// by computing the SMT price in SPR as the ratio (normalized to 1e18) of the SPR amount used for liquidity over the liquidity SMT tokens.
    function testSendToDex() public {
        // Use the full supply.
        uint256 fullSupply = 800_000_000;
        uint256 totalSprRequired = 800_000 ether; // Using the same total SPR required for sale completion.
        SuperMemeAiBondingCurve bondingCurve = new SuperMemeAiBondingCurve(totalSprRequired);
        
        // Buyer purchases the entire supply.
        uint256 cost = bondingCurve.calculateCost(fullSupply);
        vm.prank(buyer);
        IERC20(SPR_TOKEN_ADDRESS).approve(address(bondingCurve), cost);
        vm.prank(buyer);
        bondingCurve.buyTokens(fullSupply);
        assertEq(bondingCurve.scaledSupply(), fullSupply, "Full supply not sold");
        uint256 lastPriceinCurve = bondingCurve.calculateCost(1);
        console.log("Last price in curve (SPR):", formatSPR(lastPriceinCurve));
        // Trigger sendToDex.
        vm.prank(buyer);
        //bondingCurve.sendToDex();
        assertTrue(bondingCurve.liquiditySent(), "Liquidity not sent");
        
        // Simulate a trade on Uniswap: since our mock router doesn't implement swap,
        // we compute a dummy price as: (sprUsed * 1e18) / LIQUIDITY_TOKEN_AMOUNT.
        // Retrieve the SPR amount used for liquidity.
        // Note: In our sendToDex, the SPR amount is read before calling addLiquidity.
        uint256 sprUsed = IERC20(SPR_TOKEN_ADDRESS).balanceOf(address(bondingCurve));
        // The liquidity SMT tokens added are LIQUIDITY_TOKEN_AMOUNT.
        // Compute the price (in SPR wei per SMT token).
        uint256 price = (sprUsed * 1e18) / bondingCurve.LIQUIDITY_TOKEN_AMOUNT();
        console.log("Dummy SMT price in SPR (wei per token):", formatSPR(price));
    }
}
