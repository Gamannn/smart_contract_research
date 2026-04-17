pragma solidity ^0.4.19;

contract Ox130e6c8299b3c0402cbca94336c12af74e268d0d {
    address public owner;
    uint256 public totalSupply;
    uint256 public balance;
    uint256 public fee;
    uint256 public randomNumber;
    uint256 public mined;
    uint256 public minReward;
    uint256 public reducer;
    uint8 public decimals;
    string public name;
    string public symbol;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => uint256) public minedCount;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    function Ox130e6c8299b3c0402cbca94336c12af74e268d0d() public {
        owner = msg.sender;
        mined = msg.sender;
        balance = totalSupply;
        balances[this] = totalSupply - balances[owner];
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(balances[from] >= value);
        require(balances[to] + value > balances[to]);
        
        uint256 previousBalances = balances[from] + balances[to];
        balances[from] -= value;
        balances[to] += value;
        Transfer(from, to, value);
        assert(balances[from] + balances[to] == previousBalances);
    }
    
    function transfer(address to, uint256 value) external {
        _transfer(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool success) {
        require(value <= allowed[from][msg.sender]);
        allowed[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) external returns (bool success) {
        allowed[msg.sender][spender] = value;
        return true;
    }
    
    function withdrawEther() external onlyOwner {
        owner.transfer(fee);
        fee = 0;
    }
    
    function () external payable {
        if (msg.value == 0) {
            randomNumber += block.timestamp + uint(msg.sender);
            uint blockHash = uint(block.blockhash(block.number - 1));
            uint hash = uint(sha256(blockHash + randomNumber + uint(msg.sender))) % 10000000;
            uint balanceRatio = balances[msg.sender] * 1000 / totalSupply;
            
            if (balanceRatio >= 1) {
                if (balanceRatio > 255) {
                    balanceRatio = 255;
                }
                uint minedHash = 2 ** balanceRatio;
                uint minedRatio = 50000 * minedHash;
                uint balanceRel = 5000000 - balanceRatio;
                
                if (minedRatio > balanceRel) {
                    uint reward = mined + hash * 1000 / reducer * 100000000000000;
                    _transfer(this, msg.sender, reward);
                    minedCount[msg.sender]++;
                } else {
                    Transfer(this, msg.sender, 0);
                    minedCount[msg.sender]++;
                }
                fee += msg.value;
                reducer++;
            } else {
                revert();
            }
        } else {
            revert();
        }
    }
}