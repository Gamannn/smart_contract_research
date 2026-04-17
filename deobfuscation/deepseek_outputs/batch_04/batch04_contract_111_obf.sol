```solidity
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

contract Ownable {
    address public owner;
    address public pendingOwner;
    address public superOwner;
    address public pendingSuperOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SuperOwnershipTransferred(address indexed previousSuperOwner, address indexed newSuperOwner);
    
    function Ownable(address _owner, address _superOwner) internal {
        require(_owner != address(0));
        owner = _owner;
        require(_superOwner != address(0));
        superOwner = _superOwner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlySuperOwner() {
        require(msg.sender == superOwner);
        _;
    }
    
    modifier onlyOwnerOrSuperOwner() {
        require(msg.sender == owner || msg.sender == superOwner);
        _;
    }
    
    function isOwnerOrSuperOwner(address _address) public view returns (bool) {
        return _address == owner || _address == superOwner;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }
    
    function transferSuperOwnership(address newSuperOwner) onlySuperOwner public {
        pendingSuperOwner = newSuperOwner;
    }
    
    function claimOwnership() public {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
    
    function claimSuperOwnership() public {
        require(msg.sender == pendingSuperOwner);
        superOwner = pendingSuperOwner;
        pendingSuperOwner = address(0);
    }
}

contract MultiOwnable is Ownable {
    mapping (address => bool) public ownerMap;
    address[] public owners;
    
    event OwnerAddedEvent(address indexed owner);
    event OwnerRemovedEvent(address indexed owner);
    
    function MultiOwnable(address _owner, address _superOwner) Ownable(_owner, _superOwner) internal {}
    
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender));
        _;
    }
    
    function isAuthorized(address _address) public view returns (bool) {
        return isOwnerOrSuperOwner(_address) || ownerMap[_address];
    }
    
    function getOwnerCount() public view returns (uint) {
        return owners.length;
    }
    
    function addOwner(address _owner) onlyOwnerOrSuperOwner public {
        require(_owner != address(0));
        require(!ownerMap[_owner]);
        ownerMap[_owner] = true;
        owners.push(_owner);
        OwnerAddedEvent(_owner);
    }
    
    function removeOwner(address _owner) onlyOwnerOrSuperOwner public {
        require(ownerMap[_owner]);
        ownerMap[_owner] = false;
        OwnerRemovedEvent(_owner);
    }
}

contract Pausable is MultiOwnable {
    bool public paused;
    
    modifier ifNotPaused() {
        require(!paused);
        _;
    }
    
    modifier ifPaused() {
        require(paused);
        _;
    }
    
    function pause() external onlyOwnerOrSuperOwner {
        paused = true;
    }
    
    function unpause() external onlyOwnerOrSuperOwner ifPaused {
        paused = false;
    }
}

contract ERC20Interface {
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Token is ERC20Interface {
    using SafeMath for uint;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract CommonToken is ERC20Token, MultiOwnable {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    address public seller;
    uint256 public saleLimit;
    uint256 public tokensSold;
    bool public locked;
    
    event SellEvent(address indexed seller, address indexed buyer, uint256 value);
    event ChangeSellerEvent(address indexed oldSeller, address indexed newSeller);
    event Burn(address indexed burner, uint256 value);
    event Unlock();
    
    function CommonToken(
        address _owner,
        address _superOwner,
        address _seller,
        string _name,
        string _symbol,
        uint256 _totalSupply,
        uint256 _saleLimitNoDecimals
    ) MultiOwnable(_owner, _superOwner) public {
        require(_seller != address(0));
        require(_totalSupply > 0);
        require(_saleLimitNoDecimals > 0);
        
        seller = _seller;
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply * 1e18;
        saleLimit = _saleLimitNoDecimals * 1e18;
        
        balances[seller] = totalSupply;
        Transfer(0x0, seller, totalSupply);
    }
    
    modifier transferAllowed(address from, address to) {
        require(!locked || isAuthorized(from) || isAuthorized(to));
        _;
    }
    
    function unlock() onlySeller public {
        require(locked);
        locked = false;
        Unlock();
    }
    
    function changeSeller(address newSeller) onlyOwnerOrSuperOwner public returns (bool) {
        require(newSeller != address(0));
        require(seller != newSeller);
        
        address oldSeller = seller;
        uint256 sellerBalance = balances[oldSeller];
        
        balances[oldSeller] = 0;
        balances[newSeller] = balances[newSeller].add(sellerBalance);
        Transfer(oldSeller, newSeller, sellerBalance);
        
        seller = newSeller;
        ChangeSellerEvent(oldSeller, newSeller);
        return true;
    }
    
    function sellNoDecimals(address _to, uint256 _value) public returns (bool) {
        return sell(_to, _value * 1e18);
    }
    
    function sell(address _to, uint256 _value) onlyAuthorized public returns (bool) {
        require(tokensSold.add(_value) <= saleLimit);
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[seller]);
        
        balances[seller] = balances[seller].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(seller, _to, _value);
        
        tokensSold = tokensSold.add(_value);
        SellEvent(seller, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) transferAllowed(msg.sender, _to) public returns (bool) {
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) transferAllowed(_from, _to) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, 0x0, _value);
        Burn(msg.sender, _value);
        return true;
    }
}

contract RACEToken is CommonToken {
    function RACEToken() CommonToken(
        0x229B9Ef80D25A7e7648b17e2c598805d042f9e56,
        0xcd7cF1D613D5974876AfBfd612ED6AFd94093ce7,
        0x2821e1486D604566842FF27F626aF133FddD5f89,
        "Coin Race",
        "RACE",
        100 * 1e6,
        70 * 1e6
    ) public {}
}

contract Crowdsale is MultiOwnable {
    using SafeMath for uint;
    
    uint public minPaymentWei = 0.001 ether;
    uint public tokensPerWei = 15000;
    uint public maxCapTokens = 15000 * 1e6 * 1e18;
    
    address public tokenAddress;
    uint256 public totalCollected;
    uint256 public tokensSold;
    bool public locked;
    
    mapping(address => uint256) public balances;
    
    event ChangeTokenEvent(address indexed oldToken, address indexed newToken);
    event ChangeMaxCapTokensEvent(uint oldMaxCap, uint newMaxCap);
    event ChangeTokenPriceEvent(uint oldPrice, uint newPrice);
    event ReceiveEthEvent(address indexed buyer, uint256 amount);
    
    function Crowdsale(
        address _owner,
        address _superOwner
    ) MultiOwnable(_owner, _superOwner) public {}
    
    function setTokenAddress(address _tokenAddress) onlyOwnerOrSuperOwner public {
        require(_tokenAddress != address(0));
        require(_tokenAddress != address(tokenAddress));
        ChangeTokenEvent(tokenAddress, _tokenAddress);
        tokenAddress = RACEToken(_tokenAddress);
    }
    
    function setMaxCapTokens(uint _maxCapTokens) onlyOwnerOrSuperOwner public {
        require(_maxCapTokens > 0);
        ChangeMaxCapTokensEvent(maxCapTokens, _maxCapTokens);
        maxCapTokens = _maxCapTokens;
    }
    
    function setTokenPrice(uint _tokensPerWei) onlyOwnerOrSuperOwner public {
        require(_tokensPerWei > 0);
        ChangeTokenPriceEvent(tokensPerWei, _tokensPerWei);
        tokensPerWei = _tokensPerWei;
    }
    
    function() public payable {
        sellTokensForEth(msg.sender, msg.value);
    }
    
    function sellTokensForEth(
        address _buyer,
        uint256 _amount
    ) onlyAuthorized public payable {
        require(_amount >= minPaymentWei);
        require(_amount <= maxCapTokens);
        
        uint tokens = weiToTokens(_amount);
        require(tokensSold.add(tokens) <= maxCapTokens);
        
        tokensSold = tokensSold.add(tokens);
        totalCollected = totalCollected.add(_amount);
        balances[_buyer] = balances[_buyer].add(_amount);
        ReceiveEthEvent(_buyer, _amount);
        
        uint half = _amount / 2;
        balances[owner] = balances[owner].add(half);
        balances[superOwner] = balances[superOwner].add(_amount - half);
    }
    
    function weiToTokens(uint _amount) public view returns (uint) {
        return _amount.mul(tokensPerWei);
    }
    
    function withdraw1(address _to) onlyOwner public {
        if (balances[owner] > 0) {
            _to.transfer(balances[owner]);
        }
    }
    
    function withdraw2(address _to) onlySuperOwner public {
        if (balances[superOwner] > 0) {
            _to.transfer(balances[superOwner]);
        }
    }
}

contract RACECrowdsale is Crowdsale {
    function RACECrowdsale() Crowdsale(
        0x229B9Ef80D25A7e7648b17e2c598805d042f9e56,
        0xcd7cF1D613D5974876AfBfd612ED6AFd94093ce7
    ) public {}
}
```