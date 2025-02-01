// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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


/**
 * @title SuperMemeTreasuryVesting
 * @dev A contract for vesting funds and managing rewards for different roles in the ecosystem. 
 *      It handles vesting schedules, reward distribution, and staking functionality.
 */
contract SuperMemeTreasuryVesting is Ownable, ReentrancyGuard {

    IERC20 public immutable stakingToken; // The ERC20 token used for vesting and rewards
    // Balances and rewards
    mapping(address => uint256) public balance; // Current balance of tokens staked by an address
    mapping(address => uint256) public lastUnstakeTime; // Last unstake time of an address
    uint256 public totalSupply; // Total tokens staked in the contract

    uint256 private constant SCALE = 1e18; // Scaling factor for precise calculations
    uint256 private rewardIndex; // Accumulated reward index
    mapping(address => uint256) private rewardIndexOf; // Reward index for each address
    mapping(address => uint256) private earned; // Rewards earned by each address

    uint256 public allTimeRevenueCollected; // Total revenue collected by the contract
    uint256 public allTimeRewardsDistributed; // Total rewards distributed

    // Lock periods for different roles
    uint256[2] public teamLocks = [365 days, 730 days];
    uint256[2] public treasuryLocks = [365 days, 730 days];
    uint256[2] public developmentLocks = [30 days, 730 days];
    uint256[2] public marketingLocks = [30 days, 730 days];
    uint256[2] public airdropLocks = [30 days, 30 days];

    // Predefined roles and their vesting details
    address public constant TEAM = 0xFFFf2A9e9A7E8B738e3a18538CFFbc101A397419;
    address public constant TREASURY = 0xA902fFcC625D8DcAcaf08d00F96B32c5d6A6ebe7;
    address public constant DEVELOPMENT = 0xdCb265A5Ce660611Bc1DA882d8A42733d88C1323;
    address public constant MARKETING = 0xbd7784D02c6590e68fEd3098E354e7cbD232adC4;
    address public constant LIQUIDITY = 0x6F72B3530271bE8ae09CeE65d05836E9720Df880;
    address public constant AIRDROP = 0x538c08af3e3cD67eeb4FB45970D3520F58537Ba4;
    address public constant ADVISOR = 0x84dC3E5eC35A358742bf6fb2461104856439EA6C;

    // Vesting amounts for roles
    uint256 public constant TREASURY_AMOUNT = 200_000_000 ether;
    uint256 public constant DEVELOPMENT_AMOUNT = 80_000_000 ether;
    uint256 public constant MARKETING_AMOUNT = 90_000_000 ether;
    uint256 public constant LIQUIDITY_AMOUNT = 72_000_000 ether;
    uint256 public constant AIRDROP_AMOUNT = 30_000_000 ether;
    uint256 public constant TEAM_AMOUNT = 150_000_000 ether;


    // Vesting schedules for advisors and roles
    mapping(address => Vesting) public advisorVestingSchedule; // Vesting schedules for advisors
    mapping(address => Vesting) public vestingSchedule; // Vesting schedules for predefined roles
    mapping(address => uint256) public totalUnlockedAndClaimed; // Total unlocked and claimed tokens for each address

    address[] public advisors; // List of advisors with vesting schedules

    uint256 public tgeDate; // Token generation event date

    // Vesting struct
    struct Vesting {
        uint256 cliffEnd; // End of the cliff period
        uint256 vestingEnd; // End of the vesting period
        uint256 totalAmount; // Total amount of tokens to vest
    }

    /**
     * @dev Constructor initializes the staking token and TGE date, and sets up vesting schedules.
     * @param _stakingToken The ERC20 token used for staking and vesting.
     * @param _tgeDate The date of the token generation event.
     */
    constructor(address _stakingToken, uint256 _tgeDate) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        tgeDate = _tgeDate;
        initializeVestingSchedules();
    }

    // --- External/Public Functions ---

    /**
     * @dev Add an advisor with a custom vesting schedule.
     * @param advisor The address of the advisor.
     * @param amount The total amount to vest for the advisor.
     * @param _cliffDuration The duration of the cliff period.
     * @param _vestingDuration The duration of the vesting period.
     */
    function addAdvisor(
        address advisor,
        uint256 amount,
        uint256 _cliffDuration,
        uint256 _vestingDuration
    ) external {
        require(msg.sender == ADVISOR, "Only advisory can add another advisor");
        require(advisorVestingSchedule[advisor].vestingEnd == 0, "Advisor already added");
        require(_vestingDuration > 0, "Invalid vesting duration");

        // Initialize advisor vesting schedule
        advisors.push(advisor);
        advisorVestingSchedule[advisor] = Vesting(
            tgeDate + _cliffDuration,
            tgeDate + _cliffDuration + _vestingDuration,
            amount
        );

        _updateRewards(advisor);
        balance[advisor] += amount;
        totalSupply += amount;
        totalUnlockedAndClaimed[advisor] = 0;

        // Transfer tokens from the sender to the contract
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
    }

    /**
     * @dev Collect revenue to distribute as rewards.
     */
    function collectRevenue() external payable {
        uint256 reward = msg.value;
        if (totalSupply == 0) {
            return;
        }
        rewardIndex += (reward * SCALE) / totalSupply;
        allTimeRevenueCollected += reward;
    }

    /**
     * @dev Stake tokens into the vesting contract.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external {
        require(isEligibleForVesting(msg.sender), "Not eligible for vesting");
        Vesting memory vesting = getVestingSchedule(msg.sender);
        require(vesting.totalAmount == amount, "Amount does not match vesting amount");

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        _updateRewards(msg.sender);

        balance[msg.sender] += amount;
        totalSupply += amount;
        totalUnlockedAndClaimed[msg.sender] = 0;
    }



    /**
     * @dev Unstake tokens after the cliff period and vesting unlock.
     */
    function unstake() external nonReentrant {
        require(balance[msg.sender] > 0, "Not staked yet");
        uint256 amount = getUnlockedAmount(msg.sender);
        require(block.timestamp > getCliffEnd(msg.sender), "Cliff period not reached");
        require(amount > 0, "No unlocked amount");
        claim();
        stakingToken.transfer(msg.sender, amount);

        balance[msg.sender] -= amount;
        totalSupply -= amount;
        totalUnlockedAndClaimed[msg.sender] += amount;
    }

    /**
     * @dev Claim earned rewards.
     * @return reward The amount of rewards claimed.
     */
    function claim() public returns (uint256) {
        require(balance[msg.sender] > 0, "Not staked yet :)");
        _updateRewards(msg.sender);
        uint256 reward = earned[msg.sender];

        if (reward > 0) {
            earned[msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: reward, gas: 1000000}("");
            require(success, "Transfer failed");
            allTimeRewardsDistributed += reward;
        }
        return reward;
    }

    /**
     * @dev Calculate the rewards earned by an address.
     * @param account The address to calculate rewards for.
     * @return The total rewards earned.
     */
    function calculateRewardsEarned(address account) external view returns (uint256) {
        return earned[account] + _calculateRewards(account);
    }

    /**
     * @dev Get the unlocked amount for an account.
     * @param account The account to query.
     * @return The unlocked amount.
     */
    function getUnlockedAmount(address account) public view returns (uint256) {
        Vesting memory vesting = getVestingSchedule(account);
        if (block.timestamp < vesting.cliffEnd) {
            return 0;
        } else if (block.timestamp >= vesting.vestingEnd) {
            return balance[account];
        } else {
            uint256 vestingDuration = vesting.vestingEnd - vesting.cliffEnd;
            uint256 timeVested = block.timestamp - vesting.cliffEnd;
            return ((vesting.totalAmount * timeVested) / vestingDuration) - totalUnlockedAndClaimed[account];
        }
    }

    /**
     * @dev Initialize vesting schedules for predefined roles.
     */
    function initializeVestingSchedules() internal {
        vestingSchedule[TEAM] = Vesting(tgeDate + teamLocks[0], tgeDate + teamLocks[1] + teamLocks[0], TEAM_AMOUNT);
        vestingSchedule[TREASURY] = Vesting(tgeDate + treasuryLocks[0], tgeDate + treasuryLocks[1] + treasuryLocks[0], TREASURY_AMOUNT);
        vestingSchedule[DEVELOPMENT] = Vesting(tgeDate + developmentLocks[0], tgeDate + developmentLocks[1] + developmentLocks[0], DEVELOPMENT_AMOUNT);
        vestingSchedule[MARKETING] = Vesting(tgeDate + marketingLocks[0], tgeDate + marketingLocks[1]+ marketingLocks[0], MARKETING_AMOUNT);
        vestingSchedule[AIRDROP] = Vesting(tgeDate + airdropLocks[0], tgeDate + airdropLocks[1] +airdropLocks[0], AIRDROP_AMOUNT);
    }

    // --- Internal Functions ---

    function _calculateRewards(address account) private view returns (uint256) {
        uint256 shares = balance[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / SCALE;
    }

    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }

    function isEligibleForVesting(address account) internal view returns (bool) {
        return account == TEAM || account == TREASURY || account == DEVELOPMENT || account == MARKETING || account == AIRDROP || advisorVestingSchedule[account].vestingEnd > 0;
    }

    function getVestingSchedule(address account) internal view returns (Vesting memory) {
        if (advisorVestingSchedule[account].vestingEnd > 0) {
            return advisorVestingSchedule[account];
        } else {
            return vestingSchedule[account];
        }
    }

    function getCliffEnd(address account) internal view returns (uint256) {
        return getVestingSchedule(account).cliffEnd;
    }
}
