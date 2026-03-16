pragma solidity ^0.4.23;

contract Ownable {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
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

contract InvestmentContract is Ownable {
    using SafeMath for uint256;

    event onPurchase(address indexed buyer, uint256 amount, uint256 contractBalance, uint256 fee, uint timestamp);
    event onWithdraw(address indexed withdrawer, uint256 amount, uint256 contractBalance, uint timestamp);

    mapping(address => uint256) internal balances;
    mapping(address => uint256) internal investments;

    struct ContractData {
        uint256 totalSupply;
        uint256 totalInvested;
        uint256 feePercentage;
        uint256 minInvestment;
        address owner;
    }

    ContractData public contractData = ContractData(
        10e21 * 10e21,
        10e21,
        2,
        0.001 ether,
        address(0)
    );

    function() external payable {
        invest();
    }

    function invest() public payable {
        address investor = msg.sender;
        require(msg.value >= contractData.minInvestment, "Minimum investment not met");

        uint256 fee = msg.value.mul(contractData.feePercentage).div(100);
        uint256 netInvestment = msg.value.sub(fee);

        if (netInvestment != 0) {
            uint256 newTotalInvested = contractData.totalInvested.add(netInvestment);
            contractData.totalInvested = newTotalInvested;
        }

        investments[investor] = investments[investor].add(msg.value).sub(fee);
        balances[investor] = contractData.totalSupply.div(contractData.totalInvested);

        emit onPurchase(investor, msg.value, address(this).balance, fee, now);
    }

    function withdraw(uint256 amount) public {
        address investor = msg.sender;
        require(amount > 0, "Cannot withdraw zero amount");
        require(amount <= investments[investor], "Insufficient balance");

        investor.transfer(amount);
        investments[investor] = investments[investor].sub(amount);
        balances[investor] = contractData.totalSupply.div(contractData.totalInvested);

        emit onWithdraw(investor, amount, address(this).balance, now);
    }

    function withdrawAll() public {
        address investor = msg.sender;
        uint256 amount = investments[investor];
        require(amount > 0, "No balance to withdraw");

        investor.transfer(amount);
        investments[investor] = 0;
        balances[investor] = contractData.totalSupply.div(contractData.totalInvested);

        emit onWithdraw(investor, amount, address(this).balance, now);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor].mul(balances[investor]).mul(contractData.totalInvested).div(contractData.totalSupply);
    }
}