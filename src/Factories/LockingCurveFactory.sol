pragma solidity 0.8.20;

import "../SuperMemeLockingCurve.sol";
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
contract LockingCurveFactory is Ownable {
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
        uint256 _amount,
        address _devAddress,
        uint256 _buyEth,
        uint256 _tMax
    ) public payable returns (address token) {
        require(
            (_tMax >= 1 days && _tMax <= 7 days && _tMax % 1 days == 0) || _tMax == 12 hours,
            "Invalid lock duration"
        );
        require(msg.value >= createTokenRevenue, "Insufficient funds");
        require(_devAddress == msg.sender, "Invalid dev address");

        (bool success, ) = revenueCollector.call{
            value: createTokenRevenue,
            gas: 500000
        }("");
        require(success, "Transfer failed");

        if (_amount == 0 && _buyEth == 0) {
            token = address(
                new SuperMemeLockingCurve(
                    _name,
                    _symbol,
                    _amount,
                    _devAddress,
                    revenueCollector,
                    _buyEth,
                    _tMax
                )
            );
        } else if (_amount > 0 && _buyEth > 0) {
            token = address(
                new SuperMemeLockingCurve{value: _buyEth}(
                    _name,
                    _symbol,
                    _amount,
                    _devAddress,
                    revenueCollector,
                    _buyEth,
                    _tMax
                )
            );
        } else {
            revert("Invalid token creation parameters");
        }
        tokenAddresses.push(token);
        superMemeRegistry.registerToken(token, _devAddress, _amount, false, 2);
        emit TokenCreated(token, _devAddress, _amount, false, 2);
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
