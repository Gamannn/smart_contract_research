pragma solidity ^0.4.16;

interface TokenInterface {
    function getOwner() constant returns (address);
    function transfer(address to, uint amount) public;
}

contract AdminControl {
    address public admin1;
    address public admin2;
    address public admin3;

    function AdminControl(address _admin1, address _admin2, address _admin3) public {
        admin1 = _admin1;
        admin2 = _admin2;
        admin3 = _admin3;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3);
        _;
    }

    function changeAdmin(address newAdmin) onlyAdmin public {
        require(newAdmin != admin1);
        require(newAdmin != admin2);
        require(newAdmin != admin3);

        if (msg.sender == admin1) {
            admin1 = newAdmin;
        } else if (msg.sender == admin2) {
            admin2 = newAdmin;
        } else if (msg.sender == admin3) {
            admin3 = newAdmin;
        }
    }
}

contract Presale is AdminControl {
    uint public hardCap;
    uint public bonusPercentage;
    uint public duration;
    uint public tokensPerEther;
    uint public startTime;
    uint public totalRaised;
    address public tokenAddress;
    address public beneficiary;

    event Investing(address investor, uint investedAmount, uint tokensWithoutBonus);
    event Raise(address beneficiary, uint amount);

    function Presale(
        address _admin1,
        address _admin2,
        address _admin3,
        address _tokenAddress
    ) AdminControl(_admin1, _admin2, _admin3) public {
        hardCap = 1000 ether;
        bonusPercentage = 50;
        duration = 61 days;
        tokensPerEther = 400;
        tokenAddress = _tokenAddress;
        startTime = 1526342400;
    }

    modifier onlyDuringSale() {
        require(now >= startTime);
        require(now <= startTime + duration);
        _;
    }

    function invest() onlyDuringSale public payable {
        uint tokenAmountWithoutBonus = msg.value * tokensPerEther;
        uint tokenAmountWithBonus = tokenAmountWithoutBonus + (tokenAmountWithoutBonus * bonusPercentage / 100);

        TokenInterface(tokenAddress).transfer(msg.sender, tokenAmountWithBonus);

        totalRaised += msg.value;

        Investing(msg.sender, msg.value, tokenAmountWithoutBonus);
    }

    function setBeneficiary(address _beneficiary) public onlyAdmin {
        beneficiary = _beneficiary;
    }

    function withdraw(uint amount) public onlyAdmin {
        require(beneficiary != 0x0);
        require(amount <= this.balance);

        Raise(beneficiary, amount);
        beneficiary.transfer(amount);
    }
}