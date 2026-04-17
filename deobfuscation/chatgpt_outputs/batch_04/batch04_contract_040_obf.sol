pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract Stoppable is Pausable {
    event Stop();

    bool public stopped = false;

    modifier whenNotStopped() {
        require(!stopped);
        _;
    }

    function stop() onlyOwner whenNotStopped public {
        stopped = true;
        emit Stop();
    }
}

contract Token is StandardToken, Stoppable {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _initialSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
}

contract Airdrop is Stoppable {
    using SafeMath for uint256;

    address public tokenAddress;
    uint256 public tokenAmount;
    uint256 public ethAmount;
    mapping(address => bool) public usedAddresses;

    constructor(address _tokenAddress, uint256 _tokenAmount, uint256 _ethAmount) public {
        tokenAddress = _tokenAddress;
        tokenAmount = _tokenAmount;
        ethAmount = _ethAmount;
    }

    function verifySignature(
        address signer,
        address signedAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signedAddress));
        return ecrecover(messageHash, v, r, s) == signer;
    }

    function claimTokens(
        address receiver,
        address transitAddress,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) public whenNotStopped returns (bool) {
        require(!usedAddresses[transitAddress]);
        require(verifySignature(tokenAddress, transitAddress, v1, r1, s1));
        require(verifySignature(transitAddress, receiver, v2, r2, s2));
        require(address(this).balance >= ethAmount);

        usedAddresses[transitAddress] = true;

        Token token = Token(tokenAddress);
        token.transfer(receiver, tokenAmount);

        if (ethAmount > 0) {
            receiver.transfer(ethAmount);
        }

        return true;
    }

    function isLinkClaimed(address transitAddress) public view returns (bool) {
        return usedAddresses[transitAddress];
    }

    function withdrawEther() public onlyOwner returns (bool) {
        owner.transfer(address(this).balance);
        return true;
    }
}