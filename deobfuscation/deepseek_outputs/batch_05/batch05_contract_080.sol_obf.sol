```solidity
pragma solidity 0.4.25;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
        return c;
    }
    
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
        return c;
    }
    
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint c) {
        c = a / b;
        return c;
    }
}

contract ERC20 {
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function balanceOf(address _owner) public view returns (uint balance) {
        return balanceOf[_owner];
    }
    
    function transfer(address _to, uint _value) public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        uint allowed = allowance[_from][msg.sender];
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowed.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool success) {
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowance[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
}

contract SHIT is ERC20 {
    uint public icoStartTime;
    uint public tokensSold;
    uint public icoCollected;
    address public bank1;
    
    uint public bank1Val;
    uint public bank2Val;
    uint public bank1Reserve;
    
    address public bank2;
    
    uint public hardCap;
    
    enum IcoStates { Ico, Done }
    IcoStates public icoState;
    
    constructor() public {
        name = "SHIT";
        symbol = "SHIT";
        decimals = 18;
        totalSupply = 100500 ether;
        owner = msg.sender;
        hardCap = 100500 ether;
    }
    
    function() public payable {
        uint tokens;
        uint rate;
        uint remainingTokens = hardCap - tokensSold;
        
        uint halfVal = msg.value / 2;
        
        if (icoState == IcoStates.Ico && tokensSold < (hardCap / 2)) {
            tokens = remainingTokens;
            bank1Reserve = tokens;
            balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
            tokensSold = tokensSold.add(tokens);
            
            if (tokensSold > hardCap) {
                revert();
            }
            
            emit Transfer(msg.sender, address(0), tokens);
            icoCollected = icoCollected.add(msg.value);
        }
        
        bank1Val = bank1Val.add(halfVal);
        bank2Val = bank2Val.add(halfVal);
        bank1Reserve = remainingTokens - (tokens * 2);
    }
    
    function setBanks(address _bank1, address _bank2) public onlyOwner {
        require(bank1 == address(0));
        require(bank2 == address(0));
        require(_bank1 != address(0));
        require(_bank2 != address(0));
        
        bank1 = _bank1;
        bank2 = _bank2;
        
        balanceOf[bank1] = 25627 ether;
        balanceOf[bank2] = 25627 ether;
    }
    
    function startIco() public onlyOwner {
        icoState = IcoStates.Ico;
    }
    
    function finishIco() public onlyOwner {
        icoState = IcoStates.Done;
    }
    
    function withdraw() public {
        require(msg.sender == bank1 || msg.sender == bank2);
        
        if (msg.sender == bank1) {
            bank1.transfer(bank1Val);
            bank1Val = 0;
        }
        
        if (msg.sender == bank2) {
            bank2.transfer(bank2Val);
            bank2Val = 0;
        }
    }
}
```