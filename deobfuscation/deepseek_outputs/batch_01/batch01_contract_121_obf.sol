```solidity
pragma solidity ^0.4.21;

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

interface Bankrollable {
    function removeBankrollAddress(address bankrollAddress) public;
    function addToBankroll() payable public;
    function getBankroll() public view returns(uint256);
}

interface TokenReceiver {
    function tokenFallback(address from, uint256 value, bytes data) public;
}

contract ERC20Token {
    function totalSupply() constant public returns (uint totalTokenSupply);
    function balanceOf(address owner) constant public returns (uint balance);
    function transfer(address to, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function allowance(address owner, address spender) constant public returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract EOSBetStakeToken is ERC20Token, Bankrollable {
    using SafeMath for *;
    
    mapping(address => bool) public authorized;
    mapping(address => uint256) lastActionTime;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    
    event FundBankroll(address sender, uint amountSent, uint tokensMinted);
    event CashOut(address sender, uint amountReceived, uint tokensBurned);
    event FailedSend(address recipient, uint amount);
    
    modifier onlyAuthorized(address sender) {
        require(authorized[sender]);
        _;
    }
    
    function EOSBetStakeToken(address bankrollAddress1, address bankrollAddress2) public payable {
        require(msg.value > 0);
        contractOwner = msg.sender;
        
        uint256 tokensMinted = msg.value.mul(100);
        balances[msg.sender] = tokensMinted;
        totalSupply = tokensMinted;
        
        emit Transfer(0x0, msg.sender, tokensMinted);
        
        authorized[bankrollAddress1] = true;
        authorized[bankrollAddress2] = true;
        
        bankroll1 = bankrollAddress1;
        bankroll2 = bankrollAddress2;
        
        cashoutFeeDelay = 6 hours;
        maxProfit = 500 ether;
    }
    
    function getLastActionTime(address user) view public returns(uint256) {
        return lastActionTime[user];
    }
    
    function getBankroll() view public returns(uint256) {
        return SafeMath.sub(address(this).balance, totalReserved);
    }
    
    function sendFundsToAddress(uint256 amount, address recipient) public onlyAuthorized(msg.sender) {
        if (!recipient.send(amount)) {
            emit FailedSend(recipient, amount);
            if (!contractOwner.send(amount)) {
                emit FailedSend(contractOwner, amount);
            }
        }
    }
    
    function addToBankroll() payable public onlyAuthorized(msg.sender) {}
    
    function removeBankrollAddress(address bankrollAddress) public onlyAuthorized(msg.sender) {
        Bankrollable(bankrollAddress).addToBankroll().value(amount)();
    }
    
    function() public payable {
        uint256 availableBankroll = getBankroll();
        uint256 maxAllowedBet = maxProfit;
        
        require(availableBankroll.add(msg.value) < maxAllowedBet && msg.value != 0);
        
        uint256 currentTotalSupply = totalSupply;
        uint256 actualBetAmount;
        bool refundNeeded;
        uint256 refundAmount;
        uint256 tokensToMint;
        
        if (availableBankroll.add(msg.value) > maxAllowedBet) {
            refundNeeded = true;
            actualBetAmount = SafeMath.sub(maxAllowedBet, availableBankroll);
            refundAmount = SafeMath.sub(msg.value, actualBetAmount);
        } else {
            actualBetAmount = msg.value;
        }
        
        if (currentTotalSupply != 0) {
            tokensToMint = actualBetAmount.mul(currentTotalSupply).div(availableBankroll);
        } else {
            tokensToMint = actualBetAmount.mul(100);
        }
        
        totalSupply = SafeMath.add(currentTotalSupply, tokensToMint);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], tokensToMint);
        lastActionTime[msg.sender] = block.timestamp;
        
        if (refundNeeded) {
            msg.sender.transfer(refundAmount);
        }
        
        emit FundBankroll(msg.sender, actualBetAmount, tokensToMint);
        emit Transfer(0x0, msg.sender, tokensToMint);
    }
    
    function cashOut(uint256 tokensToBurn) public {
        uint256 userBalance = balances[msg.sender];
        require(tokensToBurn <= userBalance && 
                lastActionTime[msg.sender].add(cashoutFeeDelay) <= block.timestamp &&
                tokensToBurn > 0);
        
        uint256 availableBankroll = getBankroll();
        uint256 currentTotalSupply = totalSupply;
        
        uint256 etherValue = tokensToBurn.mul(availableBankroll).div(currentTotalSupply);
        uint256 fee = etherValue.div(100);
        uint256 payout = SafeMath.sub(etherValue, fee);
        
        totalSupply = SafeMath.sub(currentTotalSupply, tokensToBurn);
        balances[msg.sender] = SafeMath.sub(userBalance, tokensToBurn);
        totalReserved = SafeMath.add(totalReserved, fee);
        
        msg.sender.transfer(payout);
        
        emit CashOut(msg.sender, payout, tokensToBurn);
        emit Transfer(msg.sender, 0x0, tokensToBurn);
    }
    
    function cashOutAll() public {
        cashOut(balances[msg.sender]);
    }
    
    function changeOwner(address newOwner) public {
        require(msg.sender == contractOwner);
        contractOwner = newOwner;
    }
    
    function changeCashoutFeeDelay(uint256 newDelay) public {
        require(msg.sender == contractOwner && newDelay <= 6048000);
        cashoutFeeDelay = newDelay;
    }
    
    function changeMaxProfit(uint256 newMaxProfit) public {
        require(msg.sender == contractOwner);
        maxProfit = newMaxProfit;
    }
    
    function withdrawFees(address recipient) public {
        require(msg.sender == contractOwner);
        
        Bankrollable(bankroll1).removeBankrollAddress(recipient);
        Bankrollable(bankroll2).removeBankrollAddress(recipient);
        
        uint256 feesToWithdraw = totalReserved;
        totalReserved = 0;
        recipient.transfer(feesToWithdraw);
    }
    
    function rescueTokens(address tokenAddress, uint256 amount) public {
        require(msg.sender == contractOwner);
        ERC20Token(tokenAddress).transfer(msg.sender, amount);
    }
    
    function totalSupply() constant public returns(uint) {
        return totalSupply;
    }
    
    function balanceOf(address owner) constant public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns (bool success) {
        require(balances[msg.sender] >= value && 
                lastActionTime[msg.sender].add(cashoutFeeDelay) <= block.timestamp &&
                to != address(this) &&
                to != address(0));
                
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
        balances[to] = SafeMath.add(balances[to], value);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(allowed[from][msg.sender] >= value &&
                balances[from] >= value &&
                lastActionTime[from].add(cashoutFeeDelay) <= block.timestamp &&
                to != address(this) &&
                to != address(0));
                
        balances[to] = SafeMath.add(balances[to], value);
        balances[from] = SafeMath.sub(balances[from], value);
        allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], value);
        
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant public returns(uint) {
        return allowed[owner][spender];
    }
    
    struct ContractData {
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
        address bankroll2;
        address bankroll1;
        uint256 totalReserved;
        uint256 cashoutFeeDelay;
        uint256 maxProfit;
        address contractOwner;
        uint256 _unused1;
        uint256 _unused2;
    }
    
    ContractData data = ContractData(0, 18, "EOSBETST", "EOSBet Stake Tokens", address(0), address(0), 0, 0, 0, address(0), 0, 0);
    
    uint256 totalSupply;
    uint256 totalReserved;
    uint256 cashoutFeeDelay;
    uint256 maxProfit;
    address contractOwner;
    address bankroll1;
    address bankroll2;
}
```