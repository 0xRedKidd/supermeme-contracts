// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

//import ownable
import "@openzeppelin/contracts/access/Ownable.sol";

contract LeaderboardClaim is Ownable {
    constructor() Ownable(msg.sender) {}

    mapping(address => uint256) public claimableAmounts;

    event EtherReceived(address indexed from, uint256 amount);
    event Distributed(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    function distribute(
        address[] calldata users,
        uint256[] calldata amounts
    ) external payable onlyOwner {
        require(
            users.length == amounts.length,
            "User list and amounts must match"
        );
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < users.length; i++) {
            claimableAmounts[users[i]] += amounts[i];
        }
    }

    function claim() external {
        uint256 amount = claimableAmounts[msg.sender];
        require(amount > 0, "No Ether to claim");
        claimableAmounts[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Claimed(msg.sender, amount);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
