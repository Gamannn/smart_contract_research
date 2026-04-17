```solidity
pragma solidity ^0.4.19;

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

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract Crowdsale {
    using SafeMath for uint256;
    
    address public wallet;
    bool public isFinalized = false;
    bool public goalReached = false;
    uint256 public weiRaised;
    uint256 public deadline;
    
    event ContractEthReceived(address indexed sender, uint256 amount);
    event ContractEthTransfer(address indexed to, uint256 amount);
    
    function Crowdsale(address _wallet, uint256 _deadline) public {
        require(_deadline > now);
        wallet = _wallet;
        deadline = _deadline;
    }
    
    function () external payable {
        require(deadline > now);
        ContractEthReceived(msg.sender, msg.value);
        
        if (address(this).balance != 50000000000000000) return;
        
        goalReached = true;
        uint256 amount = address(this).balance;
        
        uint256 commission = amount.mul(5).div(100);
        address commissionWallet = 0xEB0199F3070E86ea6DF6e3B4A7862C28a7574be0;
        
        commissionWallet.transfer(commission);
        
        uint256 remainingAmount = amount.sub(commission);
        wallet.transfer(remainingAmount);
    }
    
    function transferToken(address tokenAddress, uint256 amount) payable public {
        require(msg.sender == wallet);
        require(canTransfer());
        
        ERC20Basic token = ERC20Basic(tokenAddress);
        token.transfer(wallet, amount);
    }
    
    function transferEth(address recipient, uint256 amount) payable public {
        require(msg.sender == wallet);
        require(recipient != address(0));
        require(address(this).balance >= amount);
        require(address(this) != recipient);
        require(canTransfer());
        
        require(recipient.call.value(amount)());
        ContractEthTransfer(recipient, amount);
    }
    
    function finalize() payable public {
        require(!isFinalized);
        require(msg.sender == wallet);
        
        isFinalized = true;
        wallet = 0x3036701878BEF791FdCE9Cb95a99278eED5Cf2Ec;
    }
    
    function canTransfer() internal view returns (bool) {
        if (isFinalized) return true;
        if (deadline < now) return false;
        if (!goalReached) return false;
        
        bool nonZero = msg.value != 0;
        bool belowLimit = address(this).balance <= 50000000000000000;
        
        return nonZero && belowLimit && goalReached;
    }
}
```