pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Factories/DegenFactory.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/SuperMemeRevenueCollector.sol";
import "../src/Factories/SuperMemeRegistry.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";
import {IUniswapV2Router02} from "../src/Interfaces/IUniswapV2Router02.sol";


contract DegenBondingCurveTest is Test {
    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;

    DegenFactory public degenFactory;
    SuperMemeDegenBondingCurve public degenbondingcurve;
    SuperMemeRegistry public registry;
    SuperMemeRevenueCollector public revenueCollector;
    IUniswapV2Router02 public router;
    SuperMemeDegenBondingCurve public devLockDegen;


    address public owner = address(0x123);
    address public addr1 = address(0x456);
    address public addr2 = address(0x789);
    address public addr3 = address(0x101112);

    uint256 public createTokenRevenue = 0.0008 ether;

    uint256 devLockAmount = 700000;


    function setUp() public {
        vm.deal(owner, 1000 ether);
        vm.deal(addr1, 1000 ether);
        vm.deal(addr2, 1000 ether);
        vm.deal(addr3, 1000 ether);

            //base mainnet router address 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        //base sepolia router address 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        router = IUniswapV2Router02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24);

        vm.startPrank(owner);
        registry = new SuperMemeRegistry();
        degenFactory = new DegenFactory(address(registry));
        registry.setFactory(address(degenFactory));

        degenbondingcurve = SuperMemeDegenBondingCurve(degenFactory.createToken{value: createTokenRevenue}("name", "symbol", false,0, owner, 0, 0));

 
        uint256 cost = degenbondingcurve.calculateCost(devLockAmount);
        uint256 tax = cost / 100;
        uint256 totalCost = cost + tax;
        uint256 slippage = totalCost / 100;
        uint256 totalCostWithSlippage = totalCost + slippage;
        vm.stopPrank();

        vm.startPrank(addr3);
        devLockDegen = SuperMemeDegenBondingCurve(degenFactory.createToken{value: createTokenRevenue + totalCostWithSlippage }("name", "symbol", true, devLockAmount, addr3, 1 weeks, totalCostWithSlippage));
        vm.stopPrank();
    }

    function test_createToken() public {
        assertEq(degenbondingcurve.scaledSupply(),200000000);   
    }
    function testCompleteCurveDegen() public {
        uint256 amount = 800000000;
        vm.startPrank(addr1);
            uint256 cost = degenbondingcurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            degenbondingcurve.buyTokens{value: totalCostWithSlippage}(
                amount
            );
            assertEq(degenbondingcurve.balanceOf(address(addr1)), amount * 10 ** 18);
            assertEq(degenbondingcurve.bondingCurveCompleted(), true);
    }

    function testCompleteCurveBuyDegen() public {
        uint256 amount = 800000000;
        vm.startPrank(addr1);
            uint256 cost = degenbondingcurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            degenbondingcurve.buyTokens{value: totalCostWithSlippage}(
                amount
            );
            assertEq(degenbondingcurve.balanceOf(address(addr1)), amount * 10 ** 18);
            assertEq(degenbondingcurve.bondingCurveCompleted(), true);

            vm.expectRevert("Curve done");
            degenbondingcurve.buyTokens{value: totalCostWithSlippage}(
                    amount
                );
            vm.expectRevert("Curve done");
            degenbondingcurve.sellTokens(amount,0);
        vm.stopPrank();
    }

    function testCompleteCurveTradeDegen() public {
        uint256 amount = 800000000;
        vm.startPrank(addr1);
            uint256 cost = degenbondingcurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            degenbondingcurve.buyTokens{value: totalCostWithSlippage}(
                amount
            );
            assertEq(degenbondingcurve.balanceOf(address(addr1)), amount * 10 ** 18);
            assertEq(degenbondingcurve.bondingCurveCompleted(), true);

            address[] memory path = new address[](2);
            path[0] = address(degenbondingcurve);
            path[1] = router.WETH();

        degenbondingcurve.approve(address(router), amount * 10 ** 18);
        router.swapExactTokensForETH(
            amount * 10 ** 18,
            0,
            path,
            address(addr1),
            block.timestamp + 10 minutes
        );
            assertEq(degenbondingcurve.balanceOf(address(addr1)), 0);
        vm.stopPrank();
    }
    function testDevLockBeforeDex() public {
        assertEq(devLockDegen.balanceOf(address(addr3)), devLockAmount * 10 ** 18);
        uint256 amount = 800000000;
            vm.startPrank(addr3);
            uint256 cost = devLockDegen.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            console.log("totalCostWithSlippage", totalCostWithSlippage);
            vm.expectRevert("Dev Locked Cant Buy or Sell");
            devLockDegen.buyTokens{value: totalCostWithSlippage}(
                amount
            );
            //dev tries to sell tokens
            vm.expectRevert("Dev Locked Cant Buy or Sell");
            devLockDegen.sellTokens(devLockAmount,0);
            assertEq(devLockDegen.balanceOf(address(addr3)), devLockAmount * 10 ** 18);

            // 3 days passes
            vm.warp(block.timestamp + 3 days);

            //dev tries to sell tokens
            vm.expectRevert("Dev Locked Cant Buy or Sell");
            devLockDegen.sellTokens(devLockAmount,0);

            //dev tries to buy tokens
            vm.expectRevert("Dev Locked Cant Buy or Sell");
            devLockDegen.buyTokens{value: totalCostWithSlippage}(
                amount
            );

            // 5 days passes
            vm.warp(block.timestamp + 5 days);

            //dev tries to sell tokens
            devLockDegen.sellTokens(devLockAmount,0);
            assertEq(devLockDegen.balanceOf(address(addr3)), 0);
            //dev tries to buy tokens
            devLockDegen.buyTokens{value: totalCostWithSlippage}(
                amount
            );
            assertEq(devLockDegen.balanceOf(address(addr3)), (amount * 10 ** 18));

    }
    function testDevLockAfterDex() public {
        assertEq(devLockDegen.balanceOf(address(addr3)), devLockAmount * 10 ** 18);
        vm.startPrank(addr1);
        uint256 amount = 800000000;
        uint256 cost = devLockDegen.calculateCost(amount);
        uint256 tax = cost / 100;
        uint256 totalCost = cost + tax;
        uint256 slippage = totalCost / 100;
        uint256 totalCostWithSlippage = totalCost + slippage;
        devLockDegen.buyTokens{value: totalCostWithSlippage}(
            amount
        );
        console.log("devLockDegen.balanceOf(address(addr1))", devLockDegen.balanceOf(address(addr1)));
        assertEq(devLockDegen.bondingCurveCompleted(), true);
        vm.stopPrank();
        // dev tries to buy
        vm.startPrank(addr3);
        uint256 cost2 = devLockDegen.calculateCost(amount);
        uint256 tax2 = cost2 / 100;
        uint256 totalCost2 = cost2 + tax2;
        uint256 slippage2 = totalCost2 / 100;
        uint256 totalCostWithSlippage2 = totalCost2 + slippage2;
        vm.expectRevert("Curve done");
        devLockDegen.buyTokens{value: totalCostWithSlippage2}(
            amount
        );
        //dev tries to sell tokens
        vm.expectRevert("Curve done");
        devLockDegen.sellTokens(devLockAmount,0);
        assertEq(devLockDegen.balanceOf(address(addr3)), devLockAmount * 10 ** 18);
        //dev tries to buy in dex
        devLockDegen.approve(address(router), amount * 10 ** 18);
        address[] memory path = new address[](2);
        path[0] = address(devLockDegen);
        path[1] = router.WETH();
        vm.expectRevert();
        router.swapExactTokensForETH(
            amount * 10 ** 18,
            0,
            path,
            address(addr3),
            block.timestamp + 10 minutes
        );
        // dev tries to buy in dex
        path[0] = router.WETH();
        path[1] = address(devLockDegen);
        vm.expectRevert();
        router.swapExactETHForTokens{value: totalCostWithSlippage2}(
            0,
            path,
            address(addr3),
            block.timestamp + 10 minutes
        );

        vm.warp(block.timestamp + 3 days);

        //dev tries to sell tokens in dex

        path[0] = address(devLockDegen);
        path[1] = router.WETH();

        vm.expectRevert();
        router.swapExactTokensForETH(
            devLockAmount * 10 ** 18,
            0,
            path,
            address(addr3),
            block.timestamp + 10 minutes
        );

        //dev tries to buy tokens in dex

        path[0] = router.WETH();
        path[1] = address(devLockDegen);

        vm.expectRevert();
        router.swapExactETHForTokens{value: totalCostWithSlippage2}(
            0,
            path,
            address(addr3),
            block.timestamp + 10 minutes
        );

        // 5 days passes
        vm.warp(block.timestamp + 8 days);

        //dev tries to sell tokens in dex
        console.log("devLockDegen.balanceOf(address(addr3))", devLockDegen.balanceOf(address(addr3)));

        path[0] = address(devLockDegen);
        path[1] = router.WETH();

        router.swapExactTokensForETH(
            devLockAmount * 10 ** 18,
            0,
            path,
            address(addr3),
            block.timestamp + 10 minutes
        );

        assertEq(devLockDegen.balanceOf(address(addr3)), 0);
        //dev tries to buy tokens in dex
        path[0] = router.WETH();
        path[1] = address(devLockDegen);

        router.swapExactETHForTokens{value: totalCostWithSlippage2}(
            0,
            path,
            address(addr3),
            block.timestamp + 10 minutes
        );

        console.log("devLockDegen.balanceOf(address(addr3))", devLockDegen.balanceOf(address(addr3)));
    }

   
}