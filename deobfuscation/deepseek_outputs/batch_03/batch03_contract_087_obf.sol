pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract CrowdsaleBase {
    using SafeMath for uint256;
    
    uint256 public startTime;
    uint256 public endTime;
    uint256 public rate;
    address public wallet;
    
    function CrowdsaleBase(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != 0x0);
        
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = 0x00b95a5d838f02b12b75be562abf7ee0100410922b;
    }
    
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }
    
    function validPurchaseAmount(uint256 amount) internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = amount != 0;
        return withinPeriod && nonZeroPurchase;
    }
    
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }
}

contract CappedCrowdsale is CrowdsaleBase {
    using SafeMath for uint256;
    
    uint256 public cap;
    
    function CappedCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap) 
        public 
        CrowdsaleBase(_startTime, _endTime, _rate, _wallet) 
    {
        require(_cap > 0);
        cap = _cap;
    }
    
    function validPurchase() internal constant returns (bool) {
        bool withinCap = totalRaised.add(msg.value) <= cap;
        return super.validPurchase() && withinCap;
    }
    
    function validPurchaseAmount(uint256 amount) internal constant returns (bool) {
        bool withinCap = totalRaised.add(amount) <= cap;
        return super.validPurchaseAmount(amount) && withinCap;
    }
    
    function hasEnded() public constant returns (bool) {
        bool capReached = totalRaised >= cap;
        return super.hasEnded() || capReached;
    }
}

interface Token {
    function mint(address to, uint256 amount, string txHash) public returns (bool);
}

contract FinalizableCrowdsale is CappedCrowdsale, Ownable {
    using SafeMath for uint256;
    
    address public tokenAddress;
    uint256 public minimumContribution;
    
    function FinalizableCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        uint256 _cap,
        uint256 _minimumContribution
    ) 
        public 
        CappedCrowdsale(_startTime, _endTime, _rate, _wallet, _cap) 
    {
        tokenAddress = 0x00f5b36df8732fb5a045bd90ab40082ab37897b841;
        minimumContribution = _minimumContribution;
    }
    
    function() payable public {}
    
    function buyTokens(string txHash) public payable {
        require(!stringsEqual(txHash, ""));
        require(validPurchase());
        require(msg.value >= minimumContribution);
        
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);
        
        Token token = Token(tokenAddress);
        token.mint(msg.sender, tokens, txHash);
        
        totalRaised = totalRaised.add(weiAmount);
        forwardFunds();
    }
    
    function mintTokens(address beneficiary, uint256 weiAmount, string txHash) onlyOwner public {
        require(!stringsEqual(txHash, ""));
        require(validPurchaseAmount(weiAmount));
        require(weiAmount >= minimumContribution);
        
        uint256 tokens = weiAmount.mul(rate);
        
        Token token = Token(tokenAddress);
        token.mint(beneficiary, tokens, txHash);
        
        totalRaised = totalRaised.add(weiAmount);
    }
    
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
    
    function stringsEqual(string a, string b) internal pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }
    
    function changeWallet(address newWallet) onlyOwner public {
        wallet = newWallet;
    }
    
    function destroy() onlyOwner public {
        selfdestruct(wallet);
    }
    
    uint256 public totalRaised;
}