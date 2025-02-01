// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../src/SuperMemeDegenBondingCurve.sol";
// import "../src/SuperMemeRefundableBondingCurve.sol";
// import "../src/SuperMemeFactory.sol";
// import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";

// contract SuperMemeFactoryDeployTests is Test {
//     uint256 public dummyBuyAmount = 1000;
//     uint256 public dummyBuyAmount2 = 1000000;

//     IUniswapFactory public uniswapFactory;
//     SuperMemeFactory public factory;
//     SuperMemeDegenBondingCurve public degenbondingcurve;
//     uint256 public createTokenRevenue = 0.00001 ether;

//     address public owner = address(0x123);
//     address public addr1 = address(0x456);
//     address public addr2 = address(0x789);
//     address public addr3 = address(0x101112);

//     function setUp() public {
//         uint256 createTokenRevenue = 0.00001 ether;

//         address fakeContract = address(0x12123123);

//         uniswapFactory = IUniswapFactory(address(0x1));

//         degenbondingcurve = new SuperMemeDegenBondingCurve(
//             "SuperMeme",
//             "MEME",
//             false,
//             0,
//             owner,
//             address(0x123),
//             0,
//             0
//         );

//         vm.deal(owner, 1000 ether);
//         vm.deal(addr1, 1000 ether);
//         vm.deal(addr2, 1000 ether);

//         factory = new SuperMemeFactory();
//     }

//     function testDeploy() public {
//         assertEq(factory.revenueCollector(), address(0x123));
//     }

//     function testDeployNoDevLockNoDevBuy() public {
//         vm.startPrank(addr1);
//         address newToken = factory.createToken{value: createTokenRevenue}(
//             "SuperMeme",
//             "MEME",
//             false,
//             0,
//             address(addr1),
//             0,
//             0,
//             0
//         );
//         assertEq(factory.tokenAddresses(0), newToken);
//     }

//     function testDeployNoDevLockYesBuy() public {
//         vm.startPrank(addr1);
//         uint256[] memory buyAmounts = new uint256[](8);
//         buyAmounts[0] = 500;
//         buyAmounts[1] = 2000000;
//         buyAmounts[2] = 7500000;
//         buyAmounts[3] = 15000000;
//         buyAmounts[4] = 25000000;
//         buyAmounts[5] = 35000000;
//         buyAmounts[6] = 45000000;
//         buyAmounts[7] = 110000000;
//         for (uint256 i = 0; i < buyAmounts.length; i++) {
            
//             uint256 buyAmount = buyAmounts[i];
//             uint256 cost = degenbondingcurve.calculateCost(buyAmount);
//             uint256 tax = cost / 100;
//             uint256 costWithTax = cost + tax;
//             uint256 slippage = cost / 100;
//             uint256 buyEth = costWithTax + slippage;
//             address newToken = factory.createToken{
//                 value: createTokenRevenue + buyEth
//             }(
//                 "SuperMeme",
//                 "MEME",
//                 false,
//                 buyAmount,
//                 address(addr1),
//                 0,
//                 buyEth,
//                 0
//             );
//             SuperMemeDegenBondingCurve newTokenInstance = SuperMemeDegenBondingCurve(
//                     newToken
//                 );
//             assertEq(newTokenInstance.balanceOf(addr1), buyAmount * 10 ** 18);
//         }
//     }

//     function testDeployYesDevLockYesBuy() public {
//         vm.startPrank(addr1);
//         uint256[] memory buyAmounts = new uint256[](8);
//         buyAmounts[0] = 500;
//         buyAmounts[1] = 2000000;
//         buyAmounts[2] = 7500000;
//         buyAmounts[3] = 15000000;
//         buyAmounts[4] = 25000000;
//         buyAmounts[5] = 35000000;
//         buyAmounts[6] = 45000000;
//         buyAmounts[7] = 110000000;
//         for (uint256 i = 0; i < buyAmounts.length; i++) {
            
//             uint256 buyAmount = buyAmounts[i];
//             uint256 cost = degenbondingcurve.calculateCost(buyAmount);
//             uint256 tax = cost / 100;
//             uint256 costWithTax = cost + tax;
//             uint256 slippage = cost / 100;
//             uint256 buyEth = costWithTax + slippage;
//             address newToken = factory.createToken{
//                 value: createTokenRevenue + buyEth
//             }(
//                 "SuperMeme",
//                 "MEME",
//                 true,
//                 buyAmount,
//                 address(addr1),
//                 1 weeks,
//                 buyEth,
//                 0
//             );
//             SuperMemeDegenBondingCurve newTokenInstance = SuperMemeDegenBondingCurve(
//                     newToken
//                 );
//             assertEq(newTokenInstance.balanceOf(addr1), buyAmount * 10 ** 18);
//         }
//     }

//     function testRefundableNoDevBuy() public {
//         vm.startPrank(addr1);
//         uint256 buyAmount = 0;
//         uint256 cost = degenbondingcurve.calculateCost(buyAmount);
//         uint256 tax = cost / 100;
//         uint256 costWithTax = cost + tax;
//         uint256 slippage = cost / 100;
//         uint256 buyEth = costWithTax + slippage;
//         address newToken = factory.createToken{value: createTokenRevenue}(
//             "SuperMeme",
//             "MEME",
//             false,
//             0,
//             address(addr1),
//             0,
//             0,
//             1
//         );
//         SuperMemeRefundableBondingCurve newTokenInstance = SuperMemeRefundableBondingCurve(
//                 newToken
//             );
//         assertEq(newTokenInstance.balanceOf(addr1), buyAmount * 10 ** 18);
//     }


//     function testRefundableYesDevBuy() public {
//         //with the loop please
//         vm.startPrank(addr1);
//         uint256[] memory buyAmounts = new uint256[](8);
//         buyAmounts[0] = 500;
//         buyAmounts[1] = 2000000;
//         buyAmounts[2] = 7500000;
//         buyAmounts[3] = 15000000;
//         buyAmounts[4] = 25000000;
//         buyAmounts[5] = 35000000;
//         buyAmounts[6] = 45000000;
//         buyAmounts[7] = 110000000;
//         for (uint256 i = 0; i < buyAmounts.length; i++) {
            
//             uint256 buyAmount = buyAmounts[i];
//             uint256 cost = degenbondingcurve.calculateCost(buyAmount);
//             uint256 tax = cost / 100;
//             uint256 costWithTax = cost + tax;
//             uint256 slippage = cost / 100;
//             uint256 buyEth = costWithTax + slippage;
//             address newToken = factory.createToken{
//                 value: createTokenRevenue + buyEth
//             }(
//                 "SuperMeme",
//                 "MEME",
//                 false,
//                 buyAmount,
//                 address(addr1),
//                 0,
//                 buyEth,
//                 1
//             );
//             SuperMemeRefundableBondingCurve newTokenInstance = SuperMemeRefundableBondingCurve(
//                     newToken
//                 );
//             assertEq(newTokenInstance.balanceOf(addr1), buyAmount * 10 ** 18);
//         }
//     }
// }
