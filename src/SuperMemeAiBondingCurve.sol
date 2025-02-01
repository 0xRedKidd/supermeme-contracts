// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IUniswapV2Router02.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

contract SuperMemeDegenBondingCurve is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ─────────────────────────────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────────────────────────────
    event SentToDex(uint256 collateralAmount, uint256 tokenAmount, uint256 timestamp);
    event Price(
        uint256 indexed price,
        uint256 indexed totalSupply,
        address indexed tokenAddress,
        uint256 amount
    );
    event TokensBought(
        uint256 indexed amount,
        uint256 cost,
        address indexed tokenAddress,
        address indexed buyer,
        uint256 totalSupply
    );
    event TokensSold(
        uint256 indexed amount,
        uint256 refund,
        address indexed tokenAddress,
        address indexed seller,
        uint256 totalSupply
    );

    // ─────────────────────────────────────────────────────────────────────────────
    // CONSTANTS & STATE VARIABLES
    // ─────────────────────────────────────────────────────────────────────────────
    // The bonding curve will collect a total of 5 million collateral tokens.
    uint256 public constant TOTAL_COLLATERAL = 5_000_000 * 1e18;
    uint256 public constant SCALE = 1e18; // scaling factor for math
    uint256 public constant A = 234375; // constant used in the cubic integration formula
    uint256 public constant scaledLiquidityThreshold = 200_000_000;

    // Amount of tokens minted for liquidity (to be paired on the DEX)
    uint256 liquidityThreshold = 200_000_000 * 1e18;
    uint256 public MAX_SALE_SUPPLY = 1e9; // maximum “scaled” tokens available for sale

    // Trade tax (example: 1000/100000 = 1% tax)
    uint256 private constant tradeTax = 1000;
    uint256 private constant tradeTaxDivisor = 100000;

    // Instead of tracking ETH, we track the collateral token collected.
    uint256 public totalCollateralCollected;
    uint256 public scaledSupply;

    bool public bondingCurveCompleted;

    address public revenueCollector;
    uint256 public totalRevenueCollected;
    // A fixed fee to be taken before sending liquidity.
    uint256 public constant SEND_DEX_REVENUE = 150000000000000000; // 0.15 tokens

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;

    address public factoryContract;

    // The collateral token that buyers use is now a constant.
    // Replace the address below with the actual deployed collateral token address.
    address public constant COLLATERAL_TOKEN_ADDRESS = 0x1234567890123456789012345678901234567890;
    IERC20 public constant COLLATERAL_TOKEN = IERC20(COLLATERAL_TOKEN_ADDRESS);

    // ─────────────────────────────────────────────────────────────────────────────
    // CONSTRUCTOR
    // ─────────────────────────────────────────────────────────────────────────────
    constructor(
        string memory _name,
        string memory _symbol,
        address _revenueCollector,
        address _uniswapRouter
    )
        ERC20(_name, _symbol)
    {
        factoryContract = msg.sender;
        revenueCollector = _revenueCollector;
        uniswapV2Router = IUniswapV2Router02(_uniswapRouter);
        // Mint tokens for liquidity to this contract (these tokens will later be paired on the DEX)
        _mint(address(this), liquidityThreshold);
        scaledSupply = scaledLiquidityThreshold;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // INTERNAL HELPERS
    // ─────────────────────────────────────────────────────────────────────────────
    /// @dev Uses binary search to determine the maximum additional supply that can be bought
    ///      with the remaining collateral capacity.
    function _getMaxAdditionalSupply(uint256 remainingCollateral) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = MAX_SALE_SUPPLY; // upper bound (in “scaled” units)
        while (low < high) {
            uint256 mid = (low + high + 1) / 2;
            uint256 costForMid = calculateCost(mid);
            if (costForMid <= remainingCollateral) {
                low = mid;
            } else {
                high = mid - 1;
            }
        }
        return low;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // CORE FUNCTIONS
    // ─────────────────────────────────────────────────────────────────────────────
    /// @notice Purchase bonding tokens by paying the required collateral token amount.
    /// The buyer must have approved the contract to spend at least the totalCost.
    function buyTokens(uint256 _amount) public nonReentrant {
        require(_amount > 0, "0 amount");
        require(!bondingCurveCompleted, "Bonding curve complete");

        uint256 cost = calculateCost(_amount);
        uint256 tax = (cost * tradeTax) / tradeTaxDivisor;
        uint256 totalCost = cost + tax;

        // Pull the collateral tokens from the buyer.
        COLLATERAL_TOKEN.safeTransferFrom(msg.sender, address(this), totalCost);

        // If this purchase would exceed the collateral cap, adjust the amount.
        if (totalCollateralCollected + cost >= TOTAL_COLLATERAL) {
            bondingCurveCompleted = true;
            uint256 remaining = TOTAL_COLLATERAL - totalCollateralCollected;
            uint256 maxAdditional = _getMaxAdditionalSupply(remaining);
            // Recompute cost and tax for the allowed additional supply.
            cost = calculateCost(maxAdditional);
            tax = (cost * tradeTax) / tradeTaxDivisor;
            totalCost = cost + tax;
            _amount = maxAdditional;
            // (Note: This implementation assumes the buyer sends exactly the required amount.)
        }

        // Pay the tax portion.
        payTax(tax);
        totalCollateralCollected += cost;
        scaledSupply += _amount;

        // Mint the bonding tokens to the buyer (scaled by 1e18).
        _mint(msg.sender, _amount * 1e18);

        uint256 totalSup = totalSupply();
        uint256 lastPrice = calculateCost(1);
        emit TokensBought(_amount, cost, address(this), msg.sender, totalSup);
        emit Price(lastPrice, totalSup, address(this), _amount);

        if (bondingCurveCompleted) {
            sendToDex();
        }
    }

    /// @notice Computes the cost (in collateral tokens) to buy a given “scaled” amount.
    function calculateCost(uint256 amount) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply + amount;
        // The cost is based on the cubic integration difference:
        // cost = ((((A * (newSupply^3 - currentSupply^3)) * 1e5) / (3 * SCALE)) * 40000) / 77500;
        uint256 cost = ((((A * ((newSupply ** 3) - (currentSupply ** 3))) * 1e5) / (3 * SCALE)) * 40000) / 77500;
        return cost;
    }

    /// @dev Transfers the tax (in collateral tokens) to the revenue collector.
    function payTax(uint256 _tax) internal {
        COLLATERAL_TOKEN.safeTransfer(revenueCollector, _tax);
        totalRevenueCollected += _tax;
    }

    /// @notice Once the bonding curve is complete the contract adds liquidity to the DEX.
    /// It pairs the liquidity tokens (minted in the constructor) with the collateral tokens.
    function sendToDex() public {
        require(bondingCurveCompleted, "Bonding curve not complete");
        // First, take the DEX fee.
        payTax(SEND_DEX_REVENUE);
        totalCollateralCollected -= SEND_DEX_REVENUE;

        uint256 _tokenAmount = liquidityThreshold;
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uint256 collateralAmount = totalCollateralCollected;
        COLLATERAL_TOKEN.approve(address(uniswapV2Router), collateralAmount);

        // Add liquidity pairing this token with the collateral token.
        uniswapV2Router.addLiquidity(
            address(this),
            COLLATERAL_TOKEN_ADDRESS,
            _tokenAmount,
            collateralAmount,
            0,
            0,
            address(0),
            block.timestamp + 1000
        );

        console.log("Collateral balance after liquidity:", COLLATERAL_TOKEN.balanceOf(address(this)));
        emit SentToDex(collateralAmount, _tokenAmount, block.timestamp);
    }

    /// @notice Sell bonding tokens in exchange for collateral tokens.
    /// The seller must have enough bonding tokens.
    function sellTokens(uint256 _amount, uint256 _minimumCollateralRequired) public nonReentrant {
        require(!bondingCurveCompleted, "Bonding curve complete");

        uint256 refund = calculateRefund(_amount);
        uint256 tax = (refund * tradeTax) / tradeTaxDivisor;
        uint256 netRefund = refund - tax;
        require(COLLATERAL_TOKEN.balanceOf(address(this)) >= netRefund, "Low collateral");
        require(balanceOf(msg.sender) >= _amount * 1e18, "Insufficient tokens");
        require(netRefund >= _minimumCollateralRequired, "Refund below minimum");

        payTax(tax);
        _burn(msg.sender, _amount * 1e18);
        totalCollateralCollected -= (netRefund + tax);
        scaledSupply -= _amount;

        COLLATERAL_TOKEN.safeTransfer(msg.sender, netRefund);

        uint256 totalSup = totalSupply();
        uint256 lastPrice = calculateCost(1);
        emit TokensSold(_amount, refund, address(this), msg.sender, totalSup);
        emit Price(lastPrice, totalSup, address(this), _amount);
    }

    /// @notice Computes the refund (in collateral tokens) when selling a given amount.
    function calculateRefund(uint256 _amount) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply - _amount;
        uint256 refund = ((((A * ((currentSupply ** 3) - (newSupply ** 3))) * 1e5) / (3 * SCALE)) * 40000) / 77500;
        return refund;
    }

    /// @dev Overrides the ERC20 hook to restrict transfers until the bonding curve is complete.
    function _update(address from, address to, uint256 value) internal override {
        if (bondingCurveCompleted) {
            super._update(from, to, value);
        } else {
            if (from == address(this) || from == address(0)) {
                super._update(from, to, value);
            } else if (to == address(this) || to == address(0)) {
                super._update(from, to, value);
            } else {
                revert("No transfer allowed during bonding phase");
            }
        }
    }

    /// @notice Returns the remaining “scaled” tokens available for sale.
    function remainingTokens() public view returns (uint256) {
        return MAX_SALE_SUPPLY - scaledSupply;
    }
}
