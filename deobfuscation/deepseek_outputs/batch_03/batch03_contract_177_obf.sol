```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == (b * c + a % b));
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ENToken is IERC20 {
    using SafeMath for uint256;
    
    address internal owner;
    string public constant name = "ENTROPIUM";
    string public constant symbol = "ENTUM";
    uint8 public constant decimals = 18;
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply = 0;

    constructor() public payable {
        owner = msg.sender;
    }

    function ownerAddress() public view returns(address) {
        return owner;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address _account, uint256 _amount, uint8 _percent) internal returns (bool) {
        require(_account != address(0));
        require(_amount > 0);
        
        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        
        if (_percent < 100 && _percent > 0) {
            uint256 ownerAmount = _amount.mul(_percent).div(100 - _percent);
            if (ownerAmount > 0) {
                totalSupply = totalSupply.add(ownerAmount);
                balances[owner] = balances[owner].add(ownerAmount);
            }
        }
        
        emit Transfer(address(0), _account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) internal returns (bool) {
        require(_account != address(0));
        require(_amount <= balances[_account]);
        
        totalSupply = totalSupply.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        
        emit Transfer(_account, address(0), _amount);
        return true;
    }
}

contract ENTROPIUM is ENToken {
    using SafeMath for uint256;
    
    uint256 private rate = 100;
    uint256 private startTime = now;
    uint256 private period = 90;
    uint256 private hardcap = 100000000000000000000000;
    uint256 private softcap = 0;
    uint256 private ethtotal = 0;
    uint8 private percent = 0;
    
    mapping(address => uint256) private ethbalances;
    
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event RefundEvent(address indexed beneficiary, uint256 amount);
    event FinishEvent(uint256 amount);

    constructor() public payable {
    }

    function() external payable {
        buyTokens(msg.sender);
    }

    function rate() public view returns(uint256) {
        return rate;
    }

    function start() public view returns(uint256) {
        return startTime;
    }

    function finished() public view returns(bool) {
        uint256 nowTime = now;
        return ((nowTime > (startTime + period * 1 days)) || (ethtotal >= hardcap));
    }

    function reachSoftcap() public view returns(bool) {
        return (ethtotal >= softcap);
    }

    function reachHardcap() public view returns(bool) {
        return (ethtotal >= hardcap);
    }

    function period() public view returns(uint256) {
        return period;
    }

    function setPeriod(uint256 _period) public returns(uint256) {
        require(msg.sender == owner);
        uint256 nowTime = now;
        require(nowTime >= startTime);
        require(_period > 0);
        period = _period;
        return period;
    }

    function daysEnd() public view returns(uint256) {
        uint256 nowTime = now;
        uint256 endTime = startTime + period * 1 days;
        if (nowTime >= endTime) return 0;
        return (endTime - startTime) / (1 days);
    }

    function hardcap() public view returns(uint256) {
        return hardcap;
    }

    function setHardcap(uint256 _hardcap) public returns(uint256) {
        require(msg.sender == owner);
        require(_hardcap > softcap);
        uint256 nowTime = now;
        require(nowTime >= startTime);
        hardcap = _hardcap;
        return hardcap;
    }

    function softcap() public view returns(uint256) {
        return softcap;
    }

    function percent() public view returns(uint8) {
        return percent;
    }

    function ethtotal() public view returns(uint256) {
        return ethtotal;
    }

    function ethOf(address _owner) public view returns (uint256) {
        return ethbalances[_owner];
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner);
        require(_owner != address(0) && _owner != address(this));
        owner = _owner;
    }

    function buyTokens(address _beneficiary) internal {
        require(_beneficiary != address(0));
        uint256 nowTime = now;
        require((nowTime >= startTime) && (nowTime <= (startTime + period * 1 days)));
        require(ethtotal < hardcap);
        
        uint256 weiAmount = msg.value;
        require(weiAmount != 0);
        
        uint256 tokenAmount = weiAmount.mul(rate);
        mint(_beneficiary, tokenAmount, percent);
        
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
        
        ethbalances[_beneficiary] = ethbalances[_beneficiary].add(weiAmount);
        ethtotal = ethtotal.add(weiAmount);
    }

    function refund(uint256 _amount) external returns(uint256) {
        uint256 nowTime = now;
        require((nowTime > (startTime + period * 1 days)) && (ethtotal < softcap));
        
        uint256 tokenAmount = balances[msg.sender];
        uint256 weiAmount = ethbalances[msg.sender];
        
        require((_amount > 0) && (_amount <= weiAmount) && (_amount <= address(this).balance));
        
        if (tokenAmount > 0) {
            require(tokenAmount <= totalSupply);
            totalSupply = totalSupply.sub(tokenAmount);
            balances[msg.sender] = 0;
            emit Transfer(msg.sender, address(0), tokenAmount);
        }
        
        ethbalances[msg.sender] = ethbalances[msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        emit RefundEvent(msg.sender, _amount);
        
        ethtotal = ethtotal.sub(_amount);
        return _amount;
    }

    function finishICO(uint256 _amount) external returns(uint256) {
        require(msg.sender == owner);
        uint256 nowTime = now;
        require((nowTime >= startTime) && (ethtotal >= softcap));
        require(_amount <= address(this).balance);
        
        emit FinishEvent(_amount);
        msg.sender.transfer(_amount);
        return _amount;
    }

    function abalance(address _owner) public view returns (uint256) {
        return _owner.balance;
    }
}
```