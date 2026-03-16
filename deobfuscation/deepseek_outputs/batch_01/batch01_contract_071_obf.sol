```solidity
pragma solidity 0.5.8;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external returns(uint);
    function balanceOf(address account) external returns(uint balance);
    function allowance(address owner, address spender) external returns(uint remaining);
    function transfer(address recipient, uint amount) external returns(bool success);
    function approve(address spender, uint amount) external returns(bool success);
    function transferFrom(address sender, address recipient, uint amount) external returns(bool success);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract AdminControl {
    mapping(address => uint8) public adminLevel;
    
    constructor() internal {
        adminLevel[0x7a3a57c620fA468b304b5d1826CDcDe28E2b2b98] = 2;
        emit AdminshipUpdated(0x7a3a57c620fA468b304b5d1826CDcDe28E2b2b98, 2);
    }
    
    modifier onlyAdmin(uint8 requiredLevel) {
        require(adminLevel[msg.sender] >= requiredLevel, "You dont have rights for this transaction");
        _;
    }
    
    function setAdminLevel(address account, uint8 level) public onlyAdmin(2) {
        require(account != address(0), "Address cannot be zero");
        adminLevel[account] = level;
        emit AdminshipUpdated(account, level);
    }
    
    event AdminshipUpdated(address account, uint8 level);
}

contract TokenSale is AdminControl {
    using SafeMath for uint256;
    
    enum State { OnSale, Successful }
    State public saleState = State.OnSale;
    
    uint256 public startTime = now;
    uint256 public endTime;
    
    IERC20 public token;
    
    uint256 public totalRaised;
    uint256 public totalTokensSold;
    uint256 public totalBonusTokens;
    
    uint256 public constant TOKEN_PRICE = 2941;
    uint256 public constant STAGE_1_CAP = 52500000 * 1e18;
    uint256 public constant TOTAL_CAP = 420000000 * 1e18;
    uint256 public constant MIN_RAISE = 3000000 * 1e18;
    
    mapping(address => uint256) public ethContributed;
    mapping(address => uint256) public tokensPurchased;
    mapping(address => uint256) public bonusTokens;
    
    address public saleOwner;
    address payable public beneficiary;
    
    string public version = '1';
    
    event LogFundingInitialized(address owner);
    event LogFundingReceived(address contributor, uint amount, uint totalRaised);
    event LogContributorsPayout(address contributor, uint amount);
    event LogBeneficiaryPaid(address beneficiary);
    event LogFundingSuccessful(uint totalRaised);
    
    modifier saleActive() {
        require(saleState != State.Successful, "Sale has ended");
        _;
    }
    
    constructor(IERC20 tokenAddress) public {
        token = tokenAddress;
        saleOwner = 0x7a3a57c620fA468b304b5d1826CDcDe28E2b2b98;
        beneficiary = 0x8605409D35f707714A83410BE9C8025dcefa9faC;
        emit LogFundingInitialized(saleOwner);
    }
    
    function buyTokens(address beneficiaryAddress, uint256 amount) public saleActive payable {
        address contributor;
        uint contribution;
        uint tokensToBuy;
        uint bonus;
        uint remainingTokens;
        uint stageRemaining;
        uint tokensInStage;
        
        if (beneficiaryAddress != address(0) && adminLevel[msg.sender] >= 1) {
            contributor = beneficiaryAddress;
            contribution = amount;
        } else {
            contributor = msg.sender;
            contribution = msg.value;
            ethContributed[msg.sender] = ethContributed[msg.sender].add(msg.value);
        }
        
        require(contribution >= 0.1 ether, "Not enough value for this transaction");
        
        totalRaised = totalRaised.add(contribution);
        tokensToBuy = contribution.mul(TOKEN_PRICE);
        
        uint tokensWithBonus = contribution.mul(TOKEN_PRICE);
        
        if (tokensWithBonus > 0 && totalTokensSold < STAGE_1_CAP) {
            stageRemaining = STAGE_1_CAP.sub(totalTokensSold);
            
            if (tokensWithBonus < stageRemaining) {
                tokensInStage = tokensWithBonus.mul(4);
                bonus = tokensInStage.div(10);
                totalTokensSold = totalTokensSold.add(tokensWithBonus);
                tokensWithBonus = 0;
                tokensInStage = 0;
                stageRemaining = 0;
            } else {
                tokensInStage = stageRemaining.mul(4);
                bonus = tokensInStage.div(10);
                totalTokensSold = totalTokensSold.add(stageRemaining);
                tokensWithBonus = tokensWithBonus.sub(stageRemaining);
                tokensInStage = 0;
                stageRemaining = 0;
            }
        }
        
        if (tokensWithBonus > 0 && totalTokensSold >= STAGE_1_CAP && totalTokensSold < STAGE_1_CAP.mul(2)) {
            stageRemaining = STAGE_1_CAP.mul(2).sub(totalTokensSold);
            
            if (tokensWithBonus < stageRemaining) {
                tokensInStage = tokensWithBonus.mul(35);
                bonus = bonus.add(tokensInStage.div(100));
                totalTokensSold = totalTokensSold.add(tokensWithBonus);
                tokensWithBonus = 0;
                tokensInStage = 0;
                stageRemaining = 0;
            } else {
                tokensInStage = stageRemaining.mul(35);
                bonus = bonus.add(tokensInStage.div(100));
                totalTokensSold = totalTokensSold.add(stageRemaining);
                tokensWithBonus = tokensWithBonus.sub(stageRemaining);
                tokensInStage = 0;
                stageRemaining = 0;
            }
        }
        
        if (tokensWithBonus > 0 && totalTokensSold >= STAGE_1_CAP.mul(2) && totalTokensSold < STAGE_1_CAP.mul(3)) {
            stageRemaining = STAGE_1_CAP.mul(3).sub(totalTokensSold);
            
            if (tokensWithBonus < stageRemaining) {
                tokensInStage = tokensWithBonus.mul(3);
                bonus = bonus.add(tokensInStage.div(10));
                totalTokensSold = totalTokensSold.add(tokensWithBonus);
                tokensWithBonus = 0;
                tokensInStage = 0;
                stageRemaining = 0;
            } else {
                tokensInStage = stageRemaining.mul(3);
                bonus = bonus.add(tokensInStage.div(10));
                totalTokensSold = totalTokensSold.add(stageRemaining);
                tokensWithBonus = tokensWithBonus.sub(stageRemaining);
                tokensInStage = 0;
                stageRemaining = 0;
            }
        }
        
        if (tokensWithBonus > 0 && totalTokensSold >= STAGE_1_CAP.mul(3) && totalTokensSold < STAGE_1_CAP.mul(4)) {
            stageRemaining = STAGE_1_CAP.mul(4).sub(totalTokensSold);
            
            if (tokensWithBonus < stageRemaining) {
                tokensInStage = tokensWithBonus.mul(2);
                bonus = bonus.add(tokensInStage.div(10));
                totalTokensSold = totalTokensSold.add(tokensWithBonus);
                tokensWithBonus = 0;
                tokensInStage = 0;
                stageRemaining = 0;
            } else {
                tokensInStage = stageRemaining.mul(2);
                bonus = bonus.add(tokensInStage.div(10));
                totalTokensSold = totalTokensSold.add(stageRemaining);
                tokensWithBonus = tokensWithBonus.sub(stageRemaining);
                tokensInStage = 0;
                stageRemaining = 0;
            }
        }
        
        if (tokensWithBonus > 0 && totalTokensSold >= STAGE_1_CAP.mul(4) && totalTokensSold < STAGE_1_CAP.mul(5)) {
            stageRemaining = STAGE_1_CAP.mul(5).sub(totalTokensSold);
            
            if (tokensWithBonus < stageRemaining) {
                bonus = bonus.add(tokensWithBonus.div(10));
                totalTokensSold = totalTokensSold.add(tokensWithBonus);
                tokensWithBonus = 0;
                tokensInStage = 0;
                stageRemaining = 0;
            } else {
                bonus = bonus.add(stageRemaining.div(10));
                totalTokensSold = totalTokensSold.add(stageRemaining);
                tokensWithBonus = tokensWithBonus.sub(stageRemaining);
                tokensInStage = 0;
                stageRemaining = 0;
            }
        }
        
        if (tokensWithBonus > 0 && totalTokensSold >= STAGE_1_CAP.mul(5) && totalTokensSold < STAGE_1_CAP.mul(6)) {
            stageRemaining = STAGE_1_CAP.mul(6).sub(totalTokensSold);
            
            if (tokensWithBonus < stageRemaining) {
                tokensInStage = tokensWithBonus.mul(5);
                bonus = bonus.add(tokensInStage.div(100));
                totalTokensSold = totalTokensSold.add(tokensWithBonus);
                tokensWithBonus = 0;
                tokensInStage = 0;
                stageRemaining = 0;
            } else {
                tokensInStage = stageRemaining.mul(5);
                bonus = bonus.add(tokensInStage.div(100));
                totalTokensSold = totalTokensSold.add(stageRemaining);
                tokensWithBonus = tokensWithBonus.sub(stageRemaining);
                tokensInStage = 0;
                stageRemaining = 0;
            }
        }
        
        totalTokensSold = totalTokensSold.add(tokensWithBonus);
        totalBonusTokens = totalBonusTokens.add(bonus);
        
        token.transfer(contributor, tokensToBuy.add(bonus));
        tokensPurchased[contributor] = tokensPurchased[contributor].add(tokensToBuy);
        bonusTokens[contributor] = bonusTokens[contributor].add(bonus);
        
        emit LogFundingReceived(contributor, contribution, totalRaised);
        checkFundingGoal();
    }
    
    function checkFundingGoal() public {
        if (totalTokensSold.add(totalBonusTokens) > TOTAL_CAP.sub(TOKEN_PRICE)) {
            saleState = State.Successful;
            endTime = now;
            emit LogFundingSuccessful(totalRaised);
            finalizeSale();
        }
    }
    
    function withdrawFunds() public onlyAdmin(2) {
        require(totalTokensSold >= MIN_RAISE, "Too early to retrieve funds");
        beneficiary.transfer(address(this).balance);
    }
    
    function refund() public saleActive {
        require(totalTokensSold >= MIN_RAISE, "Too early to retrieve funds");
        require(ethContributed[msg.sender] > 0, "No eth to refund");
        
        require(
            token.transferFrom(
                msg.sender,
                address(this),
                tokensPurchased[msg.sender].add(bonusTokens[msg.sender])
            ),
            "Cannot retrieve tokens"
        );
        
        totalTokensSold = totalTokensSold.sub(tokensPurchased[msg.sender]);
        totalBonusTokens = totalBonusTokens.sub(bonusTokens[msg.sender]);
        
        tokensPurchased[msg.sender] = 0;
        bonusTokens[msg.sender] = 0;
        
        uint refundAmount = ethContributed[msg.sender];
        ethContributed[msg.sender] = 0;
        
        msg.sender.transfer(refundAmount);
    }
    
    function finalizeSale() public {
        require(saleState == State.Successful, "Wrong Stage");
        
        uint256 remainingTokens = token.balanceOf(address(this));
        require(token.transfer(beneficiary, remainingTokens), "Transfer could not be made");
        
        beneficiary.transfer(address(this).balance);
        emit LogBeneficiaryPaid(beneficiary);
    }
    
    function () external payable {
        buyTokens(address(0), 0);
    }
}
```