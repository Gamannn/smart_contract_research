```solidity
pragma solidity ^0.4.24;

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

contract ERC20Basic {
    uint256 public totalSupply;
    
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
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
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) allowed;
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        var _allowance = allowed[_from][msg.sender];
        
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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
    
    function pause() public onlyOwner {
        paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwner {
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
    
    function stop() public onlyOwner {
        stopped = true;
        emit Stop();
    }
}

contract AirdropEscrow is Stoppable {
    address public tokenAddress;
    uint public claimAmountTokens;
    uint public claimAmountEth;
    address public airdropTransitAddress;
    address public airdropper;
    
    mapping(address => bool) public usedTransitAddresses;
    
    constructor(
        address _tokenAddress,
        uint _claimAmountTokens,
        uint _claimAmountEth,
        address _airdropTransitAddress,
        address _airdropper
    ) public {
        tokenAddress = _tokenAddress;
        claimAmountTokens = _claimAmountTokens;
        claimAmountEth = _claimAmountEth;
        airdropTransitAddress = _airdropTransitAddress;
        airdropper = _airdropper;
    }
    
    function verifySignature(
        address _signer,
        address _signedAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns(bool) {
        bytes32 hash = keccak256("\x19Ethereum Signed Message:\n32", _signedAddress);
        address recovered = ecrecover(hash, v, r, s);
        return recovered == _signer;
    }
    
    function verifyClaimParams(
        address _receiver,
        address _transitAddress,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) public view returns(bool) {
        require(usedTransitAddresses[_transitAddress] == false);
        require(verifySignature(airdropper, _transitAddress, v1, r1, s1));
        require(verifySignature(_transitAddress, _receiver, v2, r2, s2));
        require(address(this).balance >= claimAmountEth);
        return true;
    }
    
    function claim(
        address _receiver,
        address _transitAddress,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) public whenNotPaused whenNotStopped returns (bool) {
        require(verifyClaimParams(_receiver, _transitAddress, v1, r1, s1, v2, r2, s2));
        
        usedTransitAddresses[_transitAddress] = true;
        
        StandardToken token = StandardToken(tokenAddress);
        token.transferFrom(airdropper, _receiver, claimAmountTokens);
        
        if (claimAmountEth > 0) {
            _receiver.transfer(claimAmountEth);
        }
        
        return true;
    }
    
    function isLinkClaimed(address _transitAddress) public view returns (bool) {
        return usedTransitAddresses[_transitAddress];
    }
    
    function withdrawEther() public returns (bool) {
        require(msg.sender == airdropper);
        airdropper.transfer(address(this).balance);
        return true;
    }
    
    function() public payable {}
}
```