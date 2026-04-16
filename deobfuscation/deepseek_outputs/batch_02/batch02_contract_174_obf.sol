```solidity
pragma solidity ^0.4.0;

contract Ownable {
    address public owner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Destructible is Ownable {
    function destroy() public {
        if (msg.sender == owner) 
            selfdestruct(owner);
    }
}

contract ERC20Interface {
    uint256 public totalSupply;
    
    function transfer(address to, uint256 value) public returns(bool success);
    function transferFrom(address from, address to, uint256 value, uint256 deadline) public returns(bool success);
    function approve(address spender, uint256 value) public returns(bool success);
    function allowance(address owner, address spender) public constant returns(uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract ERC20 is ERC20Interface, Destructible, Pausable {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    function transfer(address to, uint256 value) public returns(bool success) {
        require(to != address(0));
        require(value > 0);
        
        uint256 fee = 0;
        uint256 totalAmount = value + fee;
        
        if (balances[msg.sender] >= totalAmount) {
            balances[msg.sender] -= totalAmount;
            balances[to] += totalAmount;
            Transfer(msg.sender, to, totalAmount);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 value, uint256 deadline) public returns(bool success) {
        require(from != address(0));
        require(to != address(0));
        require(value > 0);
        require(now > deadline || from == owner);
        
        if (balances[from] >= value && allowance(from, to) >= value) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function balanceOf(address owner) public constant returns(uint256 balance) {
        return balances[owner];
    }
    
    function approve(address spender, uint256 value) public returns(bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public constant returns(uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract Token is ERC20 {
    string public constant name = "Token";
    uint8 public constant decimals = 18;
    string public constant symbol = "KIK";
    
    uint256 public rate;
    bool public isFinalized;
    uint256 public firstBonus;
    uint256 public secondBonus;
    uint256 public thirdBonus;
    uint256 public fourthBonus;
    
    uint256 public deadLine;
    uint256 public firstBonusEstimate;
    uint256 public secondBonusEstimate;
    uint256 public thirdBonusEstimate;
    uint256 public fourthBonusEstimate;
    
    uint256 public firstBonusPriceRate;
    uint256 public secondBonusPriceRate;
    uint256 public thirdBonusPriceRate;
    uint256 public fourthBonusPriceRate;
    
    uint256 public totalTokens = 85000 * (10 ** uint256(decimals));
    uint256 public bountyReserveTokens = 50000000 * (10 ** uint256(decimals));
    uint256 public advisoryReserveTokens = 40000000 * (10 ** uint256(decimals));
    uint256 public teamReserveTokens = 400000000 * (10 ** uint256(decimals));
    
    uint256 public tokensDistributed = 0;
    
    function Token() public {
        deadLine = now + 5097600;
        firstBonus = 50000000 * (10 ** uint256(decimals));
        firstBonusPriceRate = 5 * (10 ** uint256(decimals));
        secondBonusEstimate = 40000000 * (10 ** uint256(decimals));
        secondBonusPriceRate = 10 * (10 ** uint256(decimals));
        thirdBonusEstimate = 400000000 * (10 ** uint256(decimals));
        thirdBonusPriceRate = 8 * (10 ** uint256(decimals));
        fourthBonusEstimate = 200000 * (10 ** uint256(decimals));
        fourthBonusPriceRate = 6 * (10 ** uint256(decimals));
        isFinalized = false;
        tokensDistributed = 0;
    }
    
    function() payable public whenNotPaused {
        require(msg.value > 0);
        require(now < deadLine);
        
        if(isFinalized) {
            revert();
        }
        
        uint256 tokensToTransfer = 0;
        
        if(tokensDistributed >= 0 && tokensDistributed < firstBonus) {
            tokensToTransfer = ((msg.value * rate) / firstBonusPriceRate);
        }
        
        if(tokensDistributed >= firstBonus && tokensDistributed < secondBonusEstimate) {
            tokensToTransfer = ((msg.value * rate) / secondBonusPriceRate);
        }
        
        if(tokensDistributed >= secondBonusEstimate && tokensDistributed < thirdBonusEstimate) {
            tokensToTransfer = ((msg.value * rate) / thirdBonusPriceRate);
        }
        
        if(tokensDistributed >= thirdBonusEstimate && tokensDistributed < fourthBonusEstimate) {
            tokensToTransfer = ((msg.value * rate) / fourthBonusPriceRate);
        }
        
        if(tokensDistributed + tokensToTransfer > totalTokens) {
            revert();
        }
        
        allowed[owner][msg.sender] += tokensToTransfer;
        bool transferResult = transferFrom(owner, msg.sender, tokensToTransfer, deadLine);
        
        if (!transferResult) {
            revert();
        } else {
            tokensDistributed += tokensToTransfer;
        }
    }
    
    function withdraw() public onlyOwner whenPaused returns(uint256 amount) {
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
        return address(this).balance;
    }
    
    function transferBounty(address bountyAddress, uint256 transferAmount) public onlyOwner {
        transferAmount = transferAmount * (10 ** uint256(decimals));
        
        if(bountyReserveTokens + transferAmount > bountyReserveTokens) {
            revert();
        }
        
        allowed[owner][bountyAddress] += transferAmount;
        bool transferResult = transferFrom(owner, bountyAddress, transferAmount, deadLine);
        
        if (!transferResult) {
            revert();
        } else {
            bountyReserveTokens += transferAmount;
        }
    }
    
    function transferTeamReserve(address teamAddress, uint256 transferAmount) public onlyOwner {
        transferAmount = transferAmount * (10 ** uint256(decimals));
        
        if(teamReserveTokens + transferAmount > teamReserveTokens) {
            revert();
        }
        
        allowed[owner][teamAddress] += transferAmount;
        bool transferResult = transferFrom(owner, teamAddress, transferAmount, deadLine);
        
        if (!transferResult) {
            revert();
        } else {
            teamReserveTokens += transferAmount;
        }
    }
    
    function transferAdvisoryReserve(address advisoryAddress, uint256 transferAmount) public onlyOwner {
        transferAmount = transferAmount * (10 ** uint256(decimals));
        
        if(advisoryReserveTokens + transferAmount > advisoryReserveTokens) {
            revert();
        }
        
        allowed[owner][advisoryAddress] += transferAmount;
        bool transferResult = transferFrom(owner, advisoryAddress, transferAmount, deadLine);
        
        if (!transferResult) {
            revert();
        } else {
            advisoryReserveTokens += transferAmount;
        }
    }
    
    function finalize() public onlyOwner {
        isFinalized = true;
    }
}
```