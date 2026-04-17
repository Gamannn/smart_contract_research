```solidity
pragma solidity ^0.4.22;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract Token is BasicToken, Ownable, ERC20 {
    using SafeMath for uint256;
    
    address public TRANSFER_PROXY;
    mapping (address => bool) private signers;
    string public name;
    string public symbol;
    address public feeAddress = address(0);
    mapping (address => uint256) public lockTime;
    
    function Token(
        string _name,
        string _symbol,
        uint256 _totalSupply,
        address _TRANSFER_PROXY
    ) public {
        name = _name;
        symbol = _symbol;
        totalSupply_ = _totalSupply;
        balances[owner] = _totalSupply;
        TRANSFER_PROXY = _TRANSFER_PROXY;
        signers[TRANSFER_PROXY] = true;
    }
    
    function deposit(uint _value, uint _forTime) public payable returns (bool) {
        require(_forTime >= 1);
        require(now + _forTime * 1 hours >= lockTime[msg.sender]);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        lockTime[msg.sender] = now + _forTime * 1 hours;
        return true;
    }
    
    function withdraw(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint _value,
        uint _block
    ) public returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        
        if (now > lockTime[msg.sender]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            msg.sender.transfer(_value);
        } else {
            require(block.number < _block);
            require(isValidSignature(
                keccak256(msg.sender, address(this), _block),
                v, r, s
            ));
            balances[msg.sender] = balances[msg.sender].sub(_value);
            msg.sender.transfer(_value);
        }
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        return false;
    }
    
    function transferFrom(address _from, address _to, uint _value) public {
        require(_to == owner || _from == owner);
        assert(msg.sender == TRANSFER_PROXY);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint) {
        if (_spender == TRANSFER_PROXY) {
            return 2**256 - 1;
        }
    }
    
    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }
    
    function isValidSignature(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public constant returns (bool) {
        return signers[ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            v, r, s
        )];
    }
    
    function addSigner(address _signer) public {
        require(signers[msg.sender]);
        signers[_signer] = true;
    }
    
    function getHash(address _target, uint _nonce) public constant returns(bytes32) {
        return keccak256(_target, _target, _nonce);
    }
}
```