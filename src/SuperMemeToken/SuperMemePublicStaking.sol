// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
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
 * @title SuperMemePublicStaking
 * @dev This contract allows users to stake ERC20 tokens to earn rewards, represented as ERC721 NFTs. 
 *      Rewards are distributed based on lock periods and revenue share bonuses.
 */
contract SuperMemePublicStaking is ERC721, ERC721Enumerable, ReentrancyGuard {
    IERC20 public immutable stakingToken; // The ERC20 token used for staking
    uint256 public nextTokenId; // Counter for the next NFT token ID
    
    // Struct to store stake details for each NFT
    struct StakeInfo {
        uint256 amount;            // Amount of tokens staked
        uint256 lockEnd;           // End time of the lock period
        uint256 revenueShareBonus; // Bonus multiplier for revenue shares
        uint256 sharesAmount;      // Amount of shares calculated from the stake
        uint256 rewardIndex;       // Last reward index when rewards were updated
        uint256 earned;            // Total rewards earned by the stake
    }
    
    // Mapping from token ID to its associated stake information
    mapping(uint256 => StakeInfo) public stakeInfo;
    
    // Lock periods and corresponding revenue share bonuses
    uint256 public constant FIFTEEN_DAYS = 15 days;
    uint256 public constant ONE_MONTH = 30 days;
    uint256 public constant THREE_MONTHS = 90 days;
    uint256 public constant SIX_MONTHS = 180 days;

    uint256 public constant FIFTEEN_DAYS_BONUS = 1;
    uint256 public constant ONE_MONTH_BONUS = 2;
    uint256 public constant THREE_MONTHS_BONUS = 4;
    uint256 public constant SIX_MONTHS_BONUS = 8;

    // Reward distribution variables
    uint256 public rewardIndex; // Accumulated reward per token
    uint256 public totalStaked; // Total amount of tokens staked
    uint256 private constant SCALE = 1e18; // Scaling factor for precise calculations

    uint256 totalSharesAmount; // Total shares across all stakes

    // Events to track staking, unstaking, and claiming
    event Staked(address indexed user, uint256 amount, uint256 lockPeriod, uint256 tokenId);
    event Unstaked(address indexed user, uint256 amount, uint256 tokenId);
    event Claimed(address indexed user, uint256 amount);

    /**
     * @dev Constructor initializes the staking token and sets the NFT details.
     * @param _stakingToken Address of the ERC20 token used for staking.
     */
    constructor(address _stakingToken) ERC721("SuperMemeStakeNFT", "SMNFT") {
        stakingToken = IERC20(_stakingToken);
    }

    /**
     * @dev Stake tokens and lock them for a specified period. Mints an NFT representing the stake.
     * @param amount Amount of tokens to stake.
     * @param lockPeriod Lock duration (must match one of the predefined periods).
     * @return tokenId The ID of the minted NFT.
     */
    function stake(uint256 amount, uint256 lockPeriod) external nonReentrant returns (uint256) {
        require(amount > 500 ether, "Stake amount must be greater than zero");
        require(
            lockPeriod == FIFTEEN_DAYS ||
            lockPeriod == ONE_MONTH ||
            lockPeriod == THREE_MONTHS ||
            lockPeriod == SIX_MONTHS,
            "Invalid lock period"
        );

        uint256 revenueShareBonus = 1;
        if (lockPeriod == FIFTEEN_DAYS) {
            revenueShareBonus = FIFTEEN_DAYS_BONUS;
        } else if (lockPeriod == ONE_MONTH) {
            revenueShareBonus = ONE_MONTH_BONUS;
        } else if (lockPeriod == THREE_MONTHS) {
            revenueShareBonus = THREE_MONTHS_BONUS;
        } else if (lockPeriod == SIX_MONTHS) {
            revenueShareBonus = SIX_MONTHS_BONUS;
        }

        // Transfer staking tokens from the user to the contract
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        

        uint256 receivedShares = amount * revenueShareBonus;
        totalSharesAmount += receivedShares;
        totalStaked += amount;

        // Mint an NFT representing this stake
        uint256 tokenId = nextTokenId++;
        _mint(msg.sender, tokenId);

        // Record stake details
        stakeInfo[tokenId] = StakeInfo({
            amount: amount,
            lockEnd: block.timestamp + lockPeriod,
            revenueShareBonus: revenueShareBonus,
            sharesAmount: receivedShares,
            rewardIndex: rewardIndex,
            earned: 0
        });

        _updateRewards(tokenId);

        emit Staked(msg.sender, amount, lockPeriod, tokenId);
        return tokenId;
    }

    /**
     * @dev Unstake tokens and burn the corresponding NFT. Rewards are claimed automatically.
     * @param tokenId The ID of the NFT representing the stake.
     */
    function unstake(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this stake");

        StakeInfo memory stakeMem = stakeInfo[tokenId];
        require(block.timestamp >= stakeMem.lockEnd, "Lock period not over");

        claimReward(tokenId);

        totalSharesAmount -= stakeMem.sharesAmount;
        totalStaked -= stakeMem.amount;

        _burn(tokenId);
        delete stakeInfo[tokenId];

        stakingToken.transfer(msg.sender, stakeMem.amount);
        emit Unstaked(msg.sender, stakeMem.amount, tokenId);
    }

    /**
     * @dev Add rewards to the contract and update the reward index.
     */
    function collectRevenue() nonReentrant external payable {
        require(totalStaked > 0, "No staked tokens");
        uint256 amount = msg.value;
        rewardIndex += (amount * SCALE) / totalSharesAmount;
    }

    /**
     * @dev Claim rewards for a specific NFT.
     * @param _tokenId The ID of the NFT representing the stake.
     * @return reward The amount of rewards claimed.
     */
    function claimReward(uint256 _tokenId) public nonReentrant returns (uint256) {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of this stake");

        StakeInfo storage stake = stakeInfo[_tokenId];
        _updateRewards(_tokenId);
        uint256 reward = stake.earned;

        if (reward > 0) {
            stake.earned = 0;
            payable(msg.sender).transfer(reward);
        }

        emit Claimed(msg.sender, reward);
        return reward;
    }

    /**
     * @dev Internal function to update the rewards for a specific NFT.
     */
    function _updateRewards(uint256 _tokenId) private {
        StakeInfo storage stake = stakeInfo[_tokenId];
        stake.earned += _calculateRewards(_tokenId);
        stake.rewardIndex = rewardIndex;
    }

    /**
     * @dev Calculate the pending rewards for a specific NFT.
     * @param _tokenId The ID of the NFT representing the stake.
     * @return The calculated reward amount.
     */
    function _calculateRewards(uint256 _tokenId)  public view returns (uint256) {
        StakeInfo memory stake = stakeInfo[_tokenId];
        uint256 shares = stake.sharesAmount;
        return (shares * (rewardIndex - stake.rewardIndex)) / SCALE;
    }

    // Override functions to handle enumerable behavior
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Get the stake details for a specific NFT.
     * @param tokenId The ID of the NFT representing the stake.
     * @return The StakeInfo struct associated with the token ID.
     */
    function getStakeInfo(uint256 tokenId)
        external
        view
        returns (StakeInfo memory)
    {
        return stakeInfo[tokenId];
    }
}
