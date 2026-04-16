pragma solidity ^0.4.16;

interface TokenInterface {
    function transfer(address to, uint amount) external;
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

    function Ownable() public {
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

contract KeplerTokenCrowdsale is Ownable {
    using SafeMath for uint256;

    uint256 public tokensPerETH;
    TokenInterface public tokenReward;

    function KeplerTokenCrowdsale(uint256 initialTokensPerETH, address tokenAddress) public {
        tokensPerETH = initialTokensPerETH.mul(130).div(125);
        tokenReward = TokenInterface(tokenAddress);
    }

    function () payable public {
        require(msg.value != 0);
        uint256 amount = msg.value;
        tokenReward.transfer(msg.sender, amount.mul(tokensPerETH));
        emit FundTransfer(msg.sender, amount, true);
    }

    function updateTokensPerETH(uint256 newTokensPerETH) public onlyOwner {
        tokensPerETH = newTokensPerETH.mul(130).div(125);
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        uint256 weiAmount = amount.mul(1 ether);
        owner.transfer(weiAmount);
        emit FundTransfer(owner, weiAmount, false);
    }

    function transferTokens(address to, uint256 amount) public onlyOwner {
        TokenInterface token = TokenInterface(to);
        token.transfer(owner, amount);
    }

    function destroyContract() public onlyOwner {
        selfdestruct(owner);
    }

    event FundTransfer(address backer, uint amount, bool isContribution);
}