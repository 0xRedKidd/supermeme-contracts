pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Factories/DegenFactory.sol";
import "../src/Factories/LockingCurveFactory.sol";
import "../src/Factories/RefundableFactory.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/Factories/SuperMemeRegistry.sol";
import "../src/SuperMemeRevenueCollector.sol";
import "../src/Factories/CommunityLockFactory.sol";
import "../src/SuperMemeToken/SuperMemePublicStaking.sol";
import "../src/SuperMemeToken/SuperMemeTreasuryVesting.sol";
import "../src/SuperMemeToken/SuperMeme.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";

contract TestFactories is Test {
    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;

    uint256 public tgeDate = 1732482000;

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

    function testDeployNoDevLockNoDevBuy() public {
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
    }

    function testDeployNoDevLockYesBuy() public {
        vm.startPrank(addr1);
        uint256[] memory buyAmounts = new uint256[](8);
        buyAmounts[0] = 500;
        buyAmounts[1] = 2000000;
        buyAmounts[2] = 7500000;
        buyAmounts[3] = 15000000;
        buyAmounts[4] = 25000000;
        buyAmounts[5] = 35000000;
        buyAmounts[6] = 45000000;
        buyAmounts[7] = 110000000;
        for (uint256 i = 0; i < buyAmounts.length; i++) {
            uint256 buyAmount = buyAmounts[i];
            uint256 cost = degenbondingcurve.calculateCost(buyAmount);
            uint256 tax = cost / 100;
            uint256 costWithTax = cost + tax;
            uint256 slippage = cost / 100;
            uint256 buyEth = costWithTax + slippage;
            address newToken = degenFactory.createToken{
                value: createTokenRevenue + buyEth
            }("SuperMeme", "MEME", false, buyAmount, address(addr1), 0, buyEth);
            SuperMemeDegenBondingCurve newTokenInstance = SuperMemeDegenBondingCurve(
                    newToken
                );
            assertEq(newTokenInstance.balanceOf(addr1), buyAmount * 10 ** 18);
        }
    }

        function testDeployYesDevLockYesBuy() public {
        vm.startPrank(addr1);
        uint256[] memory buyAmounts = new uint256[](8);
        buyAmounts[0] = 500;
        buyAmounts[1] = 2000000;
        buyAmounts[2] = 7500000;
        buyAmounts[3] = 15000000;
        buyAmounts[4] = 25000000;
        buyAmounts[5] = 35000000;
        buyAmounts[6] = 45000000;
        buyAmounts[7] = 110000000;
        for (uint256 i = 0; i < buyAmounts.length; i++) {
            uint256 buyAmount = buyAmounts[i];
            uint256 cost = degenbondingcurve.calculateCost(buyAmount);
            uint256 tax = cost / 100;
            uint256 costWithTax = cost + tax;
            uint256 slippage = cost / 100;
            uint256 buyEth = costWithTax + slippage;
            address newToken = degenFactory.createToken{
                value: createTokenRevenue + buyEth
            }(
                "SuperMeme",
                "MEME",
                true,
                buyAmount,
                address(addr1),
                1 weeks,
                buyEth
            );
            SuperMemeDegenBondingCurve newTokenInstance = SuperMemeDegenBondingCurve(
                    newToken
                );
            assertEq(newTokenInstance.balanceOf(addr1), buyAmount * 10 ** 18);
        }
    }

    function testRefundableNoDevBuy() public {
        vm.startPrank(addr1);
        uint256 buyAmount = 0;
        uint256 cost = degenbondingcurve.calculateCost(buyAmount);
        uint256 tax = cost / 100;
        uint256 costWithTax = cost + tax;
        uint256 slippage = cost / 100;
        uint256 buyEth = costWithTax + slippage;
        address newToken = refundableFactory.createToken{value: createTokenRevenue}(
            "SuperMeme",
            "MEME",
            0,
            address(addr1),
            0
        );
        SuperMemeRefundableBondingCurve newTokenInstance = SuperMemeRefundableBondingCurve(
                newToken
            );
        assertEq(newTokenInstance.balanceOf(addr1), buyAmount * 10 ** 18);
    }
    function testRefundableYesDevBuy() public {
        vm.startPrank(addr1);
        uint256[] memory buyAmounts = new uint256[](8);
        buyAmounts[0] = 500;
        buyAmounts[1] = 2000000;
        buyAmounts[2] = 7500000;
        buyAmounts[3] = 15000000;
        buyAmounts[4] = 25000000;
        buyAmounts[5] = 35000000;
        buyAmounts[6] = 45000000;
        buyAmounts[7] = 110000000;
        for (uint256 i = 0; i < buyAmounts.length; i++) {
            
            uint256 buyAmount = buyAmounts[i];
            uint256 cost = degenbondingcurve.calculateCost(buyAmount);
            uint256 tax = cost / 100;
            uint256 costWithTax = cost + tax;
            uint256 slippage = cost / 100;
            uint256 buyEth = costWithTax + slippage;
            address newToken = refundableFactory.createToken{
                value: createTokenRevenue + buyEth
            }(
                "SuperMeme",
                "MEME",
                buyAmount,
                address(addr1),
                buyEth
            );
            SuperMemeRefundableBondingCurve newTokenInstance = SuperMemeRefundableBondingCurve(
                    newToken
                );
            assertEq(newTokenInstance.balanceOf(addr1), buyAmount * 10 ** 18);
        }
    }

    function testCommunityLockNoDevBuy() public {
        vm.startPrank(addr1);
        uint256 buyAmount = 0;
        uint256 cost = degenbondingcurve.calculateCost(buyAmount);
        uint256 tax = cost / 100;
        uint256 costWithTax = cost + tax;
        uint256 slippage = cost / 100;
        uint256 buyEth = costWithTax + slippage;
        address newToken = communityLockFactory.createToken{value: createTokenRevenue}(
            "SuperMeme",
            "MEME",
            address(addr1)
        );
        SuperMemeCommunityLock newTokenInstance = SuperMemeCommunityLock(
                newToken
            );
        assertEq(newTokenInstance.balanceOf(addr1), buyAmount * 10 ** 18);
    }
}
