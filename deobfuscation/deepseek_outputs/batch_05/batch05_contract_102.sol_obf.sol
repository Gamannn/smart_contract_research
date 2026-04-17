pragma solidity ^0.4.21;

interface Token {
    function transfer(address receiver, uint amount) external;
}

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
        uint256 c = a / b;
        return c;
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
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenCrowdsale is Ownable {
    using SafeMath for uint256;
    
    uint256 public price;
    Token public tokenReward;
    
    event FundTransfer(address backer, uint amount, bool isContribution);

    constructor(
        uint256 etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        price = etherCostOfEachToken * 150 / 125;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }

    function () payable public {
        require(msg.value != 0);
        uint amount = msg.value;
        tokenReward.transfer(msg.sender, amount.mul(price));
        emit FundTransfer(msg.sender, amount, true);
    }

    function setPrice(uint256 etherCostOfEachToken) onlyOwner public {
        price = etherCostOfEachToken * 150 / 125;
    }

    function withdrawEther(uint256 amount) onlyOwner public {
        uint weiAmount = amount * 10**16;
        owner.transfer(weiAmount);
        emit FundTransfer(owner, weiAmount, false);
    }

    function withdrawTokens(address tokenAddress, uint amount) onlyOwner public {
        Token token = Token(tokenAddress);
        token.transfer(owner, amount);
    }

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}