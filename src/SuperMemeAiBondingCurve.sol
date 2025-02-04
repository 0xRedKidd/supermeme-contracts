// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title SuperMemeAiBondingCurve
/// @notice ERC20 token with a linear bonding curve pricing mechanism.
/// Buyers pay SPR tokens (via transferFrom) and receive minted tokens according to the bonding curve.
/// The cumulative cost is defined as:
///    F(s) = p₀ * s + (2 * p₀ * s²) / MAX_SUPPLY,
/// with p₀ = totalSprWei / (3 * MAX_SUPPLY). Thus, the first token costs p₀ and the last token costs 5 * p₀.
contract SuperMemeAiBondingCurve is ERC20 {
    // Maximum tokens available for sale.
    uint256 public constant MAX_SUPPLY = 1e9; // 1e9 tokens.

    // Total SPR tokens to be collected when the sale is complete (in SPR wei).
    // This value can vary between 800k and 1.2m SPR tokens (in wei).
    uint256 public totalSprWei;

    // The initial price per token (in SPR wei), computed as totalSprWei / (3 * MAX_SUPPLY).
    uint256 public initialPrice;

    // The number of tokens sold so far (minted via the bonding curve).
    uint256 public scaledSupply;

    // Reference to the SPR token.
    IERC20 public spr;

    // Event emitted when tokens are purchased.
    event TokensBought(address indexed buyer, uint256 amount, uint256 cost);
    // Event emitted when tokens are sold.
    event TokensSold(address indexed seller, uint256 amount, uint256 sprReturned);

    /**
     * @notice Constructor sets the SPR token address, total SPR amount to be collected, and initializes the ERC20 token.
     * @param sprTokenAddress The address of the SPR token.
     * @param _totalSprWei The total amount of SPR tokens (in wei) to be collected at sale completion.
     *                     Must be between 800k and 1.2m SPR tokens (in wei).
     */
    constructor(address sprTokenAddress, uint256 _totalSprWei) ERC20("Super Meme Token", "SMT") {
        // Ensure _totalSprWei is within the allowed range:
        // 800,000 * 1e18 <= _totalSprWei <= 1,200,000 * 1e18.
        require(
            _totalSprWei >= 800e3 * 1e18 && _totalSprWei <= 1.2e6 * 1e18,
            "Total SPR wei must be between 800k and 1.2m tokens (in wei)"
        );

        totalSprWei = _totalSprWei;
        // Calculate the initial price per token: p₀ = totalSprWei / (3 * MAX_SUPPLY).
        initialPrice = totalSprWei / (3 * MAX_SUPPLY);
        spr = IERC20(sprTokenAddress);
    }

    /**
     * @notice Returns the cumulative cost F(s) (in SPR wei) to purchase s tokens.
     * @dev F(s) = p₀ * s + (2 * p₀ * s²) / MAX_SUPPLY.
     * At s = MAX_SUPPLY, F(MAX_SUPPLY) = 3 * p₀ * MAX_SUPPLY = totalSprWei.
     */
    function cumulativeCost(uint256 s) public view returns (uint256) {
        uint256 part1 = initialPrice * s; // p₀ * s.
        uint256 part2 = (2 * initialPrice * s * s) / MAX_SUPPLY; // (2 * p₀ * s²) / MAX_SUPPLY.
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
        // (Optional) Ensure that a nonzero purchase does not return 0.
        if (amount > 0 && cost == 0) {
            revert("Cost is zero");
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

    /**
     * @notice Calculates the amount of SPR (in wei) that will be returned to the user for selling `amount` tokens.
     * @dev The return SPR is: F(scaledSupply) - F(scaledSupply - amount).
     * @param amount The number of tokens the user intends to sell.
     * @return sprReturn The amount of SPR (in wei) that will be returned.
     */
    function calculateSellTokenAmount(uint256 amount) public view returns (uint256 sprReturn) {
        require(amount > 0, "Amount must be > 0");
        require(scaledSupply >= amount, "Not enough tokens sold");
        sprReturn = cumulativeCost(scaledSupply) - cumulativeCost(scaledSupply - amount);
    }

    /**
     * @notice Allows a user to sell tokens back to the bonding curve.
     * The function calculates the SPR refund using the bonding curve and burns the sold tokens.
     * @param amount The number of tokens the user wants to sell.
     *
     * Requirements:
     * - The user must have at least `amount` SMT tokens.
     * - The contract must have enough SPR tokens to refund the user.
     *
     * Effects:
     * - Burns the SMT tokens from the seller.
     * - Decreases the internal supply (`scaledSupply`) accordingly.
     * - Transfers the calculated SPR tokens (in wei) to the seller.
     * - Emits a TokensSold event.
     */
    function sellTokens(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient SMT tokens to sell");
        require(scaledSupply >= amount, "Cannot sell more tokens than sold");

        // Calculate the SPR amount to return.
        uint256 sprReturn = calculateSellTokenAmount(amount);

        // Burn the tokens from the seller.
        _burn(msg.sender, amount);
        // Update the internal supply to reflect the tokens being sold.
        scaledSupply -= amount;

        // Transfer the calculated SPR tokens back to the seller.
        bool success = spr.transfer(msg.sender, sprReturn);
        require(success, "SPR transfer failed");

        emit TokensSold(msg.sender, amount, sprReturn);
    }

      /**
     * @notice Overrides the internal ERC20 _update function to restrict transfers.
     * @dev Until the bonding curve has collected the full required SPR tokens,
     * buyers cannot transfer SMT tokens between themselves.
     *
     * Allowances:
     * - Minting (from address(0)) and burning (to address(0)) are always allowed.
     * - Transfers where either sender or receiver is the contract itself are allowed.
     * - Otherwise, if the contract's SPR balance is less than totalSprWei,
     *   transfers are disabled.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        // Allow minting or burning.
        if (from == address(0) || to == address(0)) {
            super._update(from, to, value);
            return;
        }
        // Allow transfers where the bonding curve contract is involved.
        if (from == address(this) || to == address(this)) {
            super._update(from, to, value);
            return;
        }
        // Otherwise, if the contract has not collected the full required SPR tokens,
        // disallow transfers between users.
        if (spr.balanceOf(address(this)) < totalSprWei) {
            revert("Transfers disabled until sale complete");
        }
        super._update(from, to, value);
    }
}
