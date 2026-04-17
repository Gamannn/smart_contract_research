```solidity
pragma solidity ^0.4.18;

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

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    function unpause() onlyOwner public {
        require(paused);
        paused = false;
        Unpause();
    }
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

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
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
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract BaceToken is MintableToken, Pausable {
    string public constant name = "Bace Token";
    string public constant symbol = "BACE";
    uint8 public constant decimals = 18;

    function BaceToken() public {
        totalSupply = 100 * 1E6 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
    }
}

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    uint256 public whitelistLength = 0;

    function addAddressToWhitelist(address addr) onlyOwner public {
        require(addr != address(0));
        require(!isWhitelisted(addr));
        whitelist[addr] = true;
        whitelistLength++;
    }

    function removeAddressFromWhitelist(address addr) onlyOwner public {
        require(addr != address(0));
        require(isWhitelisted(addr));
        whitelist[addr] = false;
        whitelistLength--;
    }

    function isWhitelisted(address addr) view public returns (bool) {
        return whitelist[addr];
    }
}

contract Whitelistable {
    Whitelist public whitelist;

    modifier onlyWhitelisted(address addr) {
        require(whitelist.isWhitelisted(addr));
        _;
    }

    function Whitelistable() public {
        whitelist = new Whitelist();
    }
}

contract BaceCrowdsale is Pausable, Whitelistable {
    using SafeMath for uint256;

    uint256 public constant DECIMALS = 18;
    uint256 public constant PREICO_BONUS = 20;
    uint256 public constant ICO_BONUS = 10;

    address[] public preIcoInvestors;
    mapping(address => uint256) public preIcoInvestments;
    address[] public icoInvestors;
    mapping(address => uint256) public icoInvestments;

    uint256 public preIcoTotalCollected;
    uint256 public icoTotalCollected;

    uint256 public preIcoSoldTokens;
    uint256 public icoSoldTokens;

    uint256 public preIcoStartTime;
    uint256 public preIcoEndTime;
    uint256 public icoStartTime;
    uint256 public icoEndTime;

    uint256 public minInvestment;
    uint256 public maxInvestment;

    uint256 public preIcoHardCap;
    uint256 public icoHardCap;

    bool public unsoldTokensBurned;

    BaceToken public token;

    function BaceCrowdsale(
        uint256 _preIcoStartTime,
        uint256 _preIcoEndTime,
        uint256 _icoStartTime,
        uint256 _icoEndTime,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _preIcoHardCap,
        uint256 _icoHardCap
    ) public {
        require(_preIcoStartTime >= now && _preIcoEndTime > _preIcoStartTime);
        require(_icoStartTime >= _preIcoEndTime && _icoEndTime > _icoStartTime);
        require(_minInvestment > 0 && _maxInvestment > _minInvestment);
        require(_preIcoHardCap > 0 && _icoHardCap > _preIcoHardCap);

        preIcoStartTime = _preIcoStartTime;
        preIcoEndTime = _preIcoEndTime;
        icoStartTime = _icoStartTime;
        icoEndTime = _icoEndTime;

        minInvestment = _minInvestment;
        maxInvestment = _maxInvestment;

        preIcoHardCap = _preIcoHardCap;
        icoHardCap = _icoHardCap;

        token = new BaceToken();
        token.transferOwnership(msg.sender);
    }

    function isPreIco() public view returns (bool) {
        return now >= preIcoStartTime && now <= preIcoEndTime;
    }

    function isIco() public view returns (bool) {
        return now >= icoStartTime && now <= icoEndTime;
    }

    function hasPreIcoEnded() public view returns (bool) {
        return now > preIcoEndTime;
    }

    function hasIcoEnded() public view returns (bool) {
        return now > icoEndTime;
    }

    function remainingPreIcoTokens() public view returns (uint256) {
        if (hasPreIcoEnded()) {
            return 0;
        }
        return preIcoHardCap.sub(preIcoSoldTokens);
    }

    function remainingIcoTokens() public view returns (uint256) {
        if (unsoldTokensBurned) {
            return 0;
        }
        if (hasIcoEnded()) {
            return icoHardCap.sub(icoSoldTokens);
        }
        return icoHardCap.sub(icoSoldTokens);
    }

    function buyTokens() public payable whenNotPaused onlyWhitelisted(msg.sender) {
        require(msg.value >= minInvestment);

        bool isPreIcoStage = isPreIco();
        bool isIcoStage = isIco();

        require(isPreIcoStage || isIcoStage);

        uint256 tokensToBuy;
        uint256 weiAmount = msg.value;

        if (isPreIcoStage) {
            require(preIcoTotalCollected.add(weiAmount) <= preIcoHardCap);
            tokensToBuy = weiAmount.mul(PREICO_BONUS).div(100);
            preIcoTotalCollected = preIcoTotalCollected.add(weiAmount);
            preIcoSoldTokens = preIcoSoldTokens.add(tokensToBuy);
            preIcoInvestments[msg.sender] = preIcoInvestments[msg.sender].add(weiAmount);
            preIcoInvestors.push(msg.sender);
        } else if (isIcoStage) {
            require(icoTotalCollected.add(weiAmount) <= icoHardCap);
            tokensToBuy = weiAmount.mul(ICO_BONUS).div(100);
            icoTotalCollected = icoTotalCollected.add(weiAmount);
            icoSoldTokens = icoSoldTokens.add(tokensToBuy);
            icoInvestments[msg.sender] = icoInvestments[msg.sender].add(weiAmount);
            icoInvestors.push(msg.sender);
        }

        token.transfer(msg.sender, tokensToBuy);
    }

    function burnUnsoldTokens() onlyOwner public {
        require(hasIcoEnded());
        uint256 unsoldTokens = remainingIcoTokens();
        if (unsoldTokens > 0) {
            token.burn(unsoldTokens);
            unsoldTokensBurned = true;
        }
    }
}
```