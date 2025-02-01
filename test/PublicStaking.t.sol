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

contract PublicStaking is Test {
    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;

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


    // address public constant TEAM = 0xEcd2369e23Fb21458aa41f7fb1cB1013913D97EA;
    // address public constant TREASURY = 0xc674f8D0bBC54f8eB7e7c32d6b6E11dC07f01Af5;
    // address public constant DEVELOPMENT = 0x86F13a708347611346B37457D3A5666e33630dA6;
    // address public constant MARKETING = 0x8614a5372E87511a93568d756469CCc06c5a3393;
    // address public constant LIQUIDITY = 0x4049C6d09D7c1C93D70181650279100E4D018D3D;
    // address public constant AIRDROP = 0x137d220Fb68F637e98773E39aB74E466C773AC20;
    // address public constant ADVISOR = 0xb1683022cDE0d8d69b4c458F52610f6Fd4e83D66;


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
    uint256 public tgeDate = 1732482000;


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

    uint256 public createTokenRevenueAfterJackpot;


    function setUp() public {

        vm.startPrank(owner);

        vm.deal(owner, 1000 ether);

        vm.deal(addr1, 1000 ether);
        vm.deal(addr2, 1000 ether);
        vm.deal(addr3, 1000 ether);
        vm.deal(addr4, 1000 ether);
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
        console.log("createTokenRevenueAfterJackpot", createTokenRevenueAfterJackpot);

        vm.startPrank(TREASURY);
        spr.approve(address(treasuryVesting), TREASURY_AMOUNT);
        treasuryVesting.stake(TREASURY_AMOUNT);
        vm.stopPrank();
        assertEq(spr.balanceOf(address(treasuryVesting)), TREASURY_AMOUNT);
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

    function testForPublicStaking() public {
        vm.startPrank(PUBLIC);
        spr.transfer(addr1, 100_000 ether);
        spr.transfer(addr2, 200_000 ether);
        spr.transfer(addr3, 400_000 ether);
        spr.transfer(addr4, 1_600_000 ether);
        vm.stopPrank();

        console.log("spr balance of addr1", spr.balanceOf(addr1));

        vm.startPrank(addr1);
        spr.approve(address(publicStaking), 100_000 ether);
        uint256 tokenId1 = publicStaking.stake(100_000 ether, SIX_MONTHS);
        console.log("after stake", spr.balanceOf(addr1));
        assertEq(spr.balanceOf(address(publicStaking)), 100_000 ether);
        assertEq(publicStaking.ownerOf(tokenId1), addr1);
        vm.stopPrank();

        console.log("token id1", tokenId1);

        vm.startPrank(addr2);
        spr.approve(address(publicStaking), 200_000 ether);
        uint256 tokenId2 = publicStaking.stake(200_000 ether, THREE_MONTHS);
 
        console.log("token id2", tokenId2);

        assertEq(publicStaking.ownerOf(tokenId2), addr2);
        vm.stopPrank();

        vm.startPrank(addr3);
        spr.approve(address(publicStaking), 400_000 ether);
        uint256 tokenId3 = publicStaking.stake(400_000 ether, ONE_MONTH);

        assertEq(publicStaking.ownerOf(tokenId3), addr3);
        vm.stopPrank();

        vm.startPrank(addr4);
        spr.approve(address(publicStaking), 800_000 ether);
        uint256 tokenId4 = publicStaking.stake(800_000 ether, FIFTEEN_DAYS);

        assertEq(publicStaking.ownerOf(tokenId4), addr4);
        vm.stopPrank();

        assertEq(publicStaking.totalStaked(), 1_500_000 ether);

        assertEq(publicStaking.getStakeInfo(tokenId1).sharesAmount, 100_000 ether * 8);
        assertEq(publicStaking.getStakeInfo(tokenId2).sharesAmount, 200_000 ether * 4);
        assertEq(publicStaking.getStakeInfo(tokenId3).sharesAmount, 400_000 ether * 2);
        assertEq(publicStaking.getStakeInfo(tokenId4).sharesAmount, 800_000 ether);

        console.log("before warp 14 days");

        vm.warp(block.timestamp + 14 days);

        vm.startPrank(addr1);
        vm.expectRevert();
        publicStaking.unstake(tokenId1);
        vm.stopPrank();

        vm.startPrank(addr2);
        vm.expectRevert();
        publicStaking.unstake(tokenId2);
        vm.stopPrank();

        vm.startPrank(addr3);
        vm.expectRevert();
        publicStaking.unstake(tokenId3);
        vm.stopPrank();

        vm.startPrank(addr4);
        vm.expectRevert();
        publicStaking.unstake(tokenId4);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(addr1);
        vm.expectRevert();
        publicStaking.unstake(tokenId1);
        assertEq(publicStaking.balanceOf(addr1), 1);
        vm.stopPrank();

        vm.startPrank(addr2);
        vm.expectRevert();
        publicStaking.unstake(tokenId2);
        vm.stopPrank();

        vm.startPrank(addr3);
        vm.expectRevert();
        publicStaking.unstake(tokenId3);
        vm.stopPrank();

        console.log("info of deleted nft", publicStaking.getStakeInfo(tokenId4).revenueShareBonus);

        vm.startPrank(addr4);
        publicStaking.unstake(tokenId4);
        assertEq(publicStaking.balanceOf(addr4), 0);
        assertEq(spr.balanceOf(addr4), 1_600_000 ether);
        vm.stopPrank();

        
        console.log("info of deleted nft", publicStaking.getStakeInfo(tokenId4).revenueShareBonus);
        //console.log("owner of burned nft", publicStaking.ownerOf(tokenId4));

        //Send 100 ether to revenue collector
        vm.startPrank(addr1);
        payable(revenueCollector).call{value: 100 ether, gas: 3000000}("");
        assertGt(revenueCollector.totalEtherCollected(), 99 ether);
        assertGt(revenueCollector.nftShare(), 1 ether);
        //distributed revenue
        revenueCollector.distributeRevenue();
        vm.stopPrank();

        //try to claim with all the stakers and check their revnue share afterwards

        console.log("treasurv vesting spr balance", spr.balanceOf(address(treasuryVesting)));
        console.log("public staking spr balance", spr.balanceOf(address(publicStaking)));

        uint256 treasuryVestingSprBalance = spr.balanceOf(address(treasuryVesting));
        uint256 publicStakingSprBalance = spr.balanceOf(address(publicStaking));

        //public staking reward ratio
        uint256 publicStakingRewardRatio = publicStaking.totalStaked() * 10000000 / (treasuryVestingSprBalance + publicStakingSprBalance);

        vm.startPrank(addr1);
        uint256 ethBalanceOfAddr1Before = address(addr1).balance;
        publicStaking.claimReward(tokenId1);
        uint256 expectedRevShare = 99 ether * publicStakingRewardRatio / 10000000 / 3;
        uint256 ethBalanceOfAddr1After = address(addr1).balance;
        uint256 totalClaimedAddr1 = ethBalanceOfAddr1After - ethBalanceOfAddr1Before;
        vm.stopPrank();

        vm.startPrank(addr2);
        uint256 ethBalanceOfAddr2Before = address(addr2).balance;
        publicStaking.claimReward(tokenId2);
        uint256 expectedRevShare2 = 99 ether * publicStakingRewardRatio / 10000000 / 3;
        uint256 ethBalanceOfAddr2After = address(addr2).balance;
        uint256 totalClaimedAddr2 = ethBalanceOfAddr2After - ethBalanceOfAddr2Before;
        vm.stopPrank();

        vm.startPrank(addr3);
        uint256 ethBalanceOfAddr3Before = address(addr3).balance;
        publicStaking.claimReward(tokenId3);
        uint256 expectedRevShare3 = 99 ether * publicStakingRewardRatio / 10000000 / 3;
        uint256 ethBalanceOfAddr3After = address(addr3).balance;
        uint256 totalClaimedAddr3 = ethBalanceOfAddr3After - ethBalanceOfAddr3Before;
        vm.stopPrank();

        //all three should be equal
        console.log("expected revenue share", expectedRevShare);
        assertEq(totalClaimedAddr1, totalClaimedAddr2);
        assertEq(totalClaimedAddr2, totalClaimedAddr3);
        assertEq(totalClaimedAddr3, totalClaimedAddr1);

        //addr4 restakes again
        vm.startPrank(addr4);
        spr.approve(address(publicStaking), 1_600_000 ether);
        console.log("token id4 before new stake", tokenId4);
        tokenId4 = publicStaking.stake(1_600_000 ether, FIFTEEN_DAYS);
        assertEq(tokenId4, 4);
        assertEq(publicStaking.ownerOf(tokenId4), addr4);
        vm.stopPrank();

        //SEND 100 ether to revenue collector
        vm.startPrank(addr1);
        payable(revenueCollector).call{value: 100 ether, gas: 3000000}("");
        assertEq(revenueCollector.totalEtherCollected(), 99 ether);
        assertGt(revenueCollector.nftShare(), 2 ether);
        //distributed revenue
        revenueCollector.distributeRevenue();
        vm.stopPrank();

        //claim reward for all addresses
        vm.startPrank(addr1);
        uint256 ethBalanceOfAddr1Before2 = address(addr1).balance;
        publicStaking.claimReward(tokenId1);
        uint256 ethBalanceOfAddr1After2 = address(addr1).balance;
        totalClaimedAddr1 = ethBalanceOfAddr1After2 - ethBalanceOfAddr1Before2;
        vm.stopPrank();

        vm.startPrank(addr2);
        uint256 ethBalanceOfAddr2Before2 = address(addr2).balance;
        publicStaking.claimReward(tokenId2);
        uint256 ethBalanceOfAddr2After2 = address(addr2).balance;
        totalClaimedAddr2 = ethBalanceOfAddr2After2 - ethBalanceOfAddr2Before2;
        vm.stopPrank();

        vm.startPrank(addr3);
        uint256 ethBalanceOfAddr3Before2 = address(addr3).balance;
        publicStaking.claimReward(tokenId3);
        uint256 ethBalanceOfAddr3After2 = address(addr3).balance;
        totalClaimedAddr3 = ethBalanceOfAddr3After2 - ethBalanceOfAddr3Before2;
        vm.stopPrank();

        vm.startPrank(addr4);
        uint256 ethBalanceOfAddr4Before2 = address(addr4).balance;
        publicStaking.claimReward(tokenId4);
        uint256 ethBalanceOfAddr4After2 = address(addr4).balance;
        uint256 totalClaimedAddr4 = ethBalanceOfAddr4After2 - ethBalanceOfAddr4Before2;
        vm.stopPrank();

        console.log("before last check");

        //first three should be equal. addr4 should be double
        assertEq(totalClaimedAddr1, totalClaimedAddr2);
        console.log("total claimed addr1 equal to total claimed addr2");
        assertEq(totalClaimedAddr2, totalClaimedAddr3);
        console.log("total claimed addr2 equal to total claimed addr3");
        assertEq(totalClaimedAddr4, totalClaimedAddr1 * 2);
        console.log("total claimed addr4 equal to total claimed addr1 * 2");

        //warp to the end of locks
        vm.warp(block.timestamp + 365 days);

        //send 100 ether to revenue collector
        vm.startPrank(addr1);
        payable(revenueCollector).call{value: 100 ether, gas: 3000000}("");
        assertEq(revenueCollector.totalEtherCollected(), 99 ether);
        assertGt(revenueCollector.nftShare(), 2 ether);
        //distributed revenue
        revenueCollector.distributeRevenue();
        vm.stopPrank();

        
        //unstake for all addresses
        vm.startPrank(addr1);
        uint256 ethBalanceOfAddr1Before3 = address(addr1).balance;
        publicStaking.unstake(tokenId1);
        uint256 ethBalanceOfAddr1After3 = address(addr1).balance;
        uint256 totalClaimedAddr1AfterUnstake = ethBalanceOfAddr1After3 - ethBalanceOfAddr1Before3;
        vm.stopPrank();

        vm.startPrank(addr2);
        uint256 ethBalanceOfAddr2Before3 = address(addr2).balance;
        publicStaking.unstake(tokenId2);
        uint256 ethBalanceOfAddr2After3 = address(addr2).balance;
        uint256 totalClaimedAddr2AfterUnstake = ethBalanceOfAddr2After3 - ethBalanceOfAddr2Before3;
        vm.stopPrank();

        vm.startPrank(addr3);
        uint256 ethBalanceOfAddr3Before3 = address(addr3).balance;
        publicStaking.unstake(tokenId3);
        uint256 ethBalanceOfAddr3After3 = address(addr3).balance;
        uint256 totalClaimedAddr3AfterUnstake = ethBalanceOfAddr3After3 - ethBalanceOfAddr3Before3;
        vm.stopPrank();

        vm.startPrank(addr4);
        uint256 ethBalanceOfAddr4Before3 = address(addr4).balance;
        publicStaking.unstake(tokenId4);
        uint256 ethBalanceOfAddr4After3 = address(addr4).balance;
        uint256 totalClaimedAddr4AfterUnstake = ethBalanceOfAddr4After3 - ethBalanceOfAddr4Before3;
        vm.stopPrank();

        //all should be equal
        assertEq(totalClaimedAddr1AfterUnstake, totalClaimedAddr2AfterUnstake);
        assertEq(totalClaimedAddr2AfterUnstake, totalClaimedAddr3AfterUnstake);
        assertEq(totalClaimedAddr3AfterUnstake * 2, totalClaimedAddr4AfterUnstake);

    }

        
    

}
