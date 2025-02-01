pragma solidity 0.8.20;

import "./SuperMemeDegenBondingCurve.sol";

contract SuperMemeTokenCalculator {

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

    uint256 public constant MAX_SALE_SUPPLY = 1e9; // 1 billion tokens
    uint256 public constant TOTAL_ETHER = 4 ether;
    uint256 public constant SCALE = 1e18; // Scaling factor
    uint256 public constant A = 234375; // Calculated constant A
    uint256 liquidityThreshold = 200_000_000 * 10 ** 18;
    uint256 public constant scaledLiquidityThreshold = 200_000_000;
    function calculateTokensForEth(
        uint256 scaledSupply,
        uint256 loopVar,
        uint256 ethAmount
    ) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply;
        uint256 tokens = 0;

        while (true) {
            uint256 cost = ((((A * ((newSupply ** 3) - (currentSupply ** 3))) *
                10 ** 5) / (3 * SCALE)) * 40000) / 77500;
            if (cost > ethAmount) {
                break;
            }
            ethAmount -= cost;
            currentSupply = newSupply;
            newSupply += loopVar;
            tokens += loopVar;
        }
        return tokens;
    }
}
