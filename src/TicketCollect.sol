pragma solidity 0.8.20;

//import ownable
import "@openzeppelin/contracts/access/Ownable.sol";


contract TicketCollect is Ownable {

    address public revenueCollector;
    uint256 public totalRevenueCollected;

    constructor(address _revenueCollector) Ownable(msg.sender) {
        revenueCollector = _revenueCollector;
    }

    uint256 public ticketPrice = 0.00034 ether;

    function buyTicket(uint256 _amount) public payable returns (bool) {
        require(msg.value == ticketPrice * _amount, "Incorrect amount sent");
        payTax(msg.value);
        return true;
    }

    function payTax(uint256 _tax) internal {
        (bool success, ) = revenueCollector.call{value: _tax, gas: 50000}("");
        require(success, "Transfer failed");
        totalRevenueCollected += _tax;
    }

    function setTicketPrice(uint256 _price) public onlyOwner {
        ticketPrice = _price;
    }

    function setRevenueCollector(address _revenueCollector) public onlyOwner {
        revenueCollector = _revenueCollector;
    }


}

