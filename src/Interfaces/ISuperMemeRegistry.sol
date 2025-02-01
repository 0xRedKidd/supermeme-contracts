pragma solidity 0.8.20;

interface ISuperMemeRegistry {
    event TokenCreated(
        address indexed tokenAddress,
        address indexed devAddress,
        uint256 amount,
        bool devLocked,
        uint256 tokenType
    );

    function tokenAddresses(uint256 index) external view returns (address);

    function refundableFactory() external view returns (address);

    function degenFactory() external view returns (address);

    function lockingCurveFactory() external view returns (address);

    function registerToken(
        address _tokenAddress,
        address _devAddress,
        uint256 _amount,
        bool _devLocked,
        uint256 _tokenType
    ) external;

    function setRefundableFactory(address _refundableFactory) external;

    function setDegenFactory(address _degenFactory) external;

    function setLockingCurveFactory(address _lockingCurveFactory) external;
}
