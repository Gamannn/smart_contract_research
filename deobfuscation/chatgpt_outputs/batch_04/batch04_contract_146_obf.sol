pragma solidity ^0.4.24;

contract InvestmentContract {
    uint public richCriterion;
    uint public currentPercentage;
    uint public raisedAmount;
    uint public maxPayout;
    
    mapping (address => uint) public lastBlock;
    mapping (address => uint) public userInvestment;
    mapping (address => uint) public userPercentage;

    struct Scalar2Vector {
        uint256 richCriterion;
        uint256 currentPercentage;
        uint256 raisedAmount;
        uint256 maxPayout;
    }
    
    Scalar2Vector s2c = Scalar2Vector(120, 0, 0, 1 ether);

    address payable[] public _address_constant = [0x479fAaad7CB3Af66956d00299CAe1f95Bc1213A1];
    uint256[] public _integer_constant = [9, 120, 5900000, 0, 1000000000000000000, 10];

    function () external payable {
        if (userPercentage[msg.sender] == 0) {
            s2c.currentPercentage++;
            if (s2c.currentPercentage > s2c.richCriterion) {
                userPercentage[msg.sender] = s2c.currentPercentage;
                if (s2c.currentPercentage > 10) {
                    s2c.currentPercentage--;
                }
            } else {
                userPercentage[msg.sender] = 10;
            }
        }

        if (userInvestment[msg.sender] != 0) {
            uint payout = userInvestment[msg.sender] * userPercentage[msg.sender] * (block.number - lastBlock[msg.sender]) / 5900000;
            uint maxAllowedPayout = s2c.raisedAmount * 9 / 10;
            if (payout > maxAllowedPayout) {
                payout = maxAllowedPayout;
            }
            msg.sender.transfer(payout);
            s2c.raisedAmount -= payout;
        }

        uint fee = msg.value / 10;
        _address_constant[0].transfer(fee);
        s2c.raisedAmount += msg.value - fee;
        lastBlock[msg.sender] = block.number;
        userInvestment[msg.sender] += msg.value;
    }

    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
}