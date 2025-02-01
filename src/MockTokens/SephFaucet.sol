pragma solidity 0.8.20;

contract SephFaucet {

    uint256 public maxDailyTotalWithdrawal = 3 ether;
    uint256 public dailyTotalWithdrawal;
    uint256 public dailyTimestampCheck;
    uint256 public maxWithdrawal = 0.1 ether;
    
    // Track user's daily withdrawals and last withdrawal time
    mapping(address => uint256) public dailyWithdrawals;
    mapping(address => uint256) public lastWithdrawalTime;

    // Receive ether to the contract
    receive() external payable {}

    function drip() public {    
        // Reset daily limits if more than 24 hours has passed since last reset
        if (dailyTimestampCheck + 1 days <= block.timestamp) {
            dailyTotalWithdrawal = 0;
            dailyTimestampCheck = block.timestamp;
        }
        
        // Check global faucet limit
        require(dailyTotalWithdrawal + maxWithdrawal <= maxDailyTotalWithdrawal, "Daily limit reached");
        
        // Check user's last withdrawal time and enforce 24-hour cooldown
        require(block.timestamp - lastWithdrawalTime[msg.sender] >= 1 days, "24 hours not passed yet");
        
        // Check user's individual withdrawal limit for the day
        require(dailyWithdrawals[msg.sender] + maxWithdrawal <= maxWithdrawal, "User limit reached");

        // Update the daily totals for both the user and the global faucet
        dailyTotalWithdrawal += maxWithdrawal;
        dailyWithdrawals[msg.sender] += maxWithdrawal;

        // Update user's last withdrawal time
        lastWithdrawalTime[msg.sender] = block.timestamp;

        // Transfer the amount to the user
        payable(msg.sender).transfer(maxWithdrawal);
    }
}
