pragma solidity ^0.4.24;

contract InvestmentContract {
    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastBlock;
    uint256 public minInvestment;
    address public owner;

    constructor() public {
        owner = 0x0D257779Bbe6321d8349eEbCb2f0f5a90409DB80;
        minInvestment = 0.01 ether;
    }

    function getInterestRate(address investor) internal view returns (uint256) {
        uint256 rate = 400;
        uint256 investedAmount = investments[investor];

        if (investedAmount >= 1 ether && investedAmount < 10 ether) {
            rate = 425;
        } else if (investedAmount >= 10 ether && investedAmount < 20 ether) {
            rate = 450;
        } else if (investedAmount >= 20 ether && investedAmount < 40 ether) {
            rate = 475;
        } else if (investedAmount >= 40 ether) {
            rate = 500;
        }

        return rate;
    }

    function () external payable {
        require(msg.value == 0 || msg.value >= minInvestment, "Min Amount for investing is 0.01 Ether.");
        
        uint256 investmentAmount = msg.value;
        address investor = msg.sender;

        owner.transfer(investmentAmount / 10);

        if (investments[investor] != 0) {
            uint256 payout = investments[investor] * getInterestRate(investor) / 10000 * (block.number - lastBlock[investor]) / 5900;
            investor.transfer(payout);
            emit Withdraw(investor, payout);
        }

        lastBlock[investor] = block.number;
        investments[investor] += investmentAmount;

        if (investmentAmount > 0) {
            emit Invested(investor, investmentAmount);
        }
    }

    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getLastBlock(address investor) public view returns (uint256) {
        return lastBlock[investor];
    }

    function calculatePayout(address investor) public view returns (uint256) {
        uint256 payout = investments[investor] * getInterestRate(investor) / 10000 * (block.number - lastBlock[investor]) / 5900;
        return payout;
    }

    event Invested(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
}