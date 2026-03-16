```solidity
pragma solidity 0.4.19;

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

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ADBToken is ERC20Interface {
    using SafeMath for uint256;
    
    string public constant name = "ADB";
    string public constant symbol = "ADB";
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    enum Stages {
        NOTSTARTED,
        ICO,
        PAUSED,
        ENDED
    }
    
    Stages public currentStage;
    
    modifier onlyOwner() {
        require(msg.sender == icoData.owner);
        _;
    }
    
    modifier atStage(Stages stage) {
        require(currentStage == stage);
        _;
    }
    
    function ADBToken() public {
        icoData.owner = msg.sender;
        balances[icoData.owner] = icoData.totalTokens;
        currentStage = Stages.NOTSTARTED;
        Transfer(0, icoData.owner, balances[icoData.owner]);
    }
    
    function () public payable atStage(Stages.ICO) {
        require(icoData.totalRaised < 44000 ether);
        require(!icoData.icoEnded && !icoData.paused && now <= icoData.icoDeadline);
        
        icoData.totalRaised = icoData.raised.add(msg.value);
        
        if (icoData.totalRaised > 44000 ether) {
            icoData.excess = icoData.totalRaised.sub(44000 ether);
            msg.sender.transfer(icoData.excess);
            icoData.raised = 44000 ether;
        } else {
            icoData.raised = icoData.raised.add(msg.value);
        }
    }
    
    function startICO() external onlyOwner atStage(Stages.NOTSTARTED) {
        currentStage = Stages.ICO;
        icoData.paused = false;
        icoData.icoStartTime = now;
        icoData.icoDeadline = now.add(39 days);
    }
    
    function pauseICO() external onlyOwner atStage(Stages.ICO) {
        icoData.paused = true;
        currentStage = Stages.PAUSED;
    }
    
    function resumeICO() external onlyOwner atStage(Stages.PAUSED) {
        icoData.paused = false;
        currentStage = Stages.ICO;
    }
    
    function endICO() external onlyOwner atStage(Stages.ICO) {
        require(now > icoData.icoDeadline);
        icoData.icoEnded = true;
        currentStage = Stages.ENDED;
    }
    
    function withdraw() external onlyOwner {
        icoData.owner.transfer(this.balance);
    }
    
    function totalSupply() public view returns (uint256 totalTokens) {
        totalTokens = icoData.totalTokens;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != 0x0);
        require(balances[msg.sender] >= tokens && tokens >= 0);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(to != 0x0);
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens >= 0);
        
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
    function approve(address spender, uint256 tokens) public returns (bool success) {
        require(spender != 0x0);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        require(tokenOwner != 0x0 && spender != 0x0);
        return allowed[tokenOwner][spender];
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != 0x0);
        balances[newOwner] = balances[newOwner].add(balances[icoData.owner]);
        balances[icoData.owner] = 0;
        icoData.owner = newOwner;
    }
    
    struct ICOData {
        bool icoEnded;
        uint256 excess;
        uint256 totalRaised;
        uint256 icoDeadline;
        uint256 icoStartTime;
        uint256 raised;
        bool paused;
        address owner;
        uint256 totalTokens;
        uint8 decimals;
    }
    
    ICOData icoData = ICOData(
        false,
        0,
        0,
        0,
        0,
        0,
        true,
        address(0),
        (1000000000) * (10 ** 18),
        18
    );
}
```