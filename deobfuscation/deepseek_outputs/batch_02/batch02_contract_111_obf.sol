pragma solidity ^0.4.18;

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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

interface Token {
    function transfer(address to, uint256 value) public returns (bool);
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;
    
    uint public startTime = 1512118800;
    uint public endTime = 1517562000;
    uint public tokensSold = 0;
    bool public paused = false;
    
    address public tokenAddress;
    address public wallet1;
    address public wallet2;
    
    mapping(address => bool) public whitelist;
    
    uint public rate = 1000;
    uint public minContribution = 20000;
    uint public hardCap = 860000000;
    uint public minIndividualCap = 20000;
    
    Token token;
    
    function Crowdsale(address _tokenAddress, address _wallet1, address _wallet2) public {
        token = Token(_tokenAddress);
        wallet1 = _wallet1;
        wallet2 = _wallet2;
    }
    
    function buyTokens(address beneficiary) public payable {
        require(msg.value != 0);
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.div(rate);
        _processPurchase(beneficiary, tokens);
    }
    
    function buyTokensDirect(address beneficiary, uint256 tokenAmount) external onlyOwner {
        _processPurchase(beneficiary, tokenAmount);
    }
    
    function _processPurchase(address beneficiary, uint256 tokenAmount) private {
        require(beneficiary != 0x0);
        require(_validPurchase());
        
        if(tokensSold < hardCap.sub(minIndividualCap)) {
            require(tokenAmount >= minIndividualCap);
        }
        
        require(tokenAmount.add(tokensSold) <= hardCap);
        
        tokensSold = tokensSold.add(tokenAmount);
        token.transfer(beneficiary, tokenAmount);
    }
    
    function _validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool notPaused = !paused;
        return withinPeriod && notPaused;
    }
    
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }
    
    function setWhitelist(address beneficiary, bool allowed) external onlyOwner {
        whitelist[beneficiary] = allowed;
    }
    
    function setStartTime(uint _startTime) external onlyOwner {
        startTime = _startTime;
    }
    
    function setEndTime(uint _endTime) external onlyOwner {
        endTime = _endTime;
    }
    
    function withdraw(uint256 amount) external onlyOwner {
        wallet1.transfer(amount / 2);
        wallet2.transfer(amount / 2);
    }
}