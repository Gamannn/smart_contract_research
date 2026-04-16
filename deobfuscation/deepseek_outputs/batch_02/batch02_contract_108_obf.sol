```solidity
pragma solidity ^0.4.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface Token {
    function transfer(address to, uint value) external;
    function balanceOf(address owner) external returns(uint);
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}

contract PrivateSale is Ownable {
    using SafeMath for uint;
    
    uint public totalRaised;
    address public companyWallet;
    address public developerWallet;
    address public marketingWallet;
    address public kellyWallet;
    
    Token public token;
    
    uint public phaseOneEnd;
    uint public phaseTwoEnd;
    uint public phaseThreeEnd;
    
    constructor() public {
        phaseOneEnd = now + 3 days;
        phaseTwoEnd = now + 6 days;
        phaseThreeEnd = now + 29 days;
        
        token = Token(0x4446B2551d7aCdD1f606Ef3Eed9a9af913AE3e51);
        companyWallet = 0x215c6e1FaFa372E16CfD3cA7D223fc7856018793;
        developerWallet = 0x49BAf97cc2DF6491407AE91a752e6198BC109339;
        marketingWallet = 0x36e8A1C0360B733d6a4ce57a721Ccf702d4008dE;
        kellyWallet = 0x4DbADf088EEBc22e9A679f4036877B1F7Ce71e4f;
    }
    
    event tokensBought(address indexed buyer, uint amount);
    event tokensCalledBack(uint amount);
    event privateSaleEnded(uint timestamp);
    
    function() public payable {
        require(msg.value >= 0.3 ether);
        require(now < phaseThreeEnd);
        
        uint tokens;
        
        if (now <= phaseOneEnd) {
            tokens = msg.value.mul(6280);
        } else if (now > phaseOneEnd && now <= phaseTwoEnd) {
            tokens = msg.value.mul(6280);
        } else if (now > phaseTwoEnd && now <= phaseThreeEnd) {
            tokens = msg.value.mul(6280);
        }
        
        totalRaised = totalRaised.add(msg.value);
        token.transfer(msg.sender, tokens);
        emit tokensBought(msg.sender, tokens);
    }
    
    function endSale() public onlyOwner {
        require(now >= phaseThreeEnd);
        
        uint balance = address(this).balance;
        uint onePercent = balance.div(100);
        
        uint companyShare = onePercent.mul(5);
        uint marketingShare = onePercent.mul(5);
        uint developerShare = onePercent.mul(5);
        uint kellyShare = onePercent.mul(85);
        
        companyWallet.transfer(companyShare);
        marketingWallet.transfer(marketingShare);
        developerWallet.transfer(developerShare);
        kellyWallet.transfer(kellyShare);
        
        emit privateSaleEnded(now);
    }
    
    function withdrawTokens() public onlyOwner {
        require(now >= phaseThreeEnd);
        
        uint tokenBalance = token.balanceOf(this);
        token.transfer(owner, tokenBalance);
        emit tokensCalledBack(tokenBalance);
    }
}
```