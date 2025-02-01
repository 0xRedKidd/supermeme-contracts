pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

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

contract SuperMemeRegistry is Ownable {
    event TokenCreated(
        address indexed tokenAddress,
        address indexed devAddress,
        uint256 amount,
        bool devLocked,
        uint256 tokenType
    );

    address[] public tokenAddresses;

    mapping (address => bool) public isFactory;

    constructor() Ownable(msg.sender) {

    }

    function registerToken(
        address _tokenAddress,
        address _devAddress,
        uint256 _amount,
        bool _devLocked,
        uint256 _tokenType
    ) public onlyFactory {
        tokenAddresses.push(_tokenAddress);
        emit TokenCreated(_tokenAddress, _devAddress, _amount, _devLocked, _tokenType);
    }

    modifier onlyFactory() {
        require(
            isFactory[msg.sender],
            "Only factory can call this function"
        );
        _;
    }

    function setFactory(address _factory) public onlyOwner {
        if (isFactory[_factory]) {
            isFactory[_factory] = false;
            return;
            
        }
        isFactory[_factory] = true;
    }
}