pragma solidity ^0.4.18;

contract Oxec665bfc2a45fcd178aca6fe23507dcfdae6e99b {
    mapping(address => uint256) public invested;
    mapping(address => uint256) public lastBlock;
    uint256 public minInvestment;
    address public owner;
    
    address public partner1;
    address public partner2;
    
    event Invested(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    
    constructor() public {
        owner = 0x6fDb012E4a57623eA74Cc1a6E5095Cda63f2C767;
        partner1 = 0xf62f85457f97CE475AAa5523C5739Aa8d4ba64C1;
        partner2 = address(0);
        minInvestment = 0.01 ether;
    }
    
    function calculateInterestRate(address investor) internal view returns (uint256) {
        uint256 rate = 400;
        uint256 investment = invested[investor];
        
        if (investment >= 1 ether && investment < 10 ether) {
            rate = 425;
        }
        if (investment >= 10 ether && investment < 20 ether) {
            rate = 450;
        }
        if (investment >= 20 ether && investment < 40 ether) {
            rate = 475;
        }
        if (investment >= 40 ether) {
            rate = 500;
        }
        return rate;
    }
    
    function () external payable {
        require(msg.value == 0 || msg.value >= minInvestment, "Min Amount for investing is 0.01 Ether.");
        
        uint256 amount = msg.value;
        address investor = msg.sender;
        
        owner.transfer(amount / 10);
        partner1.transfer(amount / 100);
        
        if (invested[investor] != 0) {
            uint256 payout = invested[investor] * calculateInterestRate(investor) / 10000 * (block.number - lastBlock[investor]) / 5900;
            investor.transfer(payout);
            emit Withdraw(investor, payout);
        }
        
        lastBlock[investor] = block.number;
        invested[investor] += amount;
        
        if (amount > 0) {
            emit Invested(investor, amount);
        }
    }
    
    function getInvestment(address investor) public view returns(uint256) {
        return invested[investor];
    }
    
    function getLastBlock(address investor) public view returns(uint256) {
        return lastBlock[investor];
    }
    
    function calculateDividends(address investor) public view returns(uint256) {
        uint256 dividends = invested[investor] * calculateInterestRate(investor) / 10000 * (block.number - lastBlock[investor]) / 5900;
        return dividends;
    }
}