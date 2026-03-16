pragma solidity 0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IToken {
    function mint(uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(uint256 amount) external returns (bool);
    function transferFrom(address from, uint256 amount) external returns (bool);
}

interface IRegistry {
    function getOwner() external returns(address);
    function register(string name, address owner) external returns (address);
    function resolve(string name) external view returns (address);
}

contract TokenManager {
    using SafeMath for uint256;

    IRegistry private registry;

    constructor(address registryAddress) public {
        require(registryAddress != address(0));
        registry = IRegistry(registryAddress);
    }

    function calculateTokenAmount(uint256 value) public view returns (uint256) {
        return value.mul(config.tokenConversionRate);
    }

    function calculateFee(uint256 value) public view returns (uint256) {
        return value.div(config.tokenConversionRate);
    }

    function deposit() public payable returns (bool) {
        IToken token = IToken(registry.resolve("AccessToken"));
        require(token.approve(calculateTokenAmount(msg.value)));
        return true;
    }

    function withdraw(uint256 amount) public returns (bool) {
        IToken token = IToken(registry.resolve("AccessToken"));
        require(token.transferFrom(msg.sender, amount));
        msg.sender.transfer(calculateFee(amount));
        return true;
    }

    struct Config {
        uint256 tokenConversionRate;
        uint8 decimals;
    }

    Config config = Config(1000, 1);
}