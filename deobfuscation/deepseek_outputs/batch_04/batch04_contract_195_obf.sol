pragma solidity ^0.4.19;

contract ERC20 {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        
        uint256 previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
        
        Transfer(from, to, value);
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
}

contract Airdrop is ERC20 {
    mapping (address => uint32) public airdropCount;
    
    event Airdrop(address indexed recipient, uint32 indexed count, uint256 amount);
    
    function receiveAirdrop() public payable {
        require(now >= 1522029600 && now <= 1522036800);
        require(msg.value == 0);
        
        if (airdropCount[msg.sender] >= 10) {
            revert();
        }
        
        _transfer(0xfb3eb237657ed64e4ec8ae40da2a02e3dbaab2505f, msg.sender, 20000000000000000000);
        airdropCount[msg.sender] += 1;
        Airdrop(msg.sender, airdropCount[msg.sender], 20000000000000000000);
    }
}

contract ICO is ERC20 {
    event ICO(address indexed buyer, uint256 indexed ethAmount, uint256 tokenAmount);
    event Withdraw(address indexed from, address indexed to, uint256 value);
    
    function buyTokens() public payable {
        require(now >= 1434 && now <= 1837656000);
        uint256 tokenAmount = (msg.value * 3000 * 1 * 10**18) / (1 ether / 1 wei);
        
        if (tokenAmount == 0 || balanceOf[0xfb3eb237657ed64e4ec8ae40da2a02e3dbaab2505f] < tokenAmount) {
            revert();
        }
        
        _transfer(0xfb3eb237657ed64e4ec8ae40da2a02e3dbaab2505f, msg.sender, tokenAmount);
        ICO(msg.sender, msg.value, tokenAmount);
    }
    
    function withdraw() public {
        uint256 balance = this.balance;
        address(0xfb3eb237657ed64e4ec8ae40da2a02e3dbaab2505f).transfer(balance);
        Withdraw(msg.sender, 0xfb3eb237657ed64e4ec8ae40da2a02e3dbaab2505f, balance);
    }
}

contract FOF is ERC20, Airdrop, ICO {
    function FOF() public {
        totalSupply = 21000000000000000000000000000;
        name = 'FundofFunds';
        symbol = 'FOF';
        decimals = 18;
        
        balanceOf[0xfb3eb237657ed64e4ec8ae40da2a02e3dbaab2505f] = totalSupply;
        
        airdropAmount = 20000000000000000000;
        airdropBeginTime = 1522029600;
        airdropEndTime = 1522036800;
        airdropSender = 0xfb3eb237657ed64e4ec8ae40da2a02e3dbaab2505f;
        airdropLimitCount = 10;
        
        icoRatio = 3000;
        icoBeginTime = 1434;
        icoEndTime = 1837656000;
        icoSender = 0xfb3eb237657ed64e4ec8ae40da2a02e3dbaab2505f;
        icoHolder = 0xfb3eb237657ed64e4ec8ae40da2a02e3dbaab2505f;
    }
    
    function() public payable {
        if (msg.value == 0) {
            receiveAirdrop();
        } else {
            buyTokens();
        }
    }
    
    struct Config {
        address withdrawAddress;
        address tokenHolder;
        uint256 icoEndTime;
        uint256 icoBeginTime;
        uint256 tokenMultiplier;
        uint32 airdropLimitCount;
        address airdropSender;
        uint256 airdropAmount;
        uint256 airdropBeginTime;
        uint256 airdropEndTime;
        uint256 totalSupply;
        uint8 decimals;
        string symbol;
        string name;
    }
    
    Config config = Config(address(0), address(0), 0, 0, 1, 0, address(0), 0, 0, 0, 0, 0, "", "");
}