```solidity
pragma solidity ^0.4.25;

interface MasterContract {
    function() payable external;
    function invest(address investor) payable external returns(uint256);
    function withdraw() external;
    function reinvest() payable external;
    function exit() payable external;
    function setTotalEthereumBalance(uint256 amount) external;
    function transfer(address to, uint256 amount) external returns(bool);
    function distribute() external;
    function totalEthereumBalance() external;
    function myDividends(bool includeReferralBonus) external;
    function balanceOf(address investor) external pure returns(uint256);
    function transferFrom(address from, address to, uint256 tokens) external;
    function sell(uint256 amount) payable external returns (uint256);
    function buy() external;
    function calculateTokensReceived(uint256 ethereumToSpend) external;
    function calculateEthereumReceived(uint256 tokensToSell) external returns(uint256);
    function purchase(uint256 amount, address referrer) external;
}

contract InvestmentContract {
    using SafeMath for uint;
    
    address constant private MASTER_CONTRACT_ADDRESS = 0x0a97094c19295E320D5121d72139A150021a2702;
    MasterContract constant private masterContract = MasterContract(MASTER_CONTRACT_ADDRESS);
    
    mapping(address => uint) public investmentBalance;
    mapping(address => uint) public lastActionTime;
    mapping(address => uint) public totalWithdrawn;
    
    uint constant private MASTER_TAX_PERCENT = 8;
    uint constant private PAYOUT_INTERVAL = 1 hours;
    uint constant private LOW_PERCENT = 270;
    uint constant private AVERAGE_PERCENT = 375;
    uint constant private HIGH_PERCENT = 400;
    uint constant private PHASE_1_THRESHOLD = 1500 ether;
    uint constant private PHASE_2_THRESHOLD = 4000 ether;
    
    struct PhaseThresholds {
        uint highPercent;
        uint phase2Threshold;
        uint phase1Threshold;
        uint lowPercent;
        uint averagePercent;
        uint masterTaxPercent;
        uint payoutInterval;
        address masterContractAddress;
    }
    
    PhaseThresholds private thresholds = PhaseThresholds(
        HIGH_PERCENT,
        PHASE_2_THRESHOLD,
        PHASE_1_THRESHOLD,
        LOW_PERCENT,
        AVERAGE_PERCENT,
        MASTER_TAX_PERCENT,
        PAYOUT_INTERVAL,
        MASTER_CONTRACT_ADDRESS
    );
    
    function processInvestment() internal {
        if (msg.value > 0) {
            if (now > lastActionTime[msg.sender].add(PAYOUT_INTERVAL)) {
                investmentBalance[msg.sender] = investmentBalance[msg.sender].add(msg.value);
                lastActionTime[msg.sender] = now;
                sendToMasterContract();
            }
        }
    }
    
    function withdrawDividends() internal {
        uint payout = 0;
        
        if(investmentBalance[msg.sender].mul(92).div(100) > calculateDividends()){
            payout = investmentBalance[msg.sender].mul(92).div(100);
            totalWithdrawn[msg.sender] = 0;
            investmentBalance[msg.sender] = 0;
            lastActionTime[msg.sender] = 0;
            msg.sender.transfer(payout);
        } else {
            payout = calculateDividends();
            totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(payout);
            investmentBalance[msg.sender] = 0;
            lastActionTime[msg.sender] = 0;
            msg.sender.transfer(payout);
        }
    }
    
    function sendToMasterContract() internal {
        masterContract.invest.value(msg.value.mul(MASTER_TAX_PERCENT).div(100))(MASTER_CONTRACT_ADDRESS);
        masterContract.setTotalEthereumBalance(address(this).balance);
    }
    
    function calculateDividends() public view returns(uint) {
        uint currentPercent = getCurrentPercent();
        uint timeDiff = now.sub(lastActionTime[msg.sender]).div(PAYOUT_INTERVAL);
        uint dailyReturn = investmentBalance[msg.sender].mul(currentPercent).div(100000);
        uint totalReturn = dailyReturn.mul(timeDiff);
        
        if(totalReturn > investmentBalance[msg.sender].mul(2)){
            return investmentBalance[msg.sender].mul(2);
        }
        return totalReturn;
    }
    
    function getCurrentPercent() public view returns(uint) {
        uint contractBalance = address(this).balance;
        
        if (contractBalance < PHASE_1_THRESHOLD) {
            return LOW_PERCENT;
        }
        if (contractBalance >= PHASE_1_THRESHOLD && contractBalance < PHASE_2_THRESHOLD) {
            return AVERAGE_PERCENT;
        }
        if (contractBalance >= PHASE_2_THRESHOLD) {
            return HIGH_PERCENT;
        }
    }
    
    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns(uint) {
        uint c = a / b;
        return c;
    }
    
    function sub(uint a, uint b) internal pure returns(uint) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}
```