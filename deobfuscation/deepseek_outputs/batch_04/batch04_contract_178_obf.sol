```solidity
pragma solidity ^0.4.18;

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
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface Token {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function burn(uint256 value) public;
}

contract VestingContract is Ownable {
    using SafeMath for uint256;
    
    Token public token;
    address public beneficiary;
    uint256 public startTime;
    uint256 public cliff;
    uint256 public duration;
    uint256 public period;
    uint256 public percent;
    uint256 public totalVested;
    uint256 public withdrawn;
    
    function VestingContract(Token _token, uint256 _cliff, uint256 _duration, uint256 _percent, address _beneficiary) public {
        token = _token;
        beneficiary = _beneficiary;
        cliff = _cliff;
        duration = _duration;
        percent = _percent;
        period = duration.div(100000);
    }
    
    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(this);
    }
    
    function startVesting() public onlyOwner {
        assert(token.balanceOf(this) > 0);
        totalVested = token.balanceOf(this);
        startTime = block.timestamp;
    }
    
    function available() public view returns (uint256) {
        if (block.timestamp < startTime.add(cliff)) {
            return 0;
        }
        
        uint256 elapsedPeriods = block.timestamp.sub(startTime).div(period).add(1);
        uint256 totalAvailable = totalVested.mul(percent).mul(elapsedPeriods).div(100000);
        
        if (totalAvailable > totalVested) {
            totalAvailable = totalVested;
        }
        
        return totalAvailable.sub(withdrawn);
    }
    
    function withdraw() public {
        assert(msg.sender == beneficiary || msg.sender == owner);
        uint256 amount = available();
        assert(amount > 0);
        token.transfer(beneficiary, amount);
        withdrawn = withdrawn.add(amount);
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;
    
    Token public token;
    VestingContract public vestingContract;
    uint256 public totalRaised;
    
    function Crowdsale(Token _token, VestingContract _vestingContract) public {
        token = _token;
        vestingContract = _vestingContract;
    }
    
    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(this);
    }
    
    function withdrawTokens() public onlyOwner returns (uint256) {
        uint256 amount = token.balanceOf(this);
        token.burn(amount);
        return amount;
    }
    
    function price() public view returns (uint256) {
        return vestingContract.price();
    }
    
    function priceWithBonus() public view returns (uint256) {
        return vestingContract.priceWithBonus();
    }
    
    function() public payable {
        uint256 tokens = msg.value.mul(1 ether).div(priceWithBonus());
        assert(token.balanceOf(this) > tokens);
        token.transfer(msg.sender, tokens);
        totalRaised = totalRaised.add(msg.value);
    }
    
    function buyTokens(address beneficiary, uint256 tokens) public onlyOwner {
        assert(token.balanceOf(this) > tokens);
        token.transfer(beneficiary, tokens);
        totalRaised = totalRaised.add(tokens.mul(priceWithBonus()).div(1 ether));
    }
    
    function withdrawFunds() public onlyOwner returns (bool) {
        return vestingContract.withdrawFunds();
    }
}

contract TokenSale is Ownable {
    using SafeMath for uint256;
    
    Token public token;
    Crowdsale public crowdsale;
    address public coldWallet;
    address public hotWallet;
    bool public isStarted;
    bool public isStopped;
    uint256 public price;
    uint256 public priceWithBonus;
    uint256 public totalSold;
    uint256 public totalRaised;
    
    function setToken(Token _token) public onlyOwner {
        token = _token;
    }
    
    function emergencyStop() public onlyOwner {
        assert(isStarted);
        assert(!isStopped);
        token.approve(address(0), 0);
        
        uint256 remainingTokens = crowdsale.withdrawTokens();
        token.burn(remainingTokens);
        
        uint256 teamTokens = token.totalSupply().div(5);
        uint256 advisorsTokens = token.totalSupply().div(2);
        uint256 partnersTokens = token.totalSupply().sub(teamTokens).sub(advisorsTokens);
        
        coldWallet = new VestingContract(token, 360 days, 31104000, 50000, address(0xC041CB562e4C398710dF38eAED539b943641f7b1));
        token.transfer(coldWallet, teamTokens);
        coldWallet.startVesting();
        
        hotWallet = new VestingContract(token, 180 days, 15552000, 16667, address(0x2ABfE4e1809659ab60eB0053cC799b316afCc556));
        token.transfer(hotWallet, advisorsTokens);
        hotWallet.startVesting();
        
        token.transfer(address(0xd6496BBd13ae8C4Bdeea68799F678a1456B62f23), partnersTokens);
        
        isStarted = false;
        isStopped = true;
    }
    
    function startSale() public onlyOwner {
        assert(!isStarted);
        assert(!isStopped);
        crowdsale = new Crowdsale(this, token);
        token.transfer(crowdsale, token.totalSupply().mul(500000000).div(1000000000));
        isStarted = true;
    }
    
    function totalSupply() public view returns (uint256) {
        return token.totalSupply();
    }
    
    function getPrice() public view returns (uint256) {
        return price;
    }
    
    function setPrice(uint256 _price) public onlyOwner {
        assert(_price > 0);
        price = _price * (10 ** 12);
    }
    
    function getPriceWithBonus() public view returns (uint256) {
        return priceWithBonus;
    }
    
    function setPriceWithBonus(uint256 _priceWithBonus) public onlyOwner {
        assert(_priceWithBonus > 0);
        assert(price > 0);
        priceWithBonus = _priceWithBonus * (10 ** 12);
    }
    
    function() public payable {
    }
    
    function setColdWallet(address _coldWallet) public onlyOwner {
        coldWallet = _coldWallet;
    }
    
    function withdraw() public onlyOwner returns (bool) {
        if (crowdsale.balance > 0) {
            crowdsale.withdrawFunds();
        }
        return coldWallet.send(this.balance);
    }
    
    function buyTokens(address beneficiary, uint256 tokens) public onlyOwner {
        crowdsale.buyTokens(beneficiary, tokens * (10 ** 12));
    }
    
    function approve(address spender, bool approved) public onlyOwner {
        token.approve(spender, approved);
    }
    
    function sendEther(address beneficiary, uint256 amount) public onlyOwner returns(bool) {
        if (crowdsale.balance > 0) {
            crowdsale.withdraw();
        }
        assert(crowdsale.balance + this.balance >= amount);
        return beneficiary.send(amount);
    }
}
```