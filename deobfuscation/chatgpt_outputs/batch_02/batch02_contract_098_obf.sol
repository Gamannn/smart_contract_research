```solidity
pragma solidity ^0.4.25;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract TokenSale is Ownable {
    using SafeMath for uint256;

    ERC20 public token;
    ERC20 public stableCoin;

    address public admin = msg.sender;
    mapping(address => uint256) public contributions;
    uint256 public startTime = 1543700145;
    uint256 public endTime = 1547510400;
    uint256 public tokenPrice;
    uint256 public hardCap = 10000000 * 1e18;

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    constructor(ERC20 _token, ERC20 _stableCoin) public {
        token = _token;
        stableCoin = _stableCoin;
        tokenPrice = 1e18 / 100; // Example token price
    }

    function setStartTime(uint256 _startTime) public onlyAdmin {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyAdmin {
        endTime = _endTime;
    }

    function setAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyAdmin {
        tokenPrice = _tokenPrice;
    }

    function isSaleActive() public view returns (bool) {
        return now >= startTime && now <= endTime;
    }

    function () public payable {
        require(stableCoin.transferFrom(msg.sender, address(this), msg.value));
        require(isSaleActive());
        require(msg.value >= tokenPrice.mul(100));

        uint256 tokensToBuy = msg.value.mul(1e18).div(tokenPrice);
        token.transfer(msg.sender, tokensToBuy);

        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
    }

    function distributeTokens(address _to, uint256 _amount) internal {
        uint256 tokens = _amount.mul(1e18).div(tokenPrice);
        token.transfer(_to, tokens);
    }

    function adminDistributeTokens(address _to, uint256 _amount) public onlyAdmin {
        token.transfer(_to, _amount);
    }

    function adminWithdraw(address _to, uint256 _amount) public onlyAdmin {
        _to.transfer(_amount);
    }
}

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
        uint256 c = a / b;
        return c;
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

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
```