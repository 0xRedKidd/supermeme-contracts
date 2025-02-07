// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Minimal interface for Uniswap V2 Router02.
interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA, // SMT token address
        address tokenB, // SPR token address
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,      // liquidity recipient
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

/// @title SuperMemeAiBondingCurve
/// @notice ERC20 token with a linear bonding curve pricing mechanism.
/// Buyers pay SPR tokens (via transferFrom) and receive minted tokens according to the bonding curve.
/// The cumulative cost is defined as:
///    F(s) = p₀ * s + (2 * p₀ * s²) / MAX_SUPPLY,
/// with p₀ = totalSprWei / (3 * MAX_SUPPLY). Thus, the first token costs p₀ and the last token costs 5 * p₀.
contract SuperMemeAiBondingCurve is ERC20 {
    event SentToDex(uint256 sprAmout, uint256 agentAmount, uint256 timestamp);
    event Price(
        uint256 indexed price,
        uint256 indexed totalSupply,
        address indexed tokenAddress,
        uint256 amount
    );
    event tokensBought(
        uint256 indexed amount,
        uint256 cost,
        address indexed tokenAddress,
        address indexed buyer,
        uint256 totalSupply
    );
    event tokensSold(
        uint256 indexed amount,
        uint256 refund,
        address indexed tokenAddress,
        address indexed seller,
        uint256 totalSupply
    );


    // Maximum tokens available for sale.
    uint256 public constant MAX_SUPPLY = 1e9; // 1e9 tokens.

    // Total SPR tokens to be collected when the sale is complete (in SPR wei).
    // This value can vary between 800k and 1.2m SPR tokens (in wei).
    uint256 public totalSprWei;

    // The initial price per token (in SPR wei), computed as totalSprWei / (3 * MAX_SUPPLY).
    uint256 public initialPrice;

    // The number of tokens sold so far (minted via the bonding curve).
    uint256 public scaledSupply;

    // The Uniswap V2 router and SPR token addresses are now constants.
    address public constant UNISWAP_V2_ROUTER_ADDRESS = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address public constant SPR_TOKEN_ADDRESS = 0x77184100237e46b06cd7649aBf37435F5D5e678B;
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS);
    // Instead of storing a spr instance, we use the constant address with IERC20 when needed:
    // IERC20 public constant spr = IERC20(SPR_TOKEN_ADDRESS);

    // Liquidity threshold for SMT tokens to be sent to the DEX.
    uint256 public constant LIQUIDITY_TOKEN_AMOUNT = 200_000_000 ether; // 200 million tokens.

    // Flag to ensure liquidity is sent only once.
    bool public liquiditySent;

    /**
     * @notice Constructor sets the total SPR amount to be collected and initializes the ERC20 token.
     * @param _totalSprWei The total amount of SPR tokens (in wei) to be collected at sale completion.
     *                     Must be between 800k and 1.2m SPR tokens (in wei).
     */
    constructor(uint256 _totalSprWei) ERC20("Super Meme Token", "SMT") {
        require(
            _totalSprWei >= 800e3 * 1e18 && _totalSprWei <= 1.2e6 * 1e18,
            "Total SPR wei must be between 800k and 1.2m tokens (in wei)"
        );
        totalSprWei = _totalSprWei;
        initialPrice = totalSprWei / (3 * MAX_SUPPLY);
    }

    /**
     * @notice Returns the cumulative cost F(s) (in SPR wei) to purchase s tokens.
     * @dev F(s) = p₀ * s + (2 * p₀ * s²) / MAX_SUPPLY.
     * At s = MAX_SUPPLY, F(MAX_SUPPLY) = 3 * p₀ * MAX_SUPPLY = totalSprWei.
     */
    function cumulativeCost(uint256 s) public view returns (uint256) {
        uint256 part1 = initialPrice * s;
        uint256 part2 = (2 * initialPrice * s * s) / MAX_SUPPLY;
        return part1 + part2;
    }

    /**
     * @notice Calculates the incremental cost (in SPR wei) to purchase an additional `amount` tokens.
     * @dev The incremental cost is: cost = F(scaledSupply + amount) - F(scaledSupply).
     */
    function calculateCost(uint256 amount) public view returns (uint256) {
        uint256 newSupply = scaledSupply + amount;
        uint256 cost = cumulativeCost(newSupply) - cumulativeCost(scaledSupply);
        if (amount > 0 && cost == 0) {
            revert("Cost is zero");
        }
        return cost;
    }

    /**
     * @notice Allows a user to buy tokens by paying SPR tokens.
     * @param amount The number of tokens to purchase.
     *
     * Effects:
     * - Transfers SPR tokens (in wei) from the buyer to this contract.
     * - Increases the internal supply (`scaledSupply`).
     * - Mints `amount` tokens to the buyer.
     * - Emits a TokensBought event.
     */
    function buyTokens(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        uint256 cost = calculateCost(amount);
        require(cost > 0, "Cost must be > 0");

        bool success = IERC20(SPR_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), cost);
        require(success, "SPR transfer failed");

        scaledSupply += amount;
        _mint(msg.sender, amount);

        if (scaledSupply >= MAX_SUPPLY) {
            sendToDex();
        }

        emit tokensBought(amount, cost, address(this), msg.sender, totalSupply());
    }

    /**
     * @notice Calculates the amount of SPR (in wei) that will be returned for selling `amount` tokens.
     * @dev The refund is: F(scaledSupply) - F(scaledSupply - amount).
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
     * Burns the sold tokens, decreases the internal supply, and transfers the SPR refund.
     * @param amount The number of tokens to sell.
     */
    function sellTokens(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient SMT tokens to sell");
        require(scaledSupply >= amount, "Cannot sell more tokens than sold");

        uint256 sprReturn = calculateSellTokenAmount(amount);
        _burn(msg.sender, amount);
        scaledSupply -= amount;

        bool success = IERC20(SPR_TOKEN_ADDRESS).transfer(msg.sender, sprReturn);
        require(success, "SPR transfer failed");

        emit tokensSold(amount, sprReturn, address(this), msg.sender, totalSupply());
    }

    /**
     * @notice Overrides the internal ERC20 _update function to restrict transfers.
     * Until the contract collects the full required SPR tokens, transfers between users (that are not mints, burns,
     * or transfers involving the contract itself) are disabled.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        if (from == address(0) || to == address(0)) {
            super._update(from, to, value);
            return;
        }
        if (from == address(this) || to == address(this)) {
            super._update(from, to, value);
            return;
        }
        if (IERC20(SPR_TOKEN_ADDRESS).balanceOf(address(this)) < totalSprWei) {
            revert("Transfers disabled until sale complete");
        }
        super._update(from, to, value);
    }

    /**
     * @notice Once the sale is complete (i.e. when scaledSupply reaches MAX_SUPPLY), this function mints 200 million
     * SMT tokens to the contract and adds liquidity to Uniswap V2 using all collected SPR tokens and the minted SMT tokens.
     * Can be called only once.
     */
    function sendToDex() public {
        require(!liquiditySent, "Liquidity already sent");
        require(scaledSupply >= MAX_SUPPLY, "Sale not complete");

        _mint(address(this), LIQUIDITY_TOKEN_AMOUNT);

        uint256 sprAmount = IERC20(SPR_TOKEN_ADDRESS).balanceOf(address(this));
        require(sprAmount > 0, "No SPR tokens to add as liquidity");

        _approve(address(this), UNISWAP_V2_ROUTER_ADDRESS, LIQUIDITY_TOKEN_AMOUNT);
        require(IERC20(SPR_TOKEN_ADDRESS).approve(UNISWAP_V2_ROUTER_ADDRESS, sprAmount), "SPR approve failed");

        uint256 sprForPool = 960_000_000 ether;

        (uint amountA, uint amountB, uint liquidity) = uniswapV2Router.addLiquidity(
            address(this),
            SPR_TOKEN_ADDRESS,
            LIQUIDITY_TOKEN_AMOUNT,
            sprForPool,
            0,
            0,
            address(this),
            block.timestamp + 600
        );

        liquiditySent = true;
        emit SentToDex(sprAmount, LIQUIDITY_TOKEN_AMOUNT, block.timestamp);
    }
}
