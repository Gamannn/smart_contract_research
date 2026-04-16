```solidity
pragma solidity >=0.4.10;

interface Token {
    function balanceOf(address owner) external returns(uint);
    function transfer(address to, uint value) external returns(bool);
}

contract Crowdsale {
    address public owner;
    address public newOwnerCandidate;
    string public name;
    uint public startTime;
    uint public endTime;
    uint public hardCap;
    bool public isActive;
    
    event StartSale();
    event EndSale();
    event EtherIn(address sender, uint amount);
    
    function Crowdsale() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function () payable {
        require(block.timestamp >= startTime);
        
        if (block.timestamp > endTime || this.balance > hardCap) {
            require(!isActive);
            isActive = false;
            EndSale();
        }
        
        if (!isActive) {
            isActive = true;
            StartSale();
        }
        
        EtherIn(msg.sender, msg.value);
    }
    
    function configureSale(uint _startTime, uint _endTime, uint _hardCap) onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
        hardCap = _hardCap;
    }
    
    function setEndTime(uint _endTime) onlyOwner {
        require(_endTime >= block.timestamp && _endTime >= startTime && _endTime <= endTime);
        endTime = _endTime;
    }
    
    function transferOwnership(address candidate) onlyOwner {
        newOwnerCandidate = candidate;
    }
    
    function acceptOwnership() {
        require(msg.sender == newOwnerCandidate);
        owner = msg.sender;
        newOwnerCandidate = address(0);
    }
    
    function setName(string _name) onlyOwner {
        name = _name;
    }
    
    function withdrawAll() onlyOwner {
        msg.sender.transfer(this.balance);
    }
    
    function withdrawAmount(uint amount) onlyOwner {
        require(amount <= this.balance);
        msg.sender.transfer(amount);
    }
    
    function withdrawToken(address tokenAddress) onlyOwner {
        Token token = Token(tokenAddress);
        require(token.transfer(msg.sender, token.balanceOf(this)));
    }
    
    function transferToken(address tokenAddress, address to, uint value) onlyOwner {
        Token token = Token(tokenAddress);
        require(token.transfer(to, value));
    }
}
```