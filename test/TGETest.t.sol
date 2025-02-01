pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Factories/DegenFactory.sol";
import "../src/Factories/LockingCurveFactory.sol";
import "../src/Factories/RefundableFactory.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/Factories/SuperMemeRegistry.sol";
import "../src/SuperMemeRevenueCollector.sol";
import "../src/Factories/CommunityLockFactory.sol";
import "../src/SuperMemeToken/SuperMeme.sol";
import "../src/SuperMemeToken/SuperMemePublicStaking.sol";
import "../src/SuperMemeToken/SuperMemeTreasuryVesting.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";

contract TGETest is Test {
    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;

    uint256 public tgeDate = 1734451200;

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

    SuperMemeDegenBondingCurve public degenbondingcurve2;
    SuperMemeRefundableBondingCurve public refundableBondingCurve;
    SuperMemeLockingCurve public lockingCurve;


    uint256 public createTokenRevenue = 0.0008 ether;

   address public constant SEED = 0x6F69C5363dd8c21256d40d47caBFf5242AD14e3E;
    uint256 public constant SEED_AMOUNT = 113_333_333 ether;

    address public constant PUBLIC = 0x69e63Ed9105463183625981C926e8282b6Eb0db4;
    uint256 public constant PUBLIC_AMOUNT = 126_666_667 ether;

    address public constant TEAM = 0xFFFf2A9e9A7E8B738e3a18538CFFbc101A397419;
    uint256 public constant TEAM_AMOUNT = 150_000_000 ether;

    address public constant TREASURY =
        0xA902fFcC625D8DcAcaf08d00F96B32c5d6A6ebe7;
    uint256 public constant TREASURY_AMOUNT = 200_000_000 ether;

    address public constant DEVELOPMENT =
        0xdCb265A5Ce660611Bc1DA882d8A42733d88C1323;
    uint256 public constant DEVELOPMENT_AMOUNT = 80_000_000 ether;

    address public constant MARKETING =
        0xbd7784D02c6590e68fEd3098E354e7cbD232adC4;
    uint256 public constant MARKETING_AMOUNT = 90_000_000 ether;

    address public constant LIQUIDITY =
        0x6F72B3530271bE8ae09CeE65d05836E9720Df880;
    uint256 public constant LIQUIDITY_AMOUNT = 180_000_000 ether;

    address public constant AIRDROP =
        0x538c08af3e3cD67eeb4FB45970D3520F58537Ba4;
    uint256 public constant AIRDROP_AMOUNT = 30_000_000 ether;

    address public constant ADVISOR =
        0x84dC3E5eC35A358742bf6fb2461104856439EA6C;
    uint256 public constant ADVISOR_AMOUNT = 30_000_000 ether;


    address public owner = address(0x123);
    address public addr1 = address(0x456);
    address public addr2 = address(0x789);
    address public addr3 = address(0x101112);
    address public addr4 = address(0x131415);

    uint256 public constant FIFTEEN_DAYS = 15 days;
    uint256 public constant ONE_MONTH = 30 days;
    uint256 public constant THREE_MONTHS = 90 days;
    uint256 public constant SIX_MONTHS = 180 days;

    uint256 public constant FIFTEEN_DAYS_BONUS = 1;
    uint256 public constant ONE_MONTH_BONUS = 2;
    uint256 public constant THREE_MONTHS_BONUS = 4;
    uint256 public constant SIX_MONTHS_BONUS = 8;


    uint256 createTokenRevenueAfterJackpot;



    function setUp() public {
        vm.deal(owner, 1000 ether);

        vm.deal(addr1, 1000 ether);
        vm.deal(addr2, 1000 ether);
        vm.deal(addr3, 1000 ether);
        vm.deal(SEED, 1000 ether);

        vm.deal(PUBLIC, 1000 ether);
        vm.deal(TEAM, 1000 ether);
        vm.deal(TREASURY, 1000 ether);
        vm.deal(DEVELOPMENT, 1000 ether);
        vm.deal(MARKETING, 1000 ether);
        vm.deal(LIQUIDITY, 1000 ether);
        vm.deal(AIRDROP, 1000 ether);
        vm.deal(ADVISOR, 1000 ether);

        uint256 createTokenRevenue = 0.0008 ether;

        vm.startPrank(owner);
        

        spr = new SuperMeme();

        //imitate the minted tokens addresses so we can use them to call transfer tokens
        publicStaking = new SuperMemePublicStaking(address(spr));
        treasuryVesting = new SuperMemeTreasuryVesting(address(spr), tgeDate);

        revenueCollector = new SuperMemeRevenueCollector(
            address(spr),
            address(publicStaking),
            address(treasuryVesting)
        );

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
        vm.stopPrank();

        vm.startPrank(addr1);

        address DegenToken = degenFactory.createToken{
            value: createTokenRevenue
        }("SuperMeme", "MEME", false, 0, address(addr1), 0, 0);
        assertEq(degenFactory.tokenAddresses(0), DegenToken);
        degenbondingcurve2 = SuperMemeDegenBondingCurve(DegenToken);

        address RefundableToken = refundableFactory.createToken{
            value: createTokenRevenue
        }("SuperMeme2", "MEM", 0, address(addr1), 0);

        assertEq(refundableFactory.tokenAddresses(0), RefundableToken);
        refundableBondingCurve = SuperMemeRefundableBondingCurve(
            RefundableToken
        );

        address LockingToken = lockingCurveFactory.createToken{
            value: createTokenRevenue
        }("SuperMeme3", "MEM", 0, address(addr1), 0, 1 days);
        lockingCurve = SuperMemeLockingCurve(LockingToken);


        createTokenRevenueAfterJackpot = (createTokenRevenue * 3) * 99 / 100;
        console.log("timestamp before warp", block.timestamp);
        vm.warp(tgeDate);
        console.log("timestamp after warp", block.timestamp);
    }
    function testDeploy() public {
        assertEq(degenFactory.revenueCollector(), (address(revenueCollector)));
        assertEq(
            refundableFactory.revenueCollector(),
            (address(revenueCollector))
        );
        assertEq(
            lockingCurveFactory.revenueCollector(),
            (address(revenueCollector))
        );
        assertEq(degenbondingcurve2.devAddress(), address(addr1));
        assertEq(refundableBondingCurve.devAddress(), address(addr1));
        assertEq(lockingCurve.devAddress(), address(addr1));
        console.log("total expected revenue", createTokenRevenue * 3);
        console.log(
            "revenue collector balance",
            address(revenueCollector).balance
        );
        console.log(revenueCollector.totalEtherCollected());
        
    }

    function testForTreasuryStaking() public {
        vm.startPrank(TREASURY);
        spr.approve(address(treasuryVesting), TREASURY_AMOUNT);
        treasuryVesting.stake(TREASURY_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TREASURY)), TREASURY_AMOUNT);
        vm.stopPrank();

        vm.startPrank(TEAM);
        spr.approve(address(treasuryVesting), TEAM_AMOUNT);
        treasuryVesting.stake(TEAM_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TEAM)), TEAM_AMOUNT);

        revenueCollector.distributeRevenue();
        assertEq(revenueCollector.totalEtherCollected(), 0);
        assertEq(treasuryVesting.allTimeRevenueCollected(), (createTokenRevenue * 3) * 99 / 100);
        vm.stopPrank();

    }

    function testForTreasuryUnStaking() public {
        vm.startPrank(TREASURY);
        console.log("before staking", spr.balanceOf(address(TREASURY)));
        spr.approve(address(treasuryVesting), TREASURY_AMOUNT);
        treasuryVesting.stake(TREASURY_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TREASURY)), TREASURY_AMOUNT);
        vm.stopPrank();
        console.log("after staking treasury");
        vm.startPrank(TEAM);
        spr.approve(address(treasuryVesting), TEAM_AMOUNT);
        treasuryVesting.stake(TEAM_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TEAM)), TEAM_AMOUNT);
        
        console.log("after staking team");

        

        revenueCollector.distributeRevenue();
        assertEq(revenueCollector.totalEtherCollected(), 0);
        assertEq(treasuryVesting.allTimeRevenueCollected(), createTokenRevenueAfterJackpot);
        vm.stopPrank();

        console.log("after revenue distribution");

        vm.startPrank(TREASURY);
        vm.expectRevert("Cliff period not reached");
        treasuryVesting.unstake();
        vm.stopPrank();

        vm.startPrank(TEAM);
        vm.expectRevert("Cliff period not reached");
        treasuryVesting.unstake();
        vm.stopPrank();

        vm.warp(block.timestamp + 730 days);
        console.log("block timestamp warpppppppp", block.timestamp);
        vm.startPrank(TREASURY);
        console.log("before unstake sadfasfasd", spr.balanceOf(address(TREASURY)));
        treasuryVesting.unstake();
        console.log("after unstake aaaaaaaaaaaaaa", spr.balanceOf(address(TREASURY)));
        assertEq(spr.balanceOf(address(TREASURY)), TREASURY_AMOUNT/2);
    }


    function testForTreasuryStakingRewards() public {
        vm.startPrank(TREASURY);
        console.log("before staking", spr.balanceOf(address(TREASURY)));
        spr.approve(address(treasuryVesting), TREASURY_AMOUNT);
        treasuryVesting.stake(TREASURY_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TREASURY)), TREASURY_AMOUNT);
        vm.stopPrank();

        vm.startPrank(TEAM);
        spr.approve(address(treasuryVesting), TEAM_AMOUNT);
        treasuryVesting.stake(TEAM_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TEAM)), TEAM_AMOUNT);

        vm.startPrank(addr1);

        revenueCollector.distributeRevenue();
        vm.stopPrank();

        vm.startPrank(TREASURY);
        uint256 ethBalanceofTreasuryBeforeClaim = address(TREASURY).balance;
        treasuryVesting.claim();
        uint256 ethBalanceofTreasuryAfterClaim = address(TREASURY).balance;
        uint256 expectedTreasuryRewards = createTokenRevenueAfterJackpot * 200_000_000 ether / 350_000_000 ether;
        uint256 receivedTreasuryRewards = ethBalanceofTreasuryAfterClaim - ethBalanceofTreasuryBeforeClaim;
        assertApproxEqAbs(receivedTreasuryRewards, expectedTreasuryRewards, 0.000001 ether);
        assertApproxEqAbs(address(treasuryVesting).balance, createTokenRevenueAfterJackpot * 150_000_000 ether / 350_000_000 ether,0.000001 ether);

        vm.startPrank(addr1);
        uint256 hundredether = 100 ether;
        payable(revenueCollector).call{value: hundredether, gas: 3000000}("");
        uint256 collectedRevenueAfterJackpot = 99 ether;
        revenueCollector.distributeRevenue();
        vm.stopPrank();


        vm.startPrank(TREASURY);

        vm.expectRevert("Cliff period not reached");
        treasuryVesting.unstake();
        console.log("vesting reward balance", address(treasuryVesting).balance);
        console.log("block timestamp", block.timestamp);
        vm.warp(block.timestamp + 730 days);
        ethBalanceofTreasuryBeforeClaim = address(TREASURY).balance;
        treasuryVesting.unstake();
        ethBalanceofTreasuryAfterClaim = address(TREASURY).balance;
        uint256 teamRewards = treasuryVesting.calculateRewardsEarned(TEAM);
        expectedTreasuryRewards = (collectedRevenueAfterJackpot  * 200_000_000 / 350_000_000);
        receivedTreasuryRewards = ethBalanceofTreasuryAfterClaim - ethBalanceofTreasuryBeforeClaim;
        assertApproxEqAbs(receivedTreasuryRewards, expectedTreasuryRewards, 0.0001 ether);
        assertEq(spr.balanceOf(address(TREASURY)), TREASURY_AMOUNT/2);
        assertEq(spr.balanceOf(address(treasuryVesting)), TREASURY_AMOUNT/2 + TEAM_AMOUNT);
        vm.stopPrank();

        vm.startPrank(addr1);
        payable(revenueCollector).call{value: hundredether, gas: 3000000}("");
        collectedRevenueAfterJackpot += 99 ether;
        revenueCollector.distributeRevenue();
        vm.stopPrank();

        vm.warp(block.timestamp + 150 days);

        vm.startPrank(TREASURY);
        ethBalanceofTreasuryBeforeClaim = address(TREASURY).balance;
        treasuryVesting.claim();
        ethBalanceofTreasuryAfterClaim = address(TREASURY).balance;
        uint256 sprBalanceOfTreasuryInVesting = spr.balanceOf(address(TREASURY));
        expectedTreasuryRewards = collectedRevenueAfterJackpot * 200_000_000 / 350_000_000;
        assertApproxEqAbs(sprBalanceOfTreasuryInVesting, treasuryVesting.balance(address(TREASURY)), 0.0001 ether);


        uint256 unstakableAmount = treasuryVesting.getUnlockedAmount(address(TREASURY));
        assertEq(unstakableAmount, TREASURY_AMOUNT * (150 + 365) / 730 - treasuryVesting.totalUnlockedAndClaimed(address(TREASURY)));
        treasuryVesting.unstake();


    }

    function testForAdvisorStaking() public {
        vm.startPrank(ADVISOR);

        //create two advisor accounts and _cliffDurations of 3 monthes and _vestingDurations of 6 monthes amounts of 30_000_000 ether
        address advisor1 = address(0x123456321);
        address advisor2 = address(0x654321123);
        uint256 _cliffDuration = THREE_MONTHS;
        uint256 _vestingDuration = SIX_MONTHS;
        console.log("three months", THREE_MONTHS);
        console.log("six months", SIX_MONTHS);
        uint256 amount = 10_000_000 ether;

        console.log("before approving");

        spr.approve(address(treasuryVesting), amount * 2);
        treasuryVesting.addAdvisor(advisor1, amount, _cliffDuration, _vestingDuration);  
        treasuryVesting.addAdvisor(advisor2, amount, _cliffDuration, _vestingDuration);
        uint256 totalExpectedStakedTillNow = amount * 2;

        console.log("after approving");

        assertEq(spr.balanceOf(address(treasuryVesting)), amount * 2);
        assertEq(treasuryVesting.totalSupply(), amount * 2);
        assertEq(treasuryVesting.balance(advisor1), amount);
        assertEq(treasuryVesting.balance(advisor2), amount);

        vm.stopPrank();

        console.log("before treasury staking");

        //TREASURY STAKES
        vm.startPrank(TREASURY);
        spr.approve(address(treasuryVesting), TREASURY_AMOUNT);
        treasuryVesting.stake(TREASURY_AMOUNT);
        totalExpectedStakedTillNow += TREASURY_AMOUNT;
        assertEq(spr.balanceOf(address(treasuryVesting)), totalExpectedStakedTillNow);
        assertEq(treasuryVesting.totalSupply(), totalExpectedStakedTillNow);
        assertEq(treasuryVesting.balance(address(TREASURY)), TREASURY_AMOUNT);
        vm.stopPrank();

        //TEAM STAKES
        vm.startPrank(TEAM);
        spr.approve(address(treasuryVesting), TEAM_AMOUNT);
        treasuryVesting.stake(TEAM_AMOUNT);
        totalExpectedStakedTillNow += TEAM_AMOUNT;
        assertEq(spr.balanceOf(address(treasuryVesting)), totalExpectedStakedTillNow);
        assertEq(treasuryVesting.totalSupply(), totalExpectedStakedTillNow);
        assertEq(treasuryVesting.balance(address(TEAM)), TEAM_AMOUNT);
        vm.stopPrank();

        //send revenue to revenue collector
        console.log("before sending first 100 ether");

        vm.startPrank(addr1);
        payable(revenueCollector).call{value: 100 ether, gas: 3000000}("");
        assertGt(revenueCollector.totalEtherCollected(), 99 ether);
        uint256 revToBeDistributed = revenueCollector.totalEtherCollected();
        uint256 publicStakingShare = spr.balanceOf(address(publicStaking));
        uint256 treasuryVestingShare = spr.balanceOf(address(treasuryVesting));
        uint256 totalShare = publicStakingShare + treasuryVestingShare;

        revenueCollector.distributeRevenue();
        vm.stopPrank();

        console.log("after sending first 100 ether");
        assertEq(address(treasuryVesting).balance, revToBeDistributed * treasuryVestingShare / totalShare);
        console.log("before warp", block.timestamp);
        vm.warp(block.timestamp + 730 days);
        console.log("after warp", block.timestamp);

        //advisors unstake
        vm.startPrank(advisor1);
        uint256 advisor1BalanceBeforeUnstake = address(advisor1).balance;
        treasuryVesting.unstake();
        assertEq(spr.balanceOf(advisor1), amount);
       
        uint256 advisor1BalanceAfterUnstake = address(advisor1).balance;
        uint256 expectedRewards = revToBeDistributed * amount / totalExpectedStakedTillNow;
        assertEq(spr.balanceOf(advisor1), amount);
        console.log("advisor1 rewards", treasuryVesting.calculateRewardsEarned(advisor1));
        assertApproxEqAbs(advisor1BalanceAfterUnstake, advisor1BalanceBeforeUnstake + expectedRewards, 0.0001 ether);
        totalExpectedStakedTillNow -= amount;
        vm.stopPrank();

        uint256 advisor2Rewards1 = treasuryVesting.calculateRewardsEarned(advisor2);
        console.log("advisor2 rewards for first 100 ether", advisor2Rewards1);

        //send 100 more ether to revenue collector
        vm.startPrank(addr1);
        payable(revenueCollector).call{value: 100 ether, gas: 3000000}("");
        revToBeDistributed = revenueCollector.totalEtherCollected();
        console.log("revenue to be distributed", revToBeDistributed);
        revenueCollector.distributeRevenue();
        vm.stopPrank();

        uint256 advisor2Rewards2 = treasuryVesting.calculateRewardsEarned(advisor2);
        console.log("advisor2 rewards for second 100 ether", advisor2Rewards2);

        //advisor2 unstake
        vm.startPrank(advisor2);
        uint256 advisor2BalanceBeforeUnstake = address(advisor2).balance;
        treasuryVesting.unstake();
        uint256 advisor2BalanceAfterUnstake = address(advisor2).balance;
        expectedRewards = revToBeDistributed * amount / totalExpectedStakedTillNow;
        uint256 advisor2ClaimedReward = advisor2BalanceAfterUnstake - advisor2BalanceBeforeUnstake;
        assertEq(spr.balanceOf(advisor2), amount);
        assertApproxEqAbs(advisor2ClaimedReward, advisor2Rewards1 + expectedRewards, 0.0001 ether);
        vm.stopPrank();

        //treasury claims
        vm.startPrank(TREASURY);
        uint256 treasuryBalanceBeforeClaim = address(TREASURY).balance;
        treasuryVesting.claim();
        uint256 treasuryBalanceAfterClaim = address(TREASURY).balance;
        uint256 expectedRewardsFor100Ether = 99 ether * TREASURY_AMOUNT / 370_000_000 ether;
        uint256 expectedRewardsFor200Ether = 99 ether * TREASURY_AMOUNT / 360_000_000 ether;
        console.log("expected rewards for 100 ether", expectedRewardsFor100Ether);
        assertApproxEqAbs(treasuryBalanceAfterClaim - treasuryBalanceBeforeClaim, expectedRewardsFor100Ether + expectedRewardsFor200Ether, createTokenRevenueAfterJackpot);
        vm.stopPrank();

        //team unstakes
        vm.startPrank(TEAM);
        uint256 teamBalanceBeforeUnstake = address(TEAM).balance;
        treasuryVesting.unstake();
        uint256 teamBalanceAfterUnstake = address(TEAM).balance;
        expectedRewardsFor100Ether = revToBeDistributed * TEAM_AMOUNT / 370_000_000 ether;
        expectedRewardsFor200Ether = revToBeDistributed * TEAM_AMOUNT / 360_000_000 ether;
        assertApproxEqAbs(teamBalanceAfterUnstake - teamBalanceBeforeUnstake, expectedRewardsFor100Ether + expectedRewardsFor200Ether, createTokenRevenueAfterJackpot);
        assertEq(spr.balanceOf(address(TEAM)), TEAM_AMOUNT / 2);
        vm.stopPrank();


        //send 100 more ether to revenue collector
        vm.startPrank(addr1);
        payable(revenueCollector).call{value: 100 ether, gas: 3000000}("");
        revToBeDistributed = revenueCollector.totalEtherCollected();
        console.log("revenue to be distributed", revToBeDistributed);
        revenueCollector.distributeRevenue();
        vm.stopPrank();

        //treasury claims
        vm.startPrank(TREASURY);
        treasuryBalanceBeforeClaim = address(TREASURY).balance;
        treasuryVesting.claim();
        treasuryBalanceAfterClaim = address(TREASURY).balance;
        expectedRewardsFor100Ether = 99 ether * TREASURY_AMOUNT / 275_000_000 ether;
        assertApproxEqAbs(treasuryBalanceAfterClaim - treasuryBalanceBeforeClaim, expectedRewardsFor100Ether, createTokenRevenueAfterJackpot);
        vm.stopPrank();

        //trasury unstakes
        vm.startPrank(TREASURY);
        uint256 treasuryBalanceBeforeUnstake = address(TREASURY).balance;
        treasuryVesting.unstake();
        uint256 treasuryBalanceAfterUnstake = address(TREASURY).balance;
        expectedRewardsFor100Ether = 0;
        assertApproxEqAbs(treasuryBalanceAfterUnstake - treasuryBalanceBeforeUnstake, expectedRewardsFor100Ether, createTokenRevenueAfterJackpot);
        assertEq(spr.balanceOf(address(TREASURY)), TREASURY_AMOUNT / 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 730 days);
        console.log("block timestamp after second warp", block.timestamp);
        console.log("before team unstake");
        //team unstakes all
        vm.startPrank(TEAM);
        teamBalanceBeforeUnstake = address(TEAM).balance;
        treasuryVesting.unstake();
        teamBalanceAfterUnstake = address(TEAM).balance;
        expectedRewardsFor100Ether = 99 ether * TEAM_AMOUNT / 2 / 275_000_000 ether;
        assertApproxEqAbs(teamBalanceAfterUnstake - teamBalanceBeforeUnstake, expectedRewardsFor100Ether, createTokenRevenueAfterJackpot);
        assertEq(spr.balanceOf(address(TEAM)), TEAM_AMOUNT);
        vm.stopPrank();
        console.log("before treasury unstake");
        //treasury unstakes all
        vm.startPrank(TREASURY);
        treasuryBalanceBeforeUnstake = address(TREASURY).balance;
        treasuryVesting.unstake();
        treasuryBalanceAfterUnstake = address(TREASURY).balance;
        expectedRewardsFor100Ether = 0;
        assertApproxEqAbs(treasuryBalanceAfterUnstake - treasuryBalanceBeforeUnstake, expectedRewardsFor100Ether, createTokenRevenueAfterJackpot);
        assertEq(spr.balanceOf(address(TREASURY)), TREASURY_AMOUNT);
        vm.stopPrank();

    }

}
