```solidity
pragma solidity ^0.4.8;

contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function transfer(address _to, uint _value) returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract BOPToken is ERC20 {
    string public name = "blockop";
    string public symbol = "BOP";
    uint8 public decimals = 8;
    
    uint public ico_start;
    mapping(uint => uint) public tokensSent;
    
    event preico(uint index, address investor, uint weiReceived, uint tokensSent);
    event ico(uint index, address investor, uint weiReceived, uint tokensSent);
    
    uint public counter = 0;
    uint public profit_sent = 0;
    
    address public owner;
    bool public stopped = false;
    uint public pre_ico_start = now;
    uint public pre_ico_end = pre_ico_start + 16 days;
    uint public ico_end;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    uint public _totalSupply = 20000000 * 10**8;
    
    function BOPToken() {
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
    }
    
    function changeOwner(address newOwner) onlyOwner {
        balances[newOwner] = balances[owner];
        balances[owner] = 0;
        owner = newOwner;
    }
    
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint a, uint b) internal returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    
    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }
    
    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c >= a && c >= b);
        return c;
    }
    
    function require(bool condition) internal {
        if (!condition) {
            revert();
        }
    }
    
    function transfer(address _to, uint _value) returns (bool) {
        uint check = balances[owner] - _value;
        
        if (msg.sender == owner && now >= pre_ico_start && now <= pre_ico_end && check < 1900000000000000) {
            return false;
        } else if (pre_ico_end == (pre_ico_start + 16 days) && check < 1850000000000000) {
            return false;
        } else if (msg.sender == owner && check < 200000000000000 && now < ico_start + 180 days) {
            return false;
        } else if (msg.sender == owner && check < 97500000000000 && now < ico_start + 180 days) {
            return false;
        } else if (msg.sender == owner && check < 43000000000000 && now < ico_start + 180 days) {
            return false;
        } else if (_value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if (_value > 0) {
            var allowanceAmount = allowed[_from][msg.sender];
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowanceAmount, _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    function withdraw() onlyOwner {
        owner.send(this.balance);
    }
    
    function () payable {
        if (stopped && msg.sender != owner) {
            revert();
        } else if (msg.sender == owner) {
            profit_sent = msg.value;
        } else if (now >= pre_ico_start && now <= pre_ico_end) {
            uint check = balances[owner] - ((400 * msg.value) / 10000000000);
            if (check >= 1900000000000000) {
                processPreICO(msg.sender, msg.value);
            }
        } else if (now >= ico_start && now < ico_end) {
            processICO(msg.sender, msg.value);
        }
    }
    
    function processPreICO(address investor, uint weiReceived) private {
        counter = counter + 1;
        address[] memory investors;
        uint[] memory weiReceivedArray;
        investors[counter] = investor;
        weiReceivedArray[counter] = weiReceived;
        tokensSent[counter] = (400 * weiReceived) / 10000000000;
        balances[owner] = balances[owner] - tokensSent[counter];
        balances[investors[counter]] = balances[investors[counter]] + tokensSent[counter];
        preico(counter, investors[counter], weiReceivedArray[counter], tokensSent[counter]);
    }
    
    function processICO(address investor, uint weiReceived) private {
        if (now >= ico_start && now <= (ico_start + 7 days)) {
            counter = counter + 1;
            address[] memory investors;
            uint[] memory weiReceivedArray;
            investors[counter] = investor;
            weiReceivedArray[counter] = weiReceived;
            tokensSent[counter] = (250 * weiReceived) / 10000000000;
            balances[owner] = balances[owner] - tokensSent[counter];
            balances[investors[counter]] = balances[investors[counter]] + tokensSent[counter];
            ico(counter, investors[counter], weiReceivedArray[counter], tokensSent[counter]);
        } else if (now >= (ico_start + 7 days) && now <= (ico_start + 14 days)) {
            counter = counter + 1;
            address[] memory investors;
            uint[] memory weiReceivedArray;
            investors[counter] = investor;
            weiReceivedArray[counter] = weiReceived;
            tokensSent[counter] = (220 * weiReceived) / 10000000000;
            balances[owner] = balances[owner] - tokensSent[counter];
            balances[investors[counter]] = balances[investors[counter]] + tokensSent[counter];
            ico(counter, investors[counter], weiReceivedArray[counter], tokensSent[counter]);
        } else if (now >= (ico_start + 14 days) && now <= (ico_start + 21 days)) {
            counter = counter + 1;
            address[] memory investors;
            uint[] memory weiReceivedArray;
            investors[counter] = investor;
            weiReceivedArray[counter] = weiReceived;
            tokensSent[counter] = (200 * weiReceived) / 10000000000;
            balances[owner] = balances[owner] - tokensSent[counter];
            balances[investors[counter]] = balances[investors[counter]] + tokensSent[counter];
            ico(counter, investors[counter], weiReceivedArray[counter], tokensSent[counter]);
        }
    }
    
    function startICO() onlyOwner {
        ico_start = now;
        ico_end = ico_start + 31 days;
        pre_ico_start = 0;
        pre_ico_end = 0;
    }
    
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }
    
    function stopICO() onlyOwner {
        stopped = true;
        if (balances[owner] > 130000000000000) {
            uint diff = balances[owner] - 130000000000000;
            _totalSupply = _totalSupply - diff;
            balances[owner] = 130000000000000;
        }
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    uint256[] public _integer_constant = [43000000000000, 46656000, 604800, 2678400, 31104000, 0, 97500000000000, 220, 15552000, 1, 1900000000000000, 200, 8, 1850000000000000, 20000000, 400, 1382400, 1209600, 130000000000000, 10, 250, 10000000000];
    string[] public _string_constant = ["Ox49e8456378624d08f87499af802f450f894eace0", "BOP"];
    bool[] public _bool_constant = [false, true];
}
```