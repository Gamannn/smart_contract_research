pragma solidity ^0.4.23;

contract Ownable {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

contract InvestmentContract is Ownable {
    using SafeMath for uint256;

    event onPurchase(
        address indexed investor,
        uint256 amount,
        uint256 contractBalance,
        uint256 fee,
        uint timestamp
    );

    event onWithdraw(
        address indexed investor,
        uint256 amount,
        uint256 contractBalance,
        uint timestamp
    );

    mapping(address => uint256) internal sharePriceSnapshot;
    mapping(address => uint256) internal investedAmount;

    function() external payable {
        invest();
    }

    function invest() public payable {
        address investor = msg.sender;
        require(
            msg.value >= minInvestment,
            "should be more the 0.0001 ether sent"
        );

        uint256 contractBalance = getContractBalance().sub(msg.value);
        uint256 fee;

        if (contractBalance != 0) {
            fee = msg.value.mul(feePercent).div(100);
            uint256 shareIncrease = totalShares.mul(fee) / contractBalance;
            totalShares = totalShares.add(shareIncrease);
        }

        investedAmount[investor] = getInvestmentValue(investor)
            .add(msg.value)
            .sub(fee);

        sharePriceSnapshot[investor] = totalSupply / totalShares;

        emit onPurchase(
            investor,
            msg.value,
            getContractBalance(),
            fee,
            now
        );
    }

    function withdraw(uint256 amount) public {
        address investor = msg.sender;
        require(amount > 0, "user cant spam transactions with 0 value");
        require(
            amount <= getInvestmentValue(investor),
            "user cant withdraw more then he holds"
        );

        investor.transfer(amount);
        investedAmount[investor] = getInvestmentValue(investor).sub(amount);
        sharePriceSnapshot[investor] = totalSupply / totalShares;

        emit onWithdraw(
            investor,
            amount,
            getContractBalance(),
            now
        );
    }

    function withdrawAll() public {
        address investor = msg.sender;
        uint256 amount = getInvestmentValue(investor);
        require(amount > 0, "user cant call withdraw, when holds nothing");

        investor.transfer(amount);
        investedAmount[investor] = 0;
        sharePriceSnapshot[investor] = totalSupply / totalShares;

        emit onWithdraw(
            investor,
            amount,
            getContractBalance(),
            now
        );
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getInvestmentValue(address investor) public view returns (uint256) {
        return investedAmount[investor]
            .mul(sharePriceSnapshot[investor])
            .mul(totalShares)
            .div(totalSupply);
    }

    uint256 public totalSupply = 10e21 * 10e21;
    uint256 public totalShares = 10e21;
    uint256 public feePercent = 2;
    uint256 public minInvestment = 0.001 ether;
}