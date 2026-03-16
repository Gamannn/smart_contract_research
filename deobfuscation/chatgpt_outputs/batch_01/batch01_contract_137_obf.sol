pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract ERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Extended is ERC20 {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20 {
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

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20Extended, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) internal onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract TokenizedEther is StandardToken, Ownable {
    using SafeMath for uint256;

    string public constant name = "Ether Token";
    string public constant symbol = "WXETH";
    uint8 public constant decimals = 18;

    event Issuance(uint256 amount);
    event Destruction(uint256 amount);

    struct ContractState {
        address admin;
        bool active;
        uint256 totalSupply;
        uint256 maxSupply;
        address owner;
        uint256 totalEther;
    }

    ContractState public state;

    function TokenizedEther() public {
        state = ContractState({
            admin: msg.sender,
            active: true,
            totalSupply: 0,
            maxSupply: 2**256 - 1,
            owner: msg.sender,
            totalEther: 0
        });
    }

    function toggleActive(bool _active) public onlyOwner {
        state.active = !_active;
    }

    function emergencyWithdraw() public onlyOwner {
        require(!state.active);
        require(state.totalEther > 0);
        require(state.admin != 0x0);

        uint256 amount = state.totalEther;
        state.totalEther = state.totalEther.sub(state.totalEther);
        Transfer(state.admin, this, state.totalEther);
        Destruction(state.totalEther);
        state.admin.transfer(amount);
    }

    function () public payable {
        require(state.active);
        depositEther(msg.sender);
    }

    function depositEther(address _to) public payable {
        require(state.active);
        require(_to != 0x0);
        require(msg.value != 0);

        balances[_to] = balances[_to].add(msg.value);
        state.totalEther = state.totalEther.add(msg.value);
        Issuance(msg.value);
        Transfer(this, _to, msg.value);
    }

    function withdrawEther(uint256 _amount) public {
        require(state.active);
        withdrawEtherTo(msg.sender, _amount);
    }

    function withdrawEtherTo(address _to, uint256 _amount) public {
        require(state.active);
        require(_to != 0x0);
        require(_amount != 0);
        require(_amount <= balances[_to]);
        require(this != _to);

        balances[_to] = balances[_to].sub(_amount);
        state.totalEther = state.totalEther.sub(_amount);
        Transfer(msg.sender, this, _amount);
        Destruction(_amount);
        _to.transfer(_amount);
    }
}