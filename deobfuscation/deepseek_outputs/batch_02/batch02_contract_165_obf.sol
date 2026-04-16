```solidity
pragma solidity ^0.4.18;

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
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
}

contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);
    
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}

contract Ownable {
    address public owner;
    address public pendingOwner;
    address private candidateOwner = 0x615B255EEE9cdb8BF1FA7db3EE101106673E8DCB;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract StandardToken is ERC20Basic, BasicToken {
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
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
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
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    
    bool public mintingFinished = false;
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
    
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
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
    
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }
    
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }
    
    function safeTransferFrom(ERC20Basic token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }
    
    function safeApprove(ERC20Basic token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract TokenTimelock {
    using SafeERC20 for ERC20Basic;
    
    ERC20Basic public token;
    address public beneficiary;
    uint256 public releaseTime;
    
    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }
    
    function release() public {
        require(now >= releaseTime);
        require(token.balanceOf(this) > 0);
        token.safeTransfer(beneficiary, token.balanceOf(this));
    }
}

contract PlasmaBankToken is MintableToken, PausableToken, BurnableToken {
    string public name = "PlasmaBank Token";
    string public symbol = "PBK";
    uint8 public decimals = 2;
    
    mapping(address => bool) public burners;
    
    event ReceivedEther(address from, uint256 amount);
    event WithdrewEther(address to, uint256 amount);
    
    address PlasmaPrivateTokenSale = 0xec0767B180C05B261A23744cCF8EB89b677dFeE1;
    address PlasmaPreTokenSaleReserve = 0x2910dB084a467131C121626987b3F8b69ebaE82A;
    address PlasmaTokenSaleReserve = 0x5ed22d37BB1A16a15E9a2dD6F46b9C891164916B;
    address PlasmaFoundationReserve = 0xdbf81Af07e37ec855653de1dB152E578d847f215;
    address PlasmaTeamOptionsReserveAddress = 0x831360b8Dd93692d1A0Bdf7fdE8C037BaB1CE631;
    address PlasmaFrozenForInstitutionalSales = 0x04D20280B1E870688B7552E14171923215D3411C;
    address PlasmaReserveForAdvisors = 0x88bF0Ae762B801943190D1B7D757103BA9Dd6eAb;
    address PlasmaReserveForBonusForTopManagement = 0x6Df994BdCA65f6bdAb66c72cd3fE3666cc183E37;
    address PlasmaReserveForBounty = 0xF0dbBDb93344Bc679F8f0CffAE187D324917F44b;
    address PlasmaFrozenForTokenSale2020 = 0x67F585f3EB7363E26744aA19E8f217D70e7E0001;
    
    function PlasmaBankToken() public {
        mint(PlasmaPrivateTokenSale, 200000000 * (10 ** uint256(decimals)));
        mint(PlasmaPreTokenSaleReserve, 3200000000 * (10 ** uint256(decimals)));
        mint(PlasmaTokenSaleReserve, 100000000 * (10 ** uint256(decimals)));
        mint(PlasmaFoundationReserve, 100000000 * (10 ** uint256(decimals)));
        mint(PlasmaTeamOptionsReserveAddress, 800000000 * (10 ** uint256(decimals)));
        mint(PlasmaFrozenForInstitutionalSales, 500000000 * (10 ** uint256(decimals)));
        mint(PlasmaReserveForAdvisors, 300000000 * (10 ** uint256(decimals)));
        mint(PlasmaReserveForBonusForTopManagement, 1000000000 * (10 ** uint256(decimals)));
        mint(PlasmaReserveForBounty, 1500000000 * (10 ** uint256(decimals)));
        mint(PlasmaFrozenForTokenSale2020, 1500000000 * (10 ** uint256(decimals)));
        totalSupply_ = 10000000000 * (10 ** uint256(decimals));
        finishMinting();
    }
    
    function transferTimelocked(address _to, uint256 _amount, uint256 _releaseTime) public returns (TokenTimelock) {
        TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
        transferFrom(msg.sender, timelock, _amount);
        return timelock;
    }
    
    function grantBurner(address _burner) public onlyOwner {
        burners[_burner] = true;
    }
    
    modifier onlyBurner() {
        require(burners[msg.sender]);
        _;
    }
    
    function burn(uint256 _value) public onlyBurner {
        super.burn(_value);
    }
    
    function withdrawEther(uint256 _amount) public onlyOwner {
        owner.transfer(_amount);
        WithdrewEther(msg.sender, _amount);
    }
    
    function() payable private {
        ReceivedEther(msg.sender, msg.value);
    }
}
```