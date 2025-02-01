pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Interfaces/IUniswapV2Router02.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "forge-std/console.sol";

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

contract SuperMemeCommunityLock is ERC20, ReentrancyGuard {
    event SentToDex(uint256 ethAmount, uint256 tokenAmount, uint256 timestamp);
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
    uint256 public MAX_SALE_SUPPLY = 1e9; // 1 billion tokens
    uint256 public constant TOTAL_ETHER = 4 ether;
    uint256 public constant SCALE = 1e18; // Scaling factor
    uint256 public constant A = 234375; // Calculated constant A
    uint256 liquidityThreshold = 200_000_000 * 10 ** 18;
    uint256 public constant scaledLiquidityThreshold = 200_000_000;

    uint256 private constant tradeTax = 1000;
    uint256 private constant tradeTaxDivisor = 100000;

    uint256 public totalEtherCollected;
    uint256 public scaledSupply;

    address public devAddress;

    bool public bondingCurveCompleted;

    address public revenueCollector;
    uint256 public totalRevenueCollected;
    uint256 public sendDexRevenue = 0.15 ether;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;

    address public factoryContract;

    bool public communityLocked = true; // Initially locked
    mapping(address => bool) public hasVotedToUnlock; // Track whether an address has voted
    uint256 public totalVotes; // Total votes to unlock selling

    constructor(
        string memory _name,
        string memory _symbol,
        address _devAdress,
        address _revenueCollector
    ) public payable ERC20(_name, _symbol) {
        factoryContract = msg.sender;
        revenueCollector = _revenueCollector;
        uniswapV2Router = IUniswapV2Router02(
            0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        );
        _mint(address(this), liquidityThreshold);
        scaledSupply = scaledLiquidityThreshold;
        devAddress = _devAdress;
    }
    function Vote() public {
        require(balanceOf(msg.sender) > 0, "No tokens held");
        uint256 scaledVotingSupply = totalSupply() - liquidityThreshold;
        if (!hasVotedToUnlock[msg.sender]) {
            // Voting to unlock selling
            require(communityLocked, "Selling is already unlocked");
            // Add vote for unlocking
            hasVotedToUnlock[msg.sender] = true;
            totalVotes += balanceOf(msg.sender);
            // Check if more than 50% of supply has voted to unlock
            if (totalVotes * 2 >= scaledVotingSupply) {
                communityLocked = false; // Unlock selling
            }
        } else {
            // Voting to lock selling again
            require(!communityLocked, "Selling is already locked");
            require(hasVotedToUnlock[msg.sender], "No vote to lock");

            // Subtract vote when user votes to lock
            hasVotedToUnlock[msg.sender] = false;
            totalVotes -= balanceOf(msg.sender);

            // Check if less than 50% of supply is voting to unlock
            if (totalVotes * 2 < scaledVotingSupply) {
                communityLocked = true; // Lock selling again
            }
        }
    }

    //check if the address has voted to unlock selling
    function getHasVotedToUnlock(address _address) public view returns (bool) {
        return hasVotedToUnlock[_address];
    }
    //check the percentage of votes to unlock selling
    function percentageVotesToUnlock() public view returns (uint256) {
        uint256 scaledVotingSupply = totalSupply() - liquidityThreshold;
        return (totalVotes * 100) / scaledVotingSupply;
    }

    function getVotingPowerPercentage(
        address _address
    ) public view returns (uint256) {
        uint256 scaledVotingSupply = totalSupply() - liquidityThreshold;
        return balanceOf(_address) / scaledVotingSupply;
    }

    function buyTokens(
        uint256 _amount,
        uint256 _slippage,
        uint256 _buyEth
    ) public payable nonReentrant {
        require(_amount > 0, "0 amount");
        require(!bondingCurveCompleted, "Curve done");
        uint256 cost = calculateCost(_amount);
        uint256 tax = (cost * tradeTax) / tradeTaxDivisor;
        uint256 totalCost = cost + tax;
        uint256 slippageAmount = (totalCost * _slippage) / 10000;
        uint256 minimumCost = totalCost - slippageAmount;
        require(minimumCost <= msg.value, "Insufficient funds");
        require(
            _buyEth >= minimumCost && _buyEth <= totalCost + slippageAmount,
            "Slippage"
        );
        payTax(tax);
        uint256 excessEth = (_buyEth > totalCost) ? _buyEth - totalCost : 0;
        totalEtherCollected += cost;
        address buyer = (msg.sender == factoryContract)
            ? devAddress
            : msg.sender;
        scaledSupply += _amount;
        _mint(buyer, _amount * 10 ** 18);
        if (scaledSupply >= MAX_SALE_SUPPLY) {
            bondingCurveCompleted = true;
        }

        if (excessEth > 0) {
            payable(buyer).transfer(excessEth);
        }
        if (hasVotedToUnlock[buyer]) {
            totalVotes += _amount;
        }
        uint256 totalSup = totalSupply();
        uint256 lastPrice = calculateCost(1);

        emit tokensBought(_amount, cost, address(this), buyer, totalSup);
        emit Price(lastPrice, totalSup, address(this), _amount);

        if (bondingCurveCompleted) {
            sendToDex();
        }
    }
    function calculateCost(uint256 amount) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply + amount;
        uint256 cost = ((((A * ((newSupply ** 3) - (currentSupply ** 3))) *
            10 ** 5) / (3 * SCALE)) * 40000) / 77500;
        return cost;
    }
    function payTax(uint256 _tax) internal {
        (bool success, ) = revenueCollector.call{value: _tax, gas: 100000}("");
        require(success, "Transfer failed");
        totalRevenueCollected += _tax;
    }

    function sendToDex() public payable {
        require(bondingCurveCompleted, "Curve not done");
        payTax(sendDexRevenue);

        totalEtherCollected -= sendDexRevenue;
        uint256 _ethAmount = totalEtherCollected;
        uint256 _tokenAmount = liquidityThreshold;
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
        emit SentToDex(_ethAmount, _tokenAmount, block.timestamp);
    }

    function sellTokens(
        uint256 _amount,
        uint256 _minimumEthRequired
    ) public nonReentrant {
        require(!communityLocked, "Community locked");
        require(!bondingCurveCompleted, "Curve done");

        uint256 refund = calculateRefund(_amount);
        uint256 tax = (refund * tradeTax) / tradeTaxDivisor;
        uint256 netRefund = refund - tax;

        require(address(this).balance >= netRefund, "Low ETH");
        require(balanceOf(msg.sender) >= _amount * 10 ** 18, "Low tokens");
        require(netRefund >= _minimumEthRequired, "Low refund");
        payTax(tax);
        _burn(msg.sender, _amount * 10 ** 18);
        totalEtherCollected -= netRefund + tax;
        if (hasVotedToUnlock[msg.sender]) {
            totalVotes -= _amount;
        }
        scaledSupply -= _amount;

        payable(msg.sender).transfer(netRefund);

        uint256 totalSup = totalSupply();
        uint256 lastPrice = calculateCost(1);
        emit tokensSold(_amount, refund, address(this), msg.sender, totalSup);
        emit Price(lastPrice, totalSup, address(this), _amount);
    }

    function calculateRefund(uint256 _amount) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply - _amount;
        uint256 refund = ((((A * ((currentSupply ** 3) - (newSupply ** 3))) *
            10 ** 5) / (3 * SCALE)) * 40000) / 77500;
        return refund;
    }
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20) {
        if (bondingCurveCompleted && !communityLocked) {
            super._update(from, to, value);
            if (hasVotedToUnlock[from]) {
                totalVotes -= value; // Reduce the sender's voting power
            }
            if (hasVotedToUnlock[to]) {
                totalVotes += value; // Increase the recipient's voting power
            }
        } else if (bondingCurveCompleted && communityLocked) {
            if (from == address(this) && (balanceOf(to) != 0)) {
                super._update(from, to, value);
                return;
            }
            if (
                from == address(uniswapV2Router) ||
                to == address(uniswapV2Router)
            ) {
                revert("Locked");
            }
        } else {
            if (from == address(this) || from == address(0)) {
                super._update(from, to, value);
                if (hasVotedToUnlock[from]) {
                    totalVotes -= value; // Reduce the sender's voting power
                }
                if (hasVotedToUnlock[to]) {
                    totalVotes += value; // Increase the recipient's voting power
                }
            } else if (to == address(this) || to == address(0)) {
                super._update(from, to, value);
                if (hasVotedToUnlock[from]) {
                    totalVotes -= value; // Reduce the sender's voting power
                }
                if (hasVotedToUnlock[to]) {
                    totalVotes += value; // Increase the recipient's voting power
                }
            } else {
                revert("No transfer");
            }
        }
    }
}
