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
    ERC20 public whitelist;
    address public wallet;
    mapping(address => uint256) public contributions;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public rate;
    uint256 public minContribution;
    uint256 public hardCap;
    uint256 public weiRaised;

    modifier onlyWhileOpen() {
        require(now >= startTime && now <= endTime);
        _;
    }

    constructor(
        address _token,
        address _whitelist,
        address _wallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _minContribution,
        uint256 _hardCap
    ) public {
        token = ERC20(_token);
        whitelist = ERC20(_whitelist);
        wallet = _wallet;
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        minContribution = _minContribution;
        hardCap = _hardCap;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    function setWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function isOpen() public view returns (bool) {
        return now >= startTime && now <= endTime;
    }

    function () public payable {
        require(whitelist.balanceOf(msg.sender) > 0);
        require(isOpen());
        require(msg.value >= minContribution);

        uint256 tokens = msg.value.mul(rate);
        token.transfer(msg.sender, tokens);

        weiRaised = weiRaised.add(msg.value);
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);

        wallet.transfer(msg.value);
    }

    function transferEthFromContract(address _to, uint256 _amount) public onlyOwner {
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
    function balanceOf(address who) external view returns (uint256);
}