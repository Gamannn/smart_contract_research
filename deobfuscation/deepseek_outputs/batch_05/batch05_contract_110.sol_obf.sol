pragma solidity ^0.4.19;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
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

contract AirdropToken is ERC20 {
    mapping(address => uint32) public airdropCount;
    event Airdrop(address indexed recipient, uint32 indexed count, uint256 amount);
    
    function receiveAirdrop() public payable {
        require(now >= airdropStartTime && now <= airdropEndTime);
        require(msg.value == 0);
        if (airdropCount[msg.sender] >= airdropLimit) {
            revert();
        }
        _transfer(airdropSender, msg.sender, airdropAmount);
        airdropCount[msg.sender] += 1;
        Airdrop(msg.sender, airdropCount[msg.sender], airdropAmount);
    }
}

contract ICOToken is ERC20 {
    event ICO(address indexed buyer, uint256 indexed ethAmount, uint256 tokenAmount);
    event Withdraw(address indexed from, address indexed to, uint256 amount);
    
    function buyTokens() public payable {
        require(now >= icoStartTime && now <= icoEndTime);
        require(msg.value >= minPurchase);
        uint256 tokenAmount = (msg.value * icoRatio * 10 ** decimals) / (1 ether / 1 wei);
        if (tokenAmount == 0 || balanceOf[tokenHolder] < tokenAmount) {
            revert();
        }
        _transfer(tokenHolder, msg.sender, tokenAmount);
        ICO(msg.sender, msg.value, tokenAmount);
    }
    
    function withdraw() public {
        uint256 balance = this.balance;
        withdrawAddress.transfer(balance);
        Withdraw(msg.sender, withdrawAddress, balance);
    }
}

contract MainToken is ERC20, AirdropToken, ICOToken {
    address public tokenHolder;
    address public airdropSender;
    address public withdrawAddress;
    uint256 public airdropAmount;
    uint256 public airdropStartTime;
    uint256 public airdropEndTime;
    uint32 public airdropLimit;
    uint256 public icoStartTime;
    uint256 public icoEndTime;
    uint256 public icoRatio;
    uint256 public minPurchase;
    
    function MainToken() public {
        totalSupply = 99000000000000000;
        name = "Oxde05fb6b65db56c615fab78cf9a4db72a4260098";
        symbol = "GCHAIN";
        decimals = 8;
        
        tokenHolder = 0xA89d7a553Da4E313c7F77A1F7f16B9FACF538349;
        balanceOf[0xa0f236796BE660F1ad18F56b0Da91516882aE049] = totalSupply;
        Transfer(address(0), 0xa0f236796BE660F1ad18F56b0Da91516882aE049, totalSupply);
        
        airdropAmount = 10000000;
        airdropStartTime = 1532736000;
        airdropEndTime = 1532736300;
        airdropSender = 0xa0f236796BE660F1ad18F56b0Da91516882aE049;
        airdropLimit = 1;
        
        icoStartTime = 1532736300;
        icoEndTime = 1538265540;
        icoRatio = 1000;
        minPurchase = 100000000;
        withdrawAddress = 0xA89d7a553Da4E313c7F77A1F7f16B9FACF538349;
    }
    
    function() public payable {
        if (msg.value == 0) {
            receiveAirdrop();
        } else {
            buyTokens();
        }
    }
}