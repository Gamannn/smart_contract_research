pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct OwnerData {
        address owner;
        address pendingOwner;
    }

    OwnerData private ownerData;

    constructor() public {
        ownerData.owner = msg.sender;
        ownerData.pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == ownerData.owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        ownerData.pendingOwner = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == ownerData.pendingOwner, "Caller is not the pending owner");
        emit OwnershipTransferred(ownerData.owner, msg.sender);
        ownerData.owner = msg.sender;
        ownerData.pendingOwner = address(0);
    }
}

contract Token {
    function balanceOf(address account) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function burn(uint256 value) public returns (bool);
}

contract TokenManager is Ownable {
    using SafeMath for uint256;

    Token public token;
    mapping(address => uint256) public balances;

    constructor(address tokenAddress) public {
        token = Token(tokenAddress);
    }

    function() public {
        require(msg.sender == tx.origin, "Caller is not the transaction origin");
        uint256 tokenBalance = token.balanceOf(msg.sender);
        require(tokenBalance > 0, "Token balance is zero");
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "User balance is zero");
        balances[msg.sender] = 0;
        token.burn(tokenBalance);
        msg.sender.transfer(userBalance);
    }

    function deposit(address user) public onlyOwner payable {
        balances[user] = balances[user].add(msg.value);
    }

    function withdraw(address user) public onlyOwner {
        uint256 userBalance = balances[user];
        require(userBalance > 0, "User balance is zero");
        balances[user] = 0;
        ownerData.owner.transfer(userBalance);
    }

    function transferTokens(address from, address to, uint256 value) public onlyOwner returns (bool) {
        return Token(from).transfer(to, value);
    }

    function transferTokensFrom(address to, uint256 value) public onlyOwner {
        to.transfer(value);
    }
}