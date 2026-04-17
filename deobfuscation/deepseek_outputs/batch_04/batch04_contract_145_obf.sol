```solidity
pragma solidity ^0.4.11;

contract BonusDistribution {
    mapping(address => uint) public bonusBalances;
    mapping(address => int) public investorAccounts;
    
    address public owner;
    address public fundariaTokenBuyAddress;
    address public registeringContractAddress;
    uint256 public finalTimestampOfBonusPeriod;
    
    event BonusWithdrawn(address indexed beneficiary, uint amount);
    event AccountFilledWithBonus(address indexed investor, uint amount, int accountBalance);
    
    function BonusDistribution() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier hasBonus() {
        require(bonusBalances[msg.sender] > 0);
        _;
    }
    
    function setFundariaTokenBuyAddress(address _address) onlyOwner {
        fundariaTokenBuyAddress = _address;
    }
    
    function setRegisteringContractAddress(address _address) onlyOwner {
        registeringContractAddress = _address;
    }
    
    function setFinalTimestampOfBonusPeriod(uint _timestamp) onlyOwner {
        if (finalTimestampOfBonusPeriod < _timestamp) {
            finalTimestampOfBonusPeriod = _timestamp;
        }
    }
    
    function withdrawBonus() hasBonus {
        if (now > finalTimestampOfBonusPeriod) {
            uint bonusValue = bonusBalances[msg.sender];
            bonusBalances[msg.sender] = 0;
            BonusWithdrawn(msg.sender, bonusValue);
            msg.sender.transfer(bonusValue);
        }
    }
    
    function markAsInvestor(address _investor) {
        if (msg.sender == owner || msg.sender == registeringContractAddress) {
            investorAccounts[_investor] = -1;
        }
    }
    
    function fillAccountWithBonus(address _investor) hasBonus {
        if (investorAccounts[_investor] == -1 || investorAccounts[_investor] > 0) {
            uint bonusValue = bonusBalances[msg.sender];
            bonusBalances[msg.sender] = 0;
            
            if (investorAccounts[_investor] == -1) {
                investorAccounts[_investor] = 0;
            }
            
            investorAccounts[_investor] += int(bonusValue);
            AccountFilledWithBonus(_investor, bonusValue, investorAccounts[_investor]);
            _investor.transfer(bonusValue);
        }
    }
    
    function() payable {
        if (msg.sender == fundariaTokenBuyAddress) {
            bonusBalances[tx.origin] += msg.value;
        }
    }
}
```