pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Factories/DegenFactory.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/SuperMemeRefundableBondingCurve.sol";
import "../src/SuperMemeRevenueCollector.sol";
import "../src/Factories/SuperMemeRegistry.sol";
import "../src/Factories/RefundableFactory.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";
import {IUniswapV2Router02} from "../src/Interfaces/IUniswapV2Router02.sol";



contract RefundableBondingCurveTest is Test {
    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;

    DegenFactory public degenFactory;
    SuperMemeDegenBondingCurve public degenbondingcurve;
    SuperMemeRegistry public registry;
    SuperMemeRevenueCollector public revenueCollector;
    IUniswapV2Router02 public router;
    SuperMemeRefundableBondingCurve public refundableBondingCurve;
    RefundableFactory public refundableFactory;


    address public owner = address(0x123);
    address public addr1 = address(0x456);
    address public addr2 = address(0x789);
    address public addr3 = address(0x101112);

    address public ercan = address(0x12456);
    address public ruski = address(0x78910);
    address public sinan = address(0x10111213);
    address public mert = address(0x14151617);
    address public yigit = address(0x18192021);
    address public yusuf = address(0x22232425);
    address public ahmet = address(0x26272829);
    address public mehmet = address(0x30313233);

    uint256 public createTokenRevenue = 0.0008 ether;


    function setUp() public {
        vm.deal(owner, 1000 ether);
        vm.deal(addr1, 1000 ether);
        vm.deal(addr2, 1000 ether);
        vm.deal(addr3, 1000 ether);
        vm.deal(ercan, 1000 ether);
        vm.deal(ruski, 1000 ether);


            //base mainnet router address 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        //base sepolia router address 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        router = IUniswapV2Router02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24);

        vm.startPrank(owner);
        registry = new SuperMemeRegistry();
        degenFactory = new DegenFactory(address(registry));
        refundableFactory = new RefundableFactory(address(registry));

        registry.setFactory(address(degenFactory));
        registry.setFactory(address(refundableFactory));
        

        degenbondingcurve = SuperMemeDegenBondingCurve(degenFactory.createToken{value: createTokenRevenue}("name", "symbol", false,0, owner, 0, 0));
        refundableBondingCurve = SuperMemeRefundableBondingCurve(refundableFactory.createToken{value: createTokenRevenue}("name", "symbol", 0, owner, 0));
        vm.stopPrank();
    }

    function test_createToken() public {
        assertEq(refundableBondingCurve.scaledSupply(),200000000);   
    }
    function testCompleteCurveRefundable() public {
        uint256 amount = 800000000;
        vm.startPrank(addr1);
            uint256 cost = refundableBondingCurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            refundableBondingCurve.buyTokens{value: totalCostWithSlippage}(
                amount
            );
            assertEq(refundableBondingCurve.balanceOf(address(addr1)), amount * 10 ** 18);
            assertEq(refundableBondingCurve.bondingCurveCompleted(), true);
    }

    function testCompleteCurveBuyRefundable() public {
        uint256 amount = 800000000;
        vm.startPrank(addr1);
            uint256 cost = refundableBondingCurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            refundableBondingCurve.buyTokens{value: totalCostWithSlippage}(
                amount
            );
            assertEq(refundableBondingCurve.balanceOf(address(addr1)), amount * 10 ** 18);
            assertEq(refundableBondingCurve.bondingCurveCompleted(), true);

            vm.expectRevert("Curve done");
            refundableBondingCurve.buyTokens{value: totalCostWithSlippage}(
                    amount
                );
            vm.expectRevert("Curve done");
            refundableBondingCurve.refund();
        vm.stopPrank();
    }

    function testCompleteCurveTradeRefundable() public {
        uint256 amount = 800000000;
        vm.startPrank(addr1);
            uint256 cost = refundableBondingCurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            refundableBondingCurve.buyTokens{value: totalCostWithSlippage}(
                amount
            );
            assertEq(refundableBondingCurve.balanceOf(address(addr1)), amount * 10 ** 18);
            assertEq(refundableBondingCurve.bondingCurveCompleted(), true);

            address[] memory path = new address[](2);
            path[0] = address(refundableBondingCurve);
            path[1] = router.WETH();

        refundableBondingCurve.approve(address(router), amount * 10 ** 18);
        router.swapExactTokensForETH(
            amount * 10 ** 18,
            0,
            path,
            address(addr1),
            block.timestamp + 10 minutes
        );
            assertEq(refundableBondingCurve.balanceOf(address(addr1)), 0);
        vm.stopPrank();
    }

    function testDzhonCase() public {
        vm.startPrank(addr1);
        uint256 amount = 80000000;
        uint256 cost = refundableBondingCurve.calculateCost(amount);
        uint256 tax = cost / 100;
        uint256 totalCost = cost + tax;
        refundableBondingCurve.buyTokens{value: totalCost}(
            amount
        );
        assertEq(refundableBondingCurve.balanceOf(address(addr1)), amount * 10 ** 18);

        //Same address buyt again
        uint256 amount2 = 80000000;
        uint256 cost2 = refundableBondingCurve.calculateCost(amount2);
        uint256 tax2 = cost2 / 100;
        uint256 totalCost2 = cost2 + tax2;
        refundableBondingCurve.buyTokens{value: totalCost2}(
            amount2
        );
        assertEq(refundableBondingCurve.balanceOf(address(addr1)), (amount + amount2) * 10 ** 18);

        //same address refunds
        refundableBondingCurve.refund();
        assertEq(refundableBondingCurve.balanceOf(address(addr1)), 0);
        vm.stopPrank();

        //different address buy
        vm.startPrank(addr2);
        uint256 amount3 = 80000000;
        uint256 cost3 = refundableBondingCurve.calculateCost(amount3);
        uint256 tax3 = cost3 / 100;
        uint256 totalCost3 = cost3 + tax3;
        refundableBondingCurve.buyTokens{value: totalCost3}(
            amount3
        );
        assertEq(refundableBondingCurve.balanceOf(address(addr2)), amount3 * 10 ** 18);
        vm.stopPrank();
        //different address buys
        vm.startPrank(addr3);
        uint256 amount4 = 80000000;
        uint256 cost4 = refundableBondingCurve.calculateCost(amount4);
        uint256 tax4 = cost4 / 100;
        uint256 totalCost4 = cost4 + tax4;
        refundableBondingCurve.buyTokens{value: totalCost4}(
            amount4
        );
        assertEq(refundableBondingCurve.balanceOf(address(addr3)), amount4 * 10 ** 18);
        vm.stopPrank();


        //ruski buys 2 times
        console.log("ruski buys");
        vm.startPrank(ruski);
        uint256 amount5 = 80000000;
        uint256 cost5 = refundableBondingCurve.calculateCost(amount5);
        uint256 tax5 = cost5 / 100;
        uint256 totalCost5 = cost5 + tax5;
        refundableBondingCurve.buyTokens{value: totalCost5}(
            amount5
        );
        assertEq(refundableBondingCurve.balanceOf(address(ruski)), amount5 * 10 ** 18);
        console.log("ruski buys 2nd time");
        uint256 amount6  = 80000000;
        uint256 cost6 = refundableBondingCurve.calculateCost(amount6);
        uint256 tax6 = cost6 / 100;
        uint256 totalCost6 = cost6 + tax6;
        refundableBondingCurve.buyTokens{value: totalCost6}(
            amount6
        );
        assertEq(refundableBondingCurve.balanceOf(address(ruski)), (amount5 + amount6) * 10 ** 18);
        vm.stopPrank();


        //ercan buys
        vm.startPrank(ercan);
        uint256 amount7 = 80000000;
        uint256 cost7 = refundableBondingCurve.calculateCost(amount7);
        uint256 tax7 = cost7 / 100;
        uint256 totalCost7 = cost7 + tax7;
        refundableBondingCurve.buyTokens{value: totalCost7}(
            amount7
        );
        assertEq(refundableBondingCurve.balanceOf(address(ercan)), amount7 * 10 ** 18);
        vm.stopPrank();
    
        //ruski refunds
        vm.startPrank(ruski);
        refundableBondingCurve.refund();
        assertEq(refundableBondingCurve.balanceOf(address(ruski)), 0);

    }
}