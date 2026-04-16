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
    function transfer(address to, uint tokens) external;
    function balanceOf(address tokenOwner) external returns (uint balance);
}

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

contract TokenSale is Owned {
    using SafeMath for uint;

    uint public tokenPrice;
    address public tokenAddress;
    address public developer;
    address public company;
    address public marketing;
    uint public saleStart;
    uint public saleEnd;
    uint public phaseOneEnd;
    uint public phaseTwoEnd;
    uint public phaseThreeEnd;

    event TokensBought(address indexed buyer, uint amount);
    event TokensCalledBack(uint amount);
    event PrivateSaleEnded(uint timestamp);

    constructor() public {
        saleStart = now + 3 days;
        phaseOneEnd = now + 6 days;
        phaseTwoEnd = phaseOneEnd + 29 days;
        phaseThreeEnd = phaseTwoEnd + 29 days;
        tokenAddress = 0x215c6e1FaFa372E16CfD3cA7D223fc7856018793;
        developer = 0x49BAf97cc2DF6491407AE91a752e6198BC109339;
        company = 0x36e8A1C0360B733d6a4ce57a721Ccf702d4008dE;
        marketing = 0x4DbADf088EEBc22e9A679f4036877B1F7Ce71e4f;
    }

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

        Token(tokenAddress).transfer(msg.sender, tokens);
        emit TokensBought(msg.sender, tokens);
    }

    function endSale() public onlyOwner {
        require(now >= phaseThreeEnd);

        uint balance = Token(tokenAddress).balanceOf(address(this));
        uint developerShare = balance.mul(5).div(100);
        uint companyShare = balance.mul(5).div(100);
        uint marketingShare = balance.mul(5).div(100);
        uint ownerShare = balance.mul(85).div(100);

        Token(tokenAddress).transfer(developer, developerShare);
        Token(tokenAddress).transfer(marketing, marketingShare);
        Token(tokenAddress).transfer(company, companyShare);
        Token(tokenAddress).transfer(owner, ownerShare);

        emit PrivateSaleEnded(now);
    }

    function withdrawTokens() public onlyOwner {
        require(now >= phaseThreeEnd);

        uint balance = Token(tokenAddress).balanceOf(address(this));
        Token(tokenAddress).transfer(owner, balance);

        emit TokensCalledBack(balance);
    }
}