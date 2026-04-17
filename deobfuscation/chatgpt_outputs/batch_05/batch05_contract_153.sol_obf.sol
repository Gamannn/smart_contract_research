```solidity
pragma solidity >=0.4.22 <0.6.0;

contract InvestmentContract {
    using AddressUtils for *;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastPaymentBlock;
    mapping(address => uint256) public dailyPayment;
    mapping(address => uint256) public totalPaid;

    address payable constant owner = 0x27FE767C1da8a69731c64F15d6Ee98eE8af62E72;

    function invest() public payable {
        balances[msg.sender] += msg.value;
        address referrer = msg.data.toAddress();

        if (balances[referrer] != 0 && referrer != msg.sender) {
            balances[referrer] += msg.value / 20; // 5% referral bonus
            dailyPayment[referrer] += msg.value / 400; // 0.25% daily payment
            balances[msg.sender] += msg.value / 20; // 5% bonus for investor
        }

        dailyPayment[msg.sender] = (balances[msg.sender] * 2 - totalPaid[msg.sender]) / 40; // Calculate daily payment
    }

    function withdraw() public {
        if (balances[msg.sender] * 2 > totalPaid[msg.sender] && block.number - lastPaymentBlock[msg.sender] > 5900) {
            totalPaid[msg.sender] += dailyPayment[msg.sender];
            lastPaymentBlock[msg.sender] = block.number;
            msg.sender.transfer(dailyPayment[msg.sender]);
        }
    }

    function getInvestorInfo(address investor) public view returns (uint balance, uint potentialProfit, uint daily, uint minutesBeforeNextPayment, uint totalWithdrawn) {
        balance = balances[investor] / 1000000000;
        potentialProfit = (balances[investor] * 2 - totalPaid[investor]) / 1000000000;
        daily = dailyPayment[investor] / 10;
        uint minutesPassed = 1440 - (block.number - lastPaymentBlock[investor]) / 4;
        if (minutesPassed >= 0) {
            minutesBeforeNextPayment = minutesPassed;
        } else {
            minutesBeforeNextPayment = 0;
        }
        totalWithdrawn = totalPaid[investor] / 1000000000;
    }

    address payable[] public _address_constant = [0x27FE767C1da8a69731c64F15d6Ee98eE8af62E72];
    uint256[] public _integer_constant = [0, 4, 400, 5900, 1000, 40, 1440, 10, 2, 1000000000, 20];

    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }
}

library AddressUtils {
    function toAddress(bytes memory data) internal pure returns (address payable addr) {
        assembly {
            addr := mload(add(data, 0x14))
        }
        return addr;
    }
}
```