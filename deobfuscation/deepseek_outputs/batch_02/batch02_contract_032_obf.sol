pragma solidity ^0.4.24;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenGame {
    address public richest;
    address public owner;
    address public tokenAddress;
    
    IERC20 public token;
    
    event PackageJoinedViaPAD(address participant, uint amount);
    event PackageJoinedViaETH(address participant, uint amount);
    
    mapping(address => uint) public balances;
    
    uint256 public tokenPrice;
    uint256 public highestBid;
    address public highestBidder;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        richest = msg.sender;
    }
    
    function setTokenContract(address _tokenAddress) onlyOwner public {
        token = IERC20(_tokenAddress);
        tokenAddress = _tokenAddress;
    }
    
    function withdrawTokens(uint amount) onlyOwner public returns(bool) {
        require(amount <= token.balanceOf(address(this)));
        token.transfer(owner, amount);
        return true;
    }
    
    function transferTokensFrom(address from, address to, uint amount) onlyOwner public returns(bool) {
        require(amount <= token.allowance(from, address(this)));
        token.transferFrom(from, to, amount);
        return true;
    }
    
    function setTokenPrice(uint256 price) onlyOwner public {
        tokenPrice = price;
    }
    
    function buyTokens() public payable {
        token.transfer(msg.sender, msg.value);
    }
    
    function bid() payable public {
        require(msg.value > highestBid);
        balances[highestBidder] += msg.value;
        highestBidder = msg.sender;
        highestBid = msg.value;
        richest = msg.sender;
    }
    
    function joinPackageWithETH(uint packageId) payable public {
        require(packageId >= 0);
        token.transfer(msg.sender, msg.value * 20 / 100);
        emit PackageJoinedViaETH(msg.sender, msg.value);
    }
    
    function joinPackageWithPAD(uint packageId) public {
        require(packageId >= 0);
        token.transferFrom(msg.sender, tokenAddress, msg.value * 20 / 100);
        emit PackageJoinedViaPAD(msg.sender, msg.value);
    }
    
    function getContractBalance() constant public returns(uint) {
        return token.balanceOf(address(this));
    }
    
    function getUserBalance(address user) constant public returns(uint balance) {
        return token.balanceOf(user);
    }
}