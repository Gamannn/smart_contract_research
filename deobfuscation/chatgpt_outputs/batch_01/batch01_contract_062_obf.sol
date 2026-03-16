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
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract ADBToken is ERC20Interface {
    using SafeMath for uint256;

    string public constant name = "ADB";
    string public constant symbol = "ADB";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    enum Stages { NOTSTARTED, ICO, PAUSED, ENDED }
    Stages public stage;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    struct ICOInfo {
        bool isEnded;
        uint256 refundAmount;
        uint256 totalRaised;
        uint256 endTime;
        uint256 startTime;
        uint256 tokensSold;
        bool isPaused;
        address owner;
        uint256 totalSupply;
        uint8 decimals;
    }

    ICOInfo public icoInfo;

    function ADBToken() public {
        icoInfo.owner = msg.sender;
        balances[icoInfo.owner] = icoInfo.totalSupply;
        stage = Stages.NOTSTARTED;
        Transfer(0, icoInfo.owner, balances[icoInfo.owner]);
    }

    function () public payable atStage(Stages.ICO) {
        require(icoInfo.totalRaised < 44000 ether);
        require(!icoInfo.isPaused && !icoInfo.isEnded && now <= icoInfo.endTime);

        icoInfo.totalRaised = icoInfo.totalRaised.add(msg.value);

        if (icoInfo.totalRaised > 44000 ether) {
            icoInfo.refundAmount = icoInfo.totalRaised.sub(44000 ether);
            msg.sender.transfer(icoInfo.refundAmount);
            icoInfo.tokensSold = 44000 ether;
        } else {
            icoInfo.tokensSold = icoInfo.tokensSold.add(msg.value);
        }
    }

    function startICO() external onlyOwner atStage(Stages.NOTSTARTED) {
        stage = Stages.ICO;
        icoInfo.isPaused = false;
        icoInfo.startTime = now;
        icoInfo.endTime = now.add(39 days);
    }

    function pauseICO() external onlyOwner atStage(Stages.ICO) {
        icoInfo.isPaused = true;
        stage = Stages.PAUSED;
    }

    function resumeICO() external onlyOwner atStage(Stages.PAUSED) {
        icoInfo.isPaused = false;
        stage = Stages.ICO;
    }

    function endICO() external onlyOwner atStage(Stages.ICO) {
        require(now > icoInfo.endTime);
        icoInfo.isEnded = true;
        stage = Stages.ENDED;
    }

    function withdrawFunds() external onlyOwner {
        icoInfo.owner.transfer(this.balance);
    }

    function totalSupply() public view returns (uint256) {
        return icoInfo.totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        require(balances[msg.sender] >= tokens && tokens >= 0);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens >= 0);

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        require(spender != address(0));
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        require(tokenOwner != address(0) && spender != address(0));
        return allowed[tokenOwner][spender];
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        balances[newOwner] = balances[newOwner].add(balances[icoInfo.owner]);
        balances[icoInfo.owner] = 0;
        icoInfo.owner = newOwner;
    }
}