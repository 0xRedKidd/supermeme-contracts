pragma solidity 0.8.20;

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Factories/DegenFactory.sol";
import "../src/Factories/LockingCurveFactory.sol";
import "../src/Factories/RefundableFactory.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/Factories/SuperMemeRegistry.sol";
import "../src/SuperMemeRevenueCollector.sol";

import "../src/SuperMemeToken/SuperMemePublicStaking.sol";
import "../src/SuperMemeToken/SuperMemeTreasuryVesting.sol";
import "../src/SuperMemeToken/SuperMeme.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";
//import router
import {IUniswapV2Router02} from "../src/Interfaces/IUniswapV2Router02.sol";

contract TestDex is Test {
    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;

    IUniswapFactory public uniswapFactory;
    RefundableFactory public refundableFactory;
    DegenFactory public degenFactory;
    LockingCurveFactory public lockingCurveFactory;
    SuperMemeDegenBondingCurve public degenbondingcurve;
    SuperMemeDegenBondingCurve public degenbondingcurve2;
    SuperMemeRegistry public registry;
    SuperMemeRevenueCollector public revenueCollector;
    IUniswapV2Router02 public uniswapRouter;
    SuperMeme public spr;
    SuperMemeTreasuryVesting public treasuryVesting;
    SuperMemePublicStaking public publicStaking;

    uint256 public createTokenRevenue = 0.0008 ether;

    address public owner = address(0x123);
    address public addr1 = address(0x456);
    address public addr2 = address(0x789);
    address public addr3 = address(0x101112);

    uint256 public tgeDate = 1732482000;



    function setUp() public {
        vm.deal(owner, 1000 ether);
        vm.deal(addr1, 1000 ether);

        uint256 createTokenRevenue = 0.00001 ether;

        spr = new SuperMeme();
        publicStaking = new SuperMemePublicStaking(address(spr));
        treasuryVesting = new SuperMemeTreasuryVesting(address(spr), tgeDate);


        revenueCollector = new SuperMemeRevenueCollector(address(spr), address(publicStaking), address(treasuryVesting));

        uniswapRouter = IUniswapV2Router02(address(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24));


        registry = new SuperMemeRegistry();
        degenFactory = new DegenFactory(address(registry));
        refundableFactory = new RefundableFactory(address(registry));
        lockingCurveFactory = new LockingCurveFactory(address(registry));
   

        degenFactory.setRevenueCollector(address(revenueCollector));
        refundableFactory.setRevenueCollector(address(revenueCollector));
        lockingCurveFactory.setRevenueCollector(address(revenueCollector));


        degenFactory.setCreateTokenRevenue(createTokenRevenue);
        refundableFactory.setCreateTokenRevenue(createTokenRevenue);
        lockingCurveFactory.setCreateTokenRevenue(createTokenRevenue);
 



        registry.setFactory(address(degenFactory));
        registry.setFactory(address(refundableFactory));
        registry.setFactory(address(lockingCurveFactory));
 
        

        degenbondingcurve = new SuperMemeDegenBondingCurve(
            "SuperMeme",
            "MEME",
            false,
            0,
            owner,
            address(0x123),
            0,
            0
        );

        uniswapFactory = IUniswapFactory(address(0x1));
    }
    function testDeploy() public {
        assertEq(degenFactory.revenueCollector(), (address(revenueCollector)));
        assertEq(refundableFactory.revenueCollector(), (address(revenueCollector)));
        assertEq(lockingCurveFactory.revenueCollector(), (address(revenueCollector)));
    }

    function testForSlippage() public {
        vm.startPrank(addr1);
        address newToken = degenFactory.createToken{value: createTokenRevenue}(
            "SuperMeme",
            "MEME",
            false,
            0,
            address(addr1),
            0,
            0
        );
        assertEq(degenFactory.tokenAddresses(0), newToken);

        degenbondingcurve2 = SuperMemeDegenBondingCurve(newToken);

        uint256 amount = 800_000_000;
        uint256 cost = degenbondingcurve2.calculateCost(amount);
        uint256 tax = cost/100;
        uint256 totalCost = cost + tax;
        uint256 slippage = (totalCost * 500) / 10000 ;
        uint256 totalCostWithSlippage = totalCost + slippage;

        degenbondingcurve2.buyTokens{value: totalCostWithSlippage}(amount);

        uint256 lastPrice = degenbondingcurve2.calculateCost(1);
        console.log("Last price: ", lastPrice);

        assertEq(degenbondingcurve2.balanceOf(address(addr1)), amount * 10 ** 18);
        assertEq(degenbondingcurve2.bondingCurveCompleted(), true);

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(degenbondingcurve2);

        uint256 tokenBalanceBefore = degenbondingcurve2.balanceOf(address(addr1));


        uint256 getAmountsOut = uniswapRouter.getAmountsOut(0.1 ether, path)[1];
        console.log("Amounts out: ", getAmountsOut);


        uniswapRouter.swapExactETHForTokens{value: 0.1 ether}(0, path, address(addr1), block.timestamp + 1000);
        uint256 tokenBalanceAfter = degenbondingcurve2.balanceOf(address(addr1));
        uint256 boughtTokens = tokenBalanceAfter - tokenBalanceBefore;
        console.log("Bought tokens: ", boughtTokens);

        //Sell
        uint256 ethBalanceBeforeSell = address(addr1).balance;
        path[0] = address(degenbondingcurve2);
        path[1] = uniswapRouter.WETH();
        degenbondingcurve2.approve(address(uniswapRouter), boughtTokens);
        uint256 getAmountsOutSell = uniswapRouter.getAmountsOut(boughtTokens, path)[1];
        console.log("Amounts out eth sell: ", getAmountsOutSell);
        uniswapRouter.swapExactTokensForETH(boughtTokens, 0, path, address(addr1), block.timestamp + 1000);
        uint256 ethBalanceAfterSell = address(addr1).balance;
        uint256 soldTokens = ethBalanceAfterSell - ethBalanceBeforeSell;
        console.log("Received eth: ", soldTokens);


    }

    function testDexBuys() public {
        vm.startPrank(addr1);
        address newToken = degenFactory.createToken{value: createTokenRevenue}(
            "SuperMeme",
            "MEME",
            false,
            0,
            address(addr1),
            0,
            0
        );
        assertEq(degenFactory.tokenAddresses(0), newToken);

        degenbondingcurve2 = SuperMemeDegenBondingCurve(newToken);

        uint256 amount = 800_000_000;
        uint256 cost = degenbondingcurve2.calculateCost(amount);
        uint256 tax = cost/100;
        uint256 totalCost = cost + tax;
        uint256 slippage = (totalCost * 500) / 10000 ;
        uint256 totalCostWithSlippage = totalCost + slippage;

        degenbondingcurve2.buyTokens{value: totalCostWithSlippage}(amount);

        uint256 lastPrice = degenbondingcurve2.calculateCost(1);
        console.log("Last price: ", lastPrice);

        assertEq(degenbondingcurve2.balanceOf(address(addr1)), amount * 10 ** 18);
        assertEq(degenbondingcurve2.bondingCurveCompleted(), true);

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(degenbondingcurve2);

        uint256 tokenBalanceBefore = degenbondingcurve2.balanceOf(address(addr1));


        // uint256 getAmountsOut = uniswapRouter.getAmountsOut(0.1 ether, path)[1];
        // console.log("Amounts out: ", getAmountsOut);
        uint256 totalAmountBought;

        for (uint256 i = 0; i < 20; i++) {
            
            uint256 tokenBalanceBefore = degenbondingcurve2.balanceOf(address(addr1));
            uniswapRouter.swapExactETHForTokens{value: 10 ether}(0, path, address(addr1), block.timestamp + 1000);
            uint256 tokenBalanceAfter = degenbondingcurve2.balanceOf(address(addr1));
            uint256 boughtTokens = tokenBalanceAfter - tokenBalanceBefore;
            console.log("Bought tokens: ", boughtTokens / 10 ** 18, " for ", 1 ether);
            totalAmountBought += boughtTokens / 10 ** 18;
        }

        console.log("Total bought: ", totalAmountBought);

        // uniswapRouter.swapExactETHForTokens{value: 0.1 ether}(0, path, address(addr1), block.timestamp + 1000);
        // uint256 tokenBalanceAfter = degenbondingcurve2.balanceOf(address(addr1));
        // uint256 boughtTokens = tokenBalanceAfter - tokenBalanceBefore;
        // console.log("Bought tokens: ", boughtTokens);


    }

}