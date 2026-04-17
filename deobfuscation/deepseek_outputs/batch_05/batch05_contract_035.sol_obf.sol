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

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

interface ERC20Token {
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract Airdrop is Ownable {
    using SafeMath for uint256;

    ERC20Token public tokenRewardContract;
    uint256 public totalAirDropToken;
    address public collectorAddress;
    mapping(address => uint256) public balanceOf;

    event FundTransfer(address backer, uint256 amount, bool isContribution);
    event Additional(uint amount);
    event Burn(uint amount);
    event CollectAirDropTokenBack(address collector, uint256 amount);

    constructor(
        address tokenAddress,
        address collector
    ) public {
        totalAirDropToken = 2e7;
        tokenRewardContract = ERC20Token(tokenAddress);
        collectorAddress = collector;
        owner = msg.sender;
    }

    function() payable public {
        require(totalAirDropToken > 0);
        require(balanceOf[msg.sender] == 0);
        uint256 amount = getCurrentCandyAmount();
        require(amount > 0);
        totalAirDropToken = totalAirDropToken.sub(amount);
        balanceOf[msg.sender] = amount;
        tokenRewardContract.transfer(msg.sender, amount * 1e18);
        emit FundTransfer(msg.sender, amount, true);
    }

    function getCurrentCandyAmount() private view returns (uint256 amount) {
        if (totalAirDropToken >= 10e6) {
            return 200;
        } else if (totalAirDropToken >= 2.5e6) {
            return 150;
        } else if (totalAirDropToken >= 0.5e6) {
            return 100;
        } else if (totalAirDropToken >= 50) {
            return 50;
        } else {
            return 0;
        }
    }

    function addToken(uint256 amount) public onlyOwner {
        require(amount > 0);
        totalAirDropToken = totalAirDropToken.add(amount);
        emit Additional(amount);
    }

    function burnToken(uint256 amount) public onlyOwner {
        require(amount > 0);
        totalAirDropToken = totalAirDropToken.sub(amount);
        emit Burn(amount);
    }

    function modifyCollectorAddress(address newCollector) public onlyOwner returns (bool) {
        collectorAddress = newCollector;
        return true;
    }

    function collectAirDropTokenBack(uint256 airDropToken) public onlyOwner {
        require(totalAirDropToken > 0);
        require(collectorAddress != address(0));
        if (airDropToken > 0) {
            tokenRewardContract.transfer(collectorAddress, airDropToken * 1e18);
            totalAirDropToken = totalAirDropToken.sub(airDropToken);
        } else {
            tokenRewardContract.transfer(collectorAddress, totalAirDropToken * 1e18);
            totalAirDropToken = 0;
        }
        emit CollectAirDropTokenBack(collectorAddress, airDropToken);
    }

    function collectEther() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        require(collectorAddress != address(0));
        collectorAddress.transfer(balance);
    }

    function getTokenBalance(address tokenAddress, address who) view public returns (uint) {
        ERC20Token token = ERC20Token(tokenAddress);
        return token.balanceOf(who);
    }

    function withdrawTokens(address tokenAddress) onlyOwner public returns (bool) {
        ERC20Token token = ERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        return token.transfer(collectorAddress, balance);
    }
}