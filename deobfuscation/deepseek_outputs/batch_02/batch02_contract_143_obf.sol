pragma solidity ^0.4.25;

interface IExternalContract {
    function() payable external;
    function deposit(address beneficiary) external payable;
    function withdraw() external;
    function getBalance() external view returns(uint256);
    function claimRewards() external;
    function transferTo(address recipient, uint256 amount) external payable;
    function approve(address spender) external;
    function reinvest() external;
    function setSniper(address sniper) external;
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

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

contract MainContract is Ownable {
    using SafeMath for uint;

    IExternalContract constant externalContract = IExternalContract(0x31cF8B6E8bB6cB16F23889F902be86775bB1d0B3);
    
    uint256 public contractBalance;
    address public sniper;

    function getContractBalance() view public returns(uint256) {
        return contractBalance;
    }

    function getExternalBalance() view public returns(uint256) {
        return externalContract.getBalance();
    }

    function deposit() public payable {
        contractBalance = contractBalance.add(msg.value);
    }

    function snipe(address target, uint256 amount) public {
        require(contractBalance > amount.mul(100000000000000000));
        contractBalance = contractBalance.sub(amount.mul(0.1 ether));
        externalContract.transferTo.value(amount.mul(100000000000000000))(target, amount);
    }

    function setSniperAddress() public {
        externalContract.setSniper(address(this));
    }

    function claim() public {
        externalContract.claimRewards();
    }

    function withdrawProfit() onlyOwner public {
        uint256 profit = address(this).balance.sub(contractBalance);
        msg.sender.transfer(profit);
    }

    function() external payable {}
}