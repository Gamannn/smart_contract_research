pragma solidity ^0.4.11;

contract BonusContract {
    mapping(address => uint) public bonusBalances;
    mapping(address => int) public accountStatus;
    address public owner;
    address public fundariaTokenBuyAddress;
    address public registeringContractAddress;
    uint public finalTimestampOfBonusPeriod;

    event BonusWithdrawn(address indexed user, uint amount);
    event AccountFilledWithBonus(address indexed user, uint amount, int status);

    function BonusContract() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    modifier hasBonus() {
        if (bonusBalances[msg.sender] > 0) _;
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

    function setAccountStatus(address _user) {
        if (msg.sender == owner || msg.sender == registeringContractAddress) {
            accountStatus[_user] = -1;
        }
    }

    function fillAccountWithBonus(address _user) hasBonus {
        if (accountStatus[_user] == -1 || accountStatus[_user] > 0) {
            uint bonusValue = bonusBalances[msg.sender];
            bonusBalances[msg.sender] = 0;
            if (accountStatus[_user] == -1) {
                accountStatus[_user] = 0;
            }
            accountStatus[_user] += int(bonusValue);
            AccountFilledWithBonus(_user, bonusValue, accountStatus[_user]);
            _user.transfer(bonusValue);
        }
    }

    function() payable {
        if (msg.sender == fundariaTokenBuyAddress) {
            bonusBalances[tx.origin] += msg.value;
        }
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [0, 1];
}