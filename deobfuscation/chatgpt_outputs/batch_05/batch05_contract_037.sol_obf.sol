pragma solidity ^0.4.25;

contract InterestContract {
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public balances;
    address constant private TECH_SUPPORT = 0x85889bBece41bf106675A9ae3b70Ee78D86C1649;

    function() external payable {
        address user = msg.sender;
        
        if (balances[user] == 0.00000112 ether) {
            uint256 techSupportFee = balances[user] * 10 / 100;
            TECH_SUPPORT.transfer(techSupportFee);
            
            uint256 userAmount = balances[user] - techSupportFee;
            user.transfer(userAmount);
            
            lastWithdrawalTime[user] = 0;
            balances[user] = 0;
        } else {
            if (balances[user] != 0) {
                uint256 interest = balances[user] / 100 * (now - lastWithdrawalTime[user]) / 1 days;
                
                if (interest > address(this).balance) {
                    interest = address(this).balance;
                }
                
                user.transfer(interest);
            }
            
            lastWithdrawalTime[user] = now;
            balances[user] += msg.value;
        }
    }
    
    function getAddressConstant(uint256 index) internal view returns(address) {
        return _address_constant[index];
    }
    
    function getIntegerConstant(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    address payable[] public _address_constant = [0x85889bBece41bf106675A9ae3b70Ee78D86C1649];
    uint256[] public _integer_constant = [86400, 10, 0, 100, 1120000000000];
}