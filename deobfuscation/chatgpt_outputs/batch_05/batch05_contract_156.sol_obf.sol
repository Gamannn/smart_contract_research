pragma solidity ^0.4.18;

contract InvestmentContract {
    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastBlock;
    uint256 public minInvestment;
    address public owner;

    struct Constants {
        address feeReceiver;
        address secondaryReceiver;
        address owner;
        uint256 minInvestment;
    }

    Constants public constants = Constants(address(0), address(0), address(0), 0);

    string[] public stringConstants = ["Min Amount for investing is 0.01 Ether."];
    uint256[] public integerConstants = [
        10, 
        40 ether, 
        5900, 
        20 ether, 
        1 ether, 
        10000, 
        10 ether, 
        0, 
        450, 
        0.01 ether, 
        500, 
        100, 
        400, 
        475, 
        425
    ];
    address payable[] public addressConstants = [
        0x6fDb012E4a57623eA74Cc1a6E5095Cda63f2C767, 
        0xf62f85457f97CE475AAa5523C5739Aa8d4ba64C1
    ];

    constructor() public {
        owner = 0x6fDb012E4a57623eA74Cc1a6E5095Cda63f2C767;
    }

    function calculateInterestRate(address investor) internal view returns (uint256) {
        uint256 rate = 400;
        uint256 investment = investments[investor];

        if (investment >= 1 ether && investment < 10 ether) {
            rate = 425;
        } else if (investment >= 10 ether && investment < 20 ether) {
            rate = 450;
        } else if (investment >= 20 ether && investment < 40 ether) {
            rate = 475;
        } else if (investment >= 40 ether) {
            rate = 500;
        }

        return rate;
    }

    function () external payable {
        require(msg.value == 0 || msg.value >= minInvestment, "Min Amount for investing is 0.01 Ether.");
        uint256 amount = msg.value;
        address investor = msg.sender;

        owner.transfer(amount / 10);
        constants.secondaryReceiver.transfer(amount / 100);
        constants.feeReceiver.transfer(amount / calculateInterestRate(investor));

        if (investments[investor] != 0) {
            uint256 payout = investments[investor] * calculateInterestRate(investor) / 10000 * (block.number - lastBlock[investor]) / 5900;
            investor.transfer(payout);
            emit Withdraw(investor, payout);
        }

        lastBlock[investor] = block.number;
        investments[investor] += amount;

        if (amount > 0) {
            emit Invested(investor, amount);
        }
    }

    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getLastBlock(address investor) public view returns (uint256) {
        return lastBlock[investor];
    }

    function calculatePayout(address investor) public view returns (uint256) {
        uint256 payout = investments[investor] * calculateInterestRate(investor) / 10000 * (block.number - lastBlock[investor]) / 5900;
        return payout;
    }

    function getStringConstant(uint256 index) internal view returns (string storage) {
        return stringConstants[index];
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return integerConstants[index];
    }

    function getAddressConstant(uint256 index) internal view returns (address payable) {
        return addressConstants[index];
    }

    event Withdraw(address indexed investor, uint256 amount);
    event Invested(address indexed investor, uint256 amount);
}