```solidity
pragma solidity 0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function mint(uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
}

interface IRegistry {
    function getOwner() external returns(address);
    function createContract(string name, address owner) external returns (address);
    function getContract(string name) external view returns (address);
}

contract PaymentProcessor {
    using SafeMath for uint256;
    
    IRegistry private registry;
    
    struct FeeConfig {
        uint256 feeRate;
        uint8 feeDecimals;
    }
    
    FeeConfig public feeConfig = FeeConfig(1000, 1);
    
    constructor(address registryAddress) public {
        require(registryAddress != address(0));
        registry = IRegistry(registryAddress);
    }
    
    function calculateFee(uint256 amount) public view returns (uint256) {
        return amount.mul(feeConfig.feeRate);
    }
    
    function calculateNetAmount(uint256 amount) public view returns (uint256) {
        return amount.div(feeConfig.feeRate);
    }
    
    function processPayment() public payable returns (bool) {
        IERC20 accessToken = IERC20(registry.getContract("AccessToken"));
        require(accessToken.mint(calculateFee(msg.value)));
        return true;
    }
    
    function withdrawTokens(uint256 amount) public returns (bool) {
        IERC20 accessToken = IERC20(registry.getContract("AccessToken"));
        require(accessToken.burnFrom(msg.sender, amount));
        msg.sender.transfer(calculateNetAmount(amount));
        return true;
    }
}
```