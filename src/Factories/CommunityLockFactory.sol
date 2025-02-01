pragma solidity 0.8.20;

import "../SuperMemeCommunityLock.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/ISuperMemeRegistry.sol";

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

contract CommunityLockFactory is Ownable {
    event TokenCreated(
        address indexed tokenAddress,
        address indexed devAddress,
        uint256 amount,
        bool devLocked,
        uint256 tokenType
    );

    ISuperMemeRegistry public superMemeRegistry;

    uint256 public createTokenRevenue = 0.0008 ether;
    address public revenueCollector;
    address[] public tokenAddresses;

    constructor(address _superMemeRegistry) Ownable(msg.sender) {
        superMemeRegistry = ISuperMemeRegistry(_superMemeRegistry);
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        address _devAddress
    ) public payable returns (address token) {
        require(msg.value >= createTokenRevenue, "Insufficient funds");
        require(_devAddress == msg.sender, "Invalid dev address");

        (bool success, ) = revenueCollector.call{
            value: createTokenRevenue,
            gas: 500000
        }("");
        require(success, "Transfer failed");
            token = address(
                new SuperMemeCommunityLock(
                    _name,
                    _symbol,
                    _devAddress,
                    revenueCollector
                )
            );
        tokenAddresses.push(token);
        superMemeRegistry.registerToken(token, _devAddress, 0, false, 3);
        emit TokenCreated(token, _devAddress, 0, false, 3);
    }

    function setRevenueCollector(address _revenueCollector) public onlyOwner {
        revenueCollector = _revenueCollector;
    }
    function setCreateTokenRevenue(
        uint256 _createTokenRevenue
    ) public onlyOwner {
        createTokenRevenue = _createTokenRevenue;
    }
    function setSuperMemeRegistry(address _superMemeRegistry) public onlyOwner {
        superMemeRegistry = ISuperMemeRegistry(_superMemeRegistry);
    }
}
