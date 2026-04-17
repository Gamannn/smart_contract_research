pragma solidity ^0.4.16;

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

contract Token {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public;
}

contract Admined {
    address public admin;
    
    event TransferAdminship(address newAdmin);
    event Admined(address admin);
    
    constructor(address _admin) public {
        admin = _admin;
        emit Admined(_admin);
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    function transferAdminship(address newAdmin) onlyAdmin public {
        require(newAdmin != address(0));
        admin = newAdmin;
        emit TransferAdminship(admin);
    }
}

contract Crowdsale is Admined {
    using SafeMath for uint256;
    
    uint256 public startTime = now;
    uint256 public price;
    Token public token;
    address public ethWallet;
    string public campaign;
    address public owner;
    uint256 public minContribution;
    
    event TokenBought(address buyer, uint256 amount);
    event TokenWithdrawal(address to, uint256 amount);
    event PayOut(address to, uint256 amount);
    
    constructor(
        address _ethWallet,
        string _campaign
    ) public Admined(msg.sender) {
        token = Token(0x3a26746Ddb79B1B8e4450e3F4FFE3285A307387E);
        owner = msg.sender;
        ethWallet = _ethWallet;
        campaign = _campaign;
        price = 1000000000000000;
        minContribution = 0;
    }
    
    function withdrawTokens(address to) onlyAdmin public {
        require(to != address(0));
        require(token.balanceOf(this) > 0);
        
        uint256 balance = token.balanceOf(this);
        token.transfer(to, balance);
        emit TokenWithdrawal(to, balance);
    }
    
    function withdrawEther() onlyAdmin public {
        require(this.balance > 0);
        uint256 balance = this.balance;
        minContribution = 0;
        require(ethWallet.send(balance));
        emit PayOut(ethWallet, balance);
    }
    
    function () public payable {
        require(msg.value >= minContribution);
        uint256 tokenAmount = msg.value.div(price);
        require(token.balanceOf(this) >= tokenAmount);
        token.transfer(msg.sender, tokenAmount);
        emit TokenBought(msg.sender, tokenAmount);
    }
}