pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero address");
        pendingOwner = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner, "Not pending owner");
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }
}

interface Token {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function withdraw(uint256 value) public returns(bool);
}

contract Vault is Ownable {
    using SafeMath for uint256;

    Token public token;
    mapping (address => uint256) public deposits;

    constructor(address tokenAddress) public {
        token = Token(tokenAddress);
    }

    function () public {
        require(msg.sender == tx.origin, "Not EOA");
        uint256 tokenBalance = token.balanceOf(msg.sender);
        require(tokenBalance > 0, "No token balance");
        uint256 depositAmount = deposits[msg.sender];
        require(depositAmount > 0, "No deposit");
        deposits[msg.sender] = 0;
        token.withdraw(tokenBalance);
        msg.sender.transfer(depositAmount);
    }

    function deposit(address beneficiary) public onlyOwner payable {
        deposits[beneficiary] = deposits[beneficiary].add(msg.value);
    }

    function refund(address beneficiary) public onlyOwner {
        uint256 amount = deposits[beneficiary];
        require(amount > 0, "No deposit");
        deposits[beneficiary] = 0;
        owner.transfer(amount);
    }

    function transferToken(address tokenAddress, address to, uint256 value) public onlyOwner returns (bool) {
        return Token(tokenAddress).transfer(to, value);
    }

    function transferEth(address to, uint256 value) public onlyOwner {
        to.transfer(value);
    }
}