pragma solidity ^0.8.0;

import "../src/MockTokens/MockNFT.sol";
import "../src/SuperMemeRevenueCollector.sol";
import "forge-std/Test.sol";
import "../src/SuperMemeToken/SuperMemePublicStaking.sol";
import "../src/SuperMemeToken/SuperMemeTreasuryVesting.sol";
import "../src/SuperMemeToken/SuperMeme.sol";

contract TestRevenueCollector is Test {

    MockNFT public mockNFT;
    SuperMemeRevenueCollector public revenueCollector;
    SuperMeme public spr;
    SuperMemePublicStaking public publicStaking;
    SuperMemeTreasuryVesting public treasuryVesting;

    uint256 public tgeDate = 1732482000;


    address public owner = address(0x123);
    address public addr1 = address(0x456);
    address public addr2 = address(0x789);

    

    function setUp() public {
        vm.deal(owner, 1000 ether);
        vm.deal(addr1, 1000 ether);
        vm.deal(addr2, 1000 ether);


        vm.startPrank(owner);

        spr = new SuperMeme();
        publicStaking = new SuperMemePublicStaking(address(spr));
        treasuryVesting = new SuperMemeTreasuryVesting(address(spr), tgeDate);


        mockNFT = new MockNFT(owner);
        revenueCollector = new SuperMemeRevenueCollector(address(spr), address(publicStaking), address(treasuryVesting));
        revenueCollector.setNFT(address(mockNFT));
        vm.stopPrank();

    }

    function testDeploy() public {
        assertEq(mockNFT.ownerOf(0), address(owner));
        assertEq(revenueCollector.owner(), address(owner)); 
    }
    
    function testReceive() public {
        vm.startPrank(addr1);
        payable(revenueCollector).call{value: 100 ether, gas: 3000000}("");
        assertEq(revenueCollector.totalEtherCollected(), 99 ether);
        assertEq(revenueCollector.nftShare(), 1 ether);
    }

    function testCollectNFTJackpot() public {
        vm.startPrank(owner);
        payable(revenueCollector).call{value: 100 ether, gas: 3000000}("");
        assertEq(revenueCollector.totalEtherCollected(), 99 ether);
        assertEq(revenueCollector.nftShare(), 1 ether);
        console.log("before collectNFTJackpot");
        revenueCollector.collectNFTJackpot(0);
        console.log("passed first collectNFTJackpot");
        assertEq(revenueCollector.nftShare(), 0);
        assertEq(revenueCollector.remainingLockTime(0), 1 weeks);
        vm.expectRevert();
        revenueCollector.collectNFTJackpot(0);
        vm.warp(block.timestamp + 2 weeks);
        revenueCollector.collectNFTJackpot(0);
        vm.stopPrank();
    }

}