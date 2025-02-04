// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



/// @title SuperMemeAiBondingCurve
/// @notice ERC20 token with a linear bonding curve pricing mechanism.
/// Buyers pay SPR tokens (via transferFrom) and receive minted tokens according to the bonding curve.
/// The cumulative cost is defined as:
///    F(s) = p₀ * s + (2 * p₀ * s²) / MAX_SUPPLY,
/// with p₀ = TOTAL_SPR_WEI / (3 * MAX_SUPPLY). Thus, the first token costs p₀ and the last token costs 5 * p₀.
contract SuperMemeAiBondingCurve is ERC20 {
    // Total SPR tokens collected when the sale is complete (in SPR wei).
    uint256 public constant TOTAL_SPR_WEI = 1e6 * 1e18; // 1e6 SPR tokens in wei.
    // Maximum tokens available for sale.
    uint256 public constant MAX_SUPPLY = 1e9; // 1e9 tokens.

    // The initial price per token (in SPR wei).
    uint256 public constant INITIAL_PRICE = TOTAL_SPR_WEI / (3 * MAX_SUPPLY);

    // The number of tokens sold so far (minted via the bonding curve).
    uint256 public scaledSupply;

    // Reference to the SPR token.
    IERC20 public spr;

    // Event emitted when tokens are purchased.
    event TokensBought(address indexed buyer, uint256 amount, uint256 cost);

    /**
     * @notice Constructor sets the SPR token address and initializes the ERC20 token.
     * @param sprTokenAddress The address of the SPR token.
     */
    constructor(address sprTokenAddress) ERC20("Super Meme Token", "SMT") {
        spr = IERC20(sprTokenAddress);
    }

    /**
     * @notice Returns the cumulative cost F(s) (in SPR wei) to purchase s tokens.
     * @dev F(s) = p₀ * s + (2 * p₀ * s²) / MAX_SUPPLY.
     * At s = MAX_SUPPLY, F(MAX_SUPPLY) = 3 * p₀ * MAX_SUPPLY = TOTAL_SPR_WEI.
     */
    function cumulativeCost(uint256 s) public pure returns (uint256) {
        uint256 part1 = INITIAL_PRICE * s; // p₀ * s.
        uint256 part2 = (2 * INITIAL_PRICE * s * s) / MAX_SUPPLY; // (2 * p₀ * s²) / MAX_SUPPLY.
        return part1 + part2;
    }

    /**
     * @notice Calculates the incremental cost (in SPR wei) to purchase an additional `amount` tokens.
     * @dev The incremental cost is: cost = F(scaledSupply + amount) - F(scaledSupply).
     */
    function calculateCost(uint256 amount) public view returns (uint256) {
        uint256 current = scaledSupply;
        uint256 newSupply = current + amount;
        uint256 cost = cumulativeCost(newSupply) - cumulativeCost(current);
        // (Optional) Ensure nonzero purchase does not return 0.
        if (amount > 0 && cost == 0) {
            cost = 1;
        }
        return cost;
    }

    /**
     * @notice Allows a user to buy tokens by paying SPR tokens.
     * @param amount The number of tokens to purchase.
     *
     * Requirements:
     * - The buyer must have approved the contract to spend the required SPR tokens.
     * - The transfer of SPR tokens from the buyer to this contract must succeed.
     *
     * Effects:
     * - Calculates the SPR cost according to the bonding curve.
     * - Transfers SPR tokens (in wei) from the buyer to this contract.
     * - Increases the internal supply (`scaledSupply`).
     * - Mints `amount` tokens to the buyer.
     * - Emits a TokensBought event.
     */
    function buyTokens(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        uint256 cost = calculateCost(amount);
        require(cost > 0, "Cost must be > 0");

        // Transfer SPR tokens (in wei) from the buyer to this contract.
        bool success = spr.transferFrom(msg.sender, address(this), cost);
        require(success, "SPR transfer failed");

        // Update internal supply and mint tokens to the buyer.
        scaledSupply += amount;
        _mint(msg.sender, amount);

        emit TokensBought(msg.sender, amount, cost);
    }
}
