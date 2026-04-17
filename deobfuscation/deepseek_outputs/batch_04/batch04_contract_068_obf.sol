pragma solidity ^0.4.18;

contract InvestmentContract {
    mapping (address => uint256) public investedETH;
    mapping (address => uint256) public lastActionTime;
    mapping (address => uint256) public affiliateBalance;
    
    address public constant PROMOTER_ADDRESS = 0xE6f43c670CC8a366bBcf6677F43B02754BFB5855;
    address public constant DEV_ADDRESS = address(0);

    function invest(address referrer) public payable {
        require(msg.value >= 0.01 ether);
        
        uint256 dividends = calculateDividends(msg.sender);
        if (dividends > 0) {
            lastActionTime[msg.sender] = now;
            msg.sender.transfer(dividends);
        }
        
        uint256 investment = msg.value;
        uint256 fee = SafeMath.div(investment, 20); // 5% fee
        
        if (referrer != msg.sender && referrer != address(0)) {
            affiliateBalance[referrer] = SafeMath.add(affiliateBalance[referrer], fee);
        }
        
        affiliateBalance[DEV_ADDRESS] = SafeMath.add(affiliateBalance[DEV_ADDRESS], fee);
        affiliateBalance[PROMOTER_ADDRESS] = SafeMath.add(affiliateBalance[PROMOTER_ADDRESS], fee);
        
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], investment);
        lastActionTime[msg.sender] = now;
    }
    
    function withdraw() public {
        uint256 dividends = calculateDividends(msg.sender);
        lastActionTime[msg.sender] = now;
        
        uint256 investment = investedETH[msg.sender];
        uint256 penalty = SafeMath.div(investment, 10);
        investment = SafeMath.sub(investment, penalty);
        
        uint256 totalAmount = SafeMath.add(investment, dividends);
        require(totalAmount > 0);
        
        investedETH[msg.sender] = 0;
        msg.sender.transfer(totalAmount);
    }
    
    function withdrawDividends() public {
        uint256 dividends = calculateDividends(msg.sender);
        require(dividends > 0);
        
        lastActionTime[msg.sender] = now;
        msg.sender.transfer(dividends);
    }
    
    function calculateMyDividends() public view returns(uint256) {
        return calculateDividends(msg.sender);
    }
    
    function calculateDividends(address investor) public view returns(uint256) {
        uint256 timePassed = SafeMath.sub(now, lastActionTime[investor]);
        return SafeMath.div(
            SafeMath.mul(timePassed, investedETH[investor]),
            4320000
        );
    }
    
    function reinvest() public {
        uint256 dividends = calculateDividends(msg.sender);
        require(dividends > 0);
        
        lastActionTime[msg.sender] = now;
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], dividends);
    }
    
    function getAffiliateBalance() public view returns(uint256) {
        return affiliateBalance[msg.sender];
    }
    
    function withdrawAffiliateBalance() public {
        require(affiliateBalance[msg.sender] > 0);
        uint256 balance = affiliateBalance[msg.sender];
        affiliateBalance[msg.sender] = 0;
        msg.sender.transfer(balance);
    }
    
    function getInvestment() public view returns(uint256) {
        return investedETH[msg.sender];
    }
    
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}