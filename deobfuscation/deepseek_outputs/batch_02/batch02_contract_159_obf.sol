pragma solidity ^0.4.18;

interface Token {
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function balanceOf(address who) public constant returns (uint256 balance);
}

contract Crowdsale {
    address public admin;
    bool public active;
    address public token;
    uint256 public expirationTime;
    uint256 public exchangeRate;
    
    event TokenClaim(address indexed token, address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event Redemption(address indexed redeemer, uint256 ethAmount, uint256 tokenAmount);
    
    modifier onlyActive() {
        require(active);
        require(now < expirationTime);
        _;
    }
    
    modifier onlyInactive() {
        require(!active);
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    function Crowdsale(address _admin, address _token, uint256 _expirationTime, uint256 _exchangeRate) public {
        admin = _admin;
        token = _token;
        expirationTime = _expirationTime;
        exchangeRate = _exchangeRate;
        active = true;
    }
    
    function () public payable onlyActive {
        uint256 tokenAmount = msg.value * exchangeRate;
        require(Token(token).transfer(msg.sender, tokenAmount));
        checkStatus();
        TokenClaim(token, msg.sender, msg.value, tokenAmount);
    }
    
    function redeem(uint256 tokenAmount) public onlyActive {
        require(Token(token).transferFrom(msg.sender, this, tokenAmount));
        uint256 ethAmount = tokenAmount / exchangeRate;
        msg.sender.transfer(ethAmount);
        Redemption(msg.sender, ethAmount, tokenAmount);
    }
    
    function checkStatus() public {
        if (now > expirationTime) {
            active = false;
        }
        uint256 tokenSupply = Token(token).balanceOf(this);
        if (tokenSupply < exchangeRate) {
            active = false;
        }
    }
    
    function withdraw(uint256 amount) public onlyInactive onlyAdmin {
        msg.sender.transfer(amount);
        Redemption(msg.sender, 0, amount);
    }
    
    function withdrawTokens(uint256 tokenAmount) public onlyInactive onlyAdmin {
        require(Token(token).transfer(msg.sender, tokenAmount));
        TokenClaim(token, msg.sender, 0, tokenAmount);
    }
    
    function withdrawOtherTokens(address otherToken, uint256 tokenAmount) public onlyInactive onlyAdmin {
        require(Token(otherToken).transfer(msg.sender, tokenAmount));
        TokenClaim(otherToken, msg.sender, 0, tokenAmount);
    }
}