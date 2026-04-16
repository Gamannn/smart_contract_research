```solidity
pragma solidity ^0.4.16;

interface Token {
    function transfer(address to, uint amount) public;
}

contract MultiAdmin {
    address public admin1;
    address public admin2;
    address public admin3;
    
    function MultiAdmin(address _admin1, address _admin2, address _admin3) public {
        admin1 = _admin1;
        admin2 = _admin2;
        admin3 = _admin3;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3);
        _;
    }
    
    function changeAdmin(address _newAdmin) onlyAdmin public {
        require(_newAdmin != admin1);
        require(_newAdmin != admin2);
        require(_newAdmin != admin3);
        
        if (admin1 == msg.sender) {
            admin1 = _newAdmin;
        } else if (admin2 == msg.sender) {
            admin2 = _newAdmin;
        } else if (admin3 == msg.sender) {
            admin3 = _newAdmin;
        }
    }
}

contract Presale is MultiAdmin {
    uint public duration;
    uint public hardCap;
    uint public bonusPercent;
    uint public tokensPerEther;
    uint public startTime;
    address public tokenAddress;
    address public beneficiary;
    uint public raised;
    mapping(address => uint) public investments;
    
    modifier duringSale() {
        require(startTime <= now);
        require((startTime + duration) > now);
        _;
    }
    
    modifier underHardCap() {
        require(raised < hardCap);
        _;
    }
    
    event Investing(address investor, uint invested, uint tokensWithoutBonus, uint tokensWithBonus);
    event Raise(address beneficiary, uint amount);
    
    function Presale(
        address _tokenAddress,
        address _admin1,
        address _admin2,
        address _admin3
    ) MultiAdmin(_admin1, _admin2, _admin3) public {
        hardCap = 1000 ether;
        bonusPercent = 50;
        duration = 61 days;
        tokensPerEther = 400;
        tokenAddress = _tokenAddress;
        beneficiary = address(this);
        startTime = 1526342400;
    }
    
    function() duringSale underHardCap payable public {
        uint tokenAmountWithoutBonus = msg.value * tokensPerEther;
        uint tokenAmountWithBonus = tokenAmountWithoutBonus + (tokenAmountWithoutBonus * bonusPercent / 100);
        
        Token(tokenAddress).transfer(msg.sender, tokenAmountWithBonus);
        raised += msg.value;
        investments[msg.sender] += msg.value;
        
        Investing(msg.sender, msg.value, tokenAmountWithoutBonus, tokenAmountWithBonus);
    }
    
    function setBeneficiary(address _beneficiary) public onlyAdmin {
        beneficiary = _beneficiary;
    }
    
    function withdraw(uint amount) public onlyAdmin {
        require(beneficiary != 0x0);
        require(amount <= this.balance);
        
        Raise(beneficiary, amount);
        beneficiary.send(amount);
    }
}
```