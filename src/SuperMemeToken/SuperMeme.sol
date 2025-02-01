// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
   ▄████████ ███    █▄     ▄███████▄    ▄████████    ▄████████   ▄▄▄▄███▄▄▄▄      ▄████████   ▄▄▄▄███▄▄▄▄      ▄████████ 
  ███    ███ ███    ███   ███    ███   ███    ███   ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ 
  ███    █▀  ███    ███   ███    ███   ███    █▀    ███    ███ ███   ███   ███   ███    █▀  ███   ███   ███   ███    █▀  
  ███        ███    ███   ███    ███  ▄███▄▄▄      ▄███▄▄▄▄██▀ ███   ███   ███  ▄███▄▄▄     ███   ███   ███  ▄███▄▄▄     
▀███████████ ███    ███ ▀█████████▀  ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ███   ███   ███ ▀▀███▀▀▀     ███   ███   ███ ▀▀███▀▀▀     
         ███ ███    ███   ███          ███    █▄  ▀███████████ ███   ███   ███   ███    █▄  ███   ███   ███   ███    █▄  
   ▄█    ███ ███    ███   ███          ███    ███   ███    ███ ███   ███   ███   ███    ███ ███   ███   ███   ███    ███ 
 ▄████████▀  ████████▀   ▄████▀        ██████████   ███    ███  ▀█   ███   █▀    ██████████  ▀█   ███   █▀    ██████████ 
                                                    ███    ███                                                           
*/


contract SuperMeme is ERC20 {
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

    constructor() ERC20("SuperMeme", "SPR") {
        _mint(SEED, SEED_AMOUNT);
        _mint(PUBLIC, PUBLIC_AMOUNT);
        _mint(TEAM, TEAM_AMOUNT);
        _mint(TREASURY, TREASURY_AMOUNT);
        _mint(DEVELOPMENT, DEVELOPMENT_AMOUNT);
        _mint(MARKETING, MARKETING_AMOUNT);
        _mint(LIQUIDITY, LIQUIDITY_AMOUNT);
        _mint(AIRDROP, AIRDROP_AMOUNT);
        _mint(ADVISOR, ADVISOR_AMOUNT);
        require(
            totalSupply() == 1_000_000_000 * 10 ** decimals(),
            "SuperMeme: Invalid total supply"
        );
    }
}
