pragma solidity ^0.4.24;

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

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract TokenAirdrop is Ownable {
    using SafeMath for uint256;

    ERC20 public tokenReward;
    uint256 public totalAirdropTokens;
    address public collectorAddress;
    mapping(address => uint256) public airdropBalances;

    event FundTransfer(address backer, uint256 amount, bool isContribution);
    event AdditionalTokens(uint256 amount);
    event BurnTokens(uint256 amount);
    event CollectAirdropTokenBack(address collector, uint256 amount);

    constructor(address _tokenReward, address _collectorAddress) public {
        totalAirdropTokens = 2e7;
        tokenReward = ERC20(_tokenReward);
        collectorAddress = _collectorAddress;
    }

    function() payable public {
        require(totalAirdropTokens > 0);
        require(airdropBalances[msg.sender] == 0);

        uint256 amount = getCurrentCandyAmount();
        require(amount > 0);

        totalAirdropTokens = totalAirdropTokens.sub(amount);
        airdropBalances[msg.sender] = amount;
        tokenReward.transfer(msg.sender, amount * 1e18);

        emit FundTransfer(msg.sender, amount, true);
    }

    function getCurrentCandyAmount() private view returns (uint256) {
        if (totalAirdropTokens >= 10e6) {
            return 200;
        } else if (totalAirdropTokens >= 2.5e6) {
            return 150;
        } else if (totalAirdropTokens >= 0.5e6) {
            return 100;
        } else if (totalAirdropTokens >= 50) {
            return 50;
        } else {
            return 0;
        }
    }

    function addAdditionalTokens(uint256 amount) public onlyOwner {
        require(amount > 0);
        totalAirdropTokens = totalAirdropTokens.add(amount);
        emit AdditionalTokens(amount);
    }

    function burnTokens(uint256 amount) public onlyOwner {
        require(amount > 0);
        totalAirdropTokens = totalAirdropTokens.sub(amount);
        emit BurnTokens(amount);
    }

    function setCollectorAddress(address _collectorAddress) public onlyOwner returns (bool) {
        collectorAddress = _collectorAddress;
        return true;
    }

    function collectAirdropTokensBack(uint256 amount) public onlyOwner {
        require(totalAirdropTokens > 0);
        require(collectorAddress != address(0));
        require(amount > 0);

        tokenReward.transfer(collectorAddress, amount * 1e18);
        totalAirdropTokens = 0;

        emit CollectAirdropTokenBack(collectorAddress, amount);
    }

    function collectEther() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        require(collectorAddress != address(0));

        collectorAddress.transfer(balance);
    }

    function getTokenBalance(address tokenAddress, address account) view public returns (uint256) {
        ERC20 token = ERC20(tokenAddress);
        return token.balanceOf(account);
    }

    function transferTokens(address tokenAddress) public onlyOwner returns (bool) {
        ERC20 token = ERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        return token.transfer(collectorAddress, balance);
    }
}