pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Factories/DegenFactory.sol";
import "../src/Factories/LockingCurveFactory.sol";
import "../src/Factories/RefundableFactory.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/Factories/SuperMemeRegistry.sol";
import "../src/SuperMemeRevenueCollector.sol";
import "../src/Factories/CommunityLockFactory.sol";
import "../src//SuperMemeCommunityLock.sol";
import "../src/SuperMemeToken/SuperMeme.sol";
import "../src/SuperMemeToken/SuperMemePublicStaking.sol";
import "../src/SuperMemeToken/SuperMemeTreasuryVesting.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";
import {IUniswapV2Router02} from "../src/Interfaces/IUniswapV2Router02.sol";

contract CommunityLock is Test {
   uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;

    uint256 public tgeDate = 1732482000;

    IUniswapV2Router02 public router;
    IUniswapFactory public uniswapFactory;
    RefundableFactory public refundableFactory;
    DegenFactory public degenFactory;
    LockingCurveFactory public lockingCurveFactory;
    SuperMemeDegenBondingCurve public degenbondingcurve;
    SuperMemeRegistry public registry;
    SuperMemeRevenueCollector public revenueCollector;
    CommunityLockFactory public communityLockFactory;

    SuperMemePublicStaking public publicStaking;
    SuperMemeTreasuryVesting public treasuryVesting;
    SuperMeme public spr;
    SuperMemeCommunityLock public communityLock;

    uint256 public createTokenRevenue = 0.0008 ether;

        address public owner = address(0x123);
        address public addr1 = address(0x456);
        address public addr2 = address(0x789);
        address public addr3 = address(0x101112);

    function setUp() public {
        vm.deal(owner, 1000 ether);
        vm.deal(addr1, 1000 ether);

        uint256 createTokenRevenue = 0.0008 ether;

        spr = new SuperMeme();
        publicStaking = new SuperMemePublicStaking(address(spr));
        treasuryVesting = new SuperMemeTreasuryVesting(address(spr), tgeDate);


        revenueCollector = new SuperMemeRevenueCollector(address(spr), address(publicStaking), address(treasuryVesting));

        registry = new SuperMemeRegistry();
        degenFactory = new DegenFactory(address(registry));
        refundableFactory = new RefundableFactory(address(registry));
        lockingCurveFactory = new LockingCurveFactory(address(registry));
        communityLockFactory = new CommunityLockFactory(address(registry));

        degenFactory.setRevenueCollector(address(revenueCollector));
        refundableFactory.setRevenueCollector(address(revenueCollector));
        lockingCurveFactory.setRevenueCollector(address(revenueCollector));
        communityLockFactory.setRevenueCollector(address(revenueCollector));

        degenFactory.setCreateTokenRevenue(createTokenRevenue);
        refundableFactory.setCreateTokenRevenue(createTokenRevenue);
        lockingCurveFactory.setCreateTokenRevenue(createTokenRevenue);
        communityLockFactory.setCreateTokenRevenue(createTokenRevenue);


        registry.setFactory(address(degenFactory));
        registry.setFactory(address(refundableFactory));
        registry.setFactory(address(lockingCurveFactory));
        registry.setFactory(address(communityLockFactory));

            

        communityLock = new SuperMemeCommunityLock(
            "SuperMeme",
            "MEME",
            address(owner),
            address(revenueCollector)
        );

        router = IUniswapV2Router02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24);
        uniswapFactory = IUniswapFactory(address(0x1));   
        
         }

    function testDeploy() public {
        assertTrue(address(communityLock) != address(0));
    }

       function testCompleteCurde() public {
        uint256 amount = 800000000;
        vm.startPrank(addr1);
            uint256 cost = communityLock.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            communityLock.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            assertEq(communityLock.balanceOf(address(addr1)), amount * 10 ** 18);
            assertEq(communityLock.bondingCurveCompleted(), true);
    }

    function testCompleteCurveBuyCurve() public {
        uint256 amount = 800000000;
        vm.startPrank(addr1);
            uint256 cost = communityLock.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            communityLock.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            assertEq(communityLock.balanceOf(address(addr1)), amount * 10 ** 18);
            assertEq(communityLock.bondingCurveCompleted(), true);
            vm.expectRevert("Curve done");
            communityLock.buyTokens{value: totalCostWithSlippage}(
                    amount,
                    100,
                    totalCost
                );
            vm.expectRevert("Curve done");
            communityLock.sellTokens(amount,0);
        vm.stopPrank();
    }

    function testCompleteCurveTradeCurve() public {
        uint256 amount = 800000000;
        vm.startPrank(addr1);
            uint256 cost = communityLock.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            communityLock.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            assertEq(communityLock.balanceOf(address(addr1)), amount * 10 ** 18);
            assertEq(communityLock.bondingCurveCompleted(), true);

            address[] memory path = new address[](2);
            path[0] = address(communityLock);
            path[1] = router.WETH();

        communityLock.approve(address(router), amount * 10 ** 18);
        router.swapExactTokensForETH(
            amount * 10 ** 18,
            0,
            path,
            address(addr1),
            block.timestamp + 10 minutes
        );
        assertEq(communityLock.balanceOf(address(addr1)), 0);
        vm.stopPrank();
    }

}