pragma solidity ^0.4.17;

contract ERC20Interface {
    function transfer(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns (uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

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

contract Token {
    string internal _symbol;
    string internal _name;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balanceOf;
    mapping(address => mapping(address => uint256)) internal _allowances;

    function Token(string symbol, string name, uint8 decimals, uint256 totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }

    function name() public constant returns (string) {
        return _name;
    }

    function symbol() public constant returns (string) {
        return _symbol;
    }

    function decimals() public constant returns (uint8) {
        return _decimals;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public constant returns (uint) {
        return _balanceOf[_addr];
    }

    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

contract DEVWEBVUA is Token("DWD1", "DEV WEBVUA 1", 18, 8888888888 * (10 ** 18)), ERC20Interface {
    using SafeMath for uint;

    address public owner;

    function DEVWEBVUA() public {
        owner = msg.sender;
        _balanceOf[owner] = _totalSupply;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public constant returns (uint) {
        return _balanceOf[_addr];
    }

    function() public payable {
        uint256 numberOfTokens = returnTokenYearLimit(msg.value) * (10 ** 18);
        _balanceOf[msg.sender] = _balanceOf[msg.sender].add(numberOfTokens);
        _balanceOf[address(0)] = _balanceOf[address(0)].sub(numberOfTokens);
        Transfer(address(0), msg.sender, numberOfTokens);
    }

    function returnTokenYearLimit(uint256 valueEther) view public returns (uint256) {
        if (block.timestamp < 1618987143) {
            return valueEther.div(625000000000000);
        }
        if (block.timestamp < 1650526023 && block.timestamp >= 1618987143) {
            return valueEther.div(1250000000000000);
        }
        if (block.timestamp < 1682062023 && block.timestamp >= 1650526023) {
            return valueEther.div(2500000000000000);
        }
    }

    function transfer(address _to, uint _value) public returns (bool) {
        if (_value > 0 && _value <= _balanceOf[msg.sender] && !isContract(_to)) {
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function isContract(address _addr) private constant returns (bool) {
        uint codeSize;
        assembly { codeSize := extcodesize(_addr) }
        return codeSize > 0;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (_allowances[_from][msg.sender] > 0 && _value > 0 && _allowances[_from][msg.sender] >= _value && _balanceOf[_from] >= _value) {
            _balanceOf[_from] = _balanceOf[_from].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint) {
        return _allowances[_owner][_spender];
    }
}