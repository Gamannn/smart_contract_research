pragma solidity ^0.4.21;

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

contract TokenCrowdsale is Ownable {
    using SafeMath for uint256;

    uint256 public tokensPerETH;
    TokenInterface public tokenReward;
    event FundTransfer(address backer, uint256 amount, bool isContribution);

    function setTokensPerETH(uint256 newTokensPerETH) public onlyOwner {
        tokensPerETH = newTokensPerETH.mul(150).div(125);
    }

    function () payable public {
        require(msg.value != 0);
        uint256 amount = msg.value;
        tokenReward.transfer(msg.sender, amount.mul(tokensPerETH));
        emit FundTransfer(msg.sender, amount, true);
    }

    function updateTokensPerETH(uint256 newTokensPerETH) public onlyOwner {
        tokensPerETH = newTokensPerETH.mul(150).div(125);
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        uint256 weiAmount = amount.mul(10**16);
        owner.transfer(weiAmount);
        emit FundTransfer(owner, weiAmount, false);
    }

    function withdrawTokens(address to, uint256 amount) public onlyOwner {
        tokenReward.transfer(to, amount);
    }

    function destroyContract() public onlyOwner {
        selfdestruct(owner);
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    function getBoolFunc(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }

    uint256[] public _integer_constant = [10, 125, 16, 0, 150];
    bool[] public _bool_constant = [false, true];
}