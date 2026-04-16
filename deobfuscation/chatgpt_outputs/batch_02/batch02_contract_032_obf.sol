pragma solidity ^0.4.24;

contract TokenInterface {
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function balanceOf(address owner) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract RichestContract {
    address public richest;
    address public owner;
    address public tokenAddress;
    event PackageJoinedViaPAD(address indexed user, uint amount);
    event PackageJoinedViaETH(address indexed user, uint amount);
    mapping (address => uint) public balances;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    TokenInterface public token;
    
    function setTokenAddress(address _tokenAddress) onlyOwner public {
        token = TokenInterface(_tokenAddress);
    }
    
    function withdrawTokens(uint amount) onlyOwner public returns(bool) {
        require(amount <= this.getBalance());
        owner.transfer(amount);
        return true;
    }
    
    function transferTokens(address from, address to, uint amount) onlyOwner public returns(bool) {
        require(amount <= token.balanceOf(from));
        token.transferFrom(from, to, amount);
        return true;
    }
    
    function setTokenPrice(uint256 price) onlyOwner public {
        tokenPrice = price;
    }
    
    function buyTokens() public payable {
        token.transfer(tokenAddress, msg.value);
    }
    
    function reserve() payable public {
        richest = msg.sender;
        highestBid = msg.value;
        owner = richest;
    }
    
    function becomeRichest() payable public returns(bool) {
        require(msg.value > highestBid);
        balances[richest] += msg.value;
        richest = msg.sender;
        highestBid = msg.value;
        return true;
    }
    
    function joinPackageViaETH(uint amount) payable public {
        require(amount >= 0);
        token.transfer(msg.sender, msg.value * 20 / 100);
        emit PackageJoinedViaETH(msg.sender, amount);
    }
    
    function joinPackageViaPAD(uint amount) public {
        require(amount >= 0);
        token.transfer(tokenAddress, msg.value * 20 / 100);
        emit PackageJoinedViaPAD(msg.sender, msg.value);
    }
    
    function getBalance() constant public returns(uint) {
        return this.balance;
    }
    
    function getTokenBalance(address account) constant public returns(uint balance) {
        return token.balanceOf(account);
    }
}