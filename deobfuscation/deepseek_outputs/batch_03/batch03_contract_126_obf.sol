```solidity
pragma solidity ^0.4.21;

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

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract StandardToken {
    using SafeMath for uint256;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    
    uint256 internal totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract TeamToken is StandardToken, Ownable {
    event Buy(address indexed token, address indexed buyer, uint256 amount, uint256 weiValue);
    event Sell(address indexed token, address indexed seller, uint256 amount, uint256 weiValue);
    event BeginGame(address indexed team1, address indexed team2, uint64 gameTime);
    event EndGame(address indexed team1, address indexed team2, uint8 gameResult);
    event ChangeStatus(address indexed team, uint8 status);
    
    uint256 public price;
    uint8 public status;
    uint64 public gameTime;
    address public feeOwner;
    address public gameOpponent;
    
    function TeamToken(string _name, string _symbol, address _feeOwner) public {
        name = _name;
        symbol = _symbol;
        decimals = 3;
        totalSupply = 0;
        price = 1 szabo;
        feeOwner = _feeOwner;
        owner = msg.sender;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_to != address(this)) {
            return super.transfer(_to, _value);
        }
        
        require(_value <= balances[msg.sender] && status == 0);
        
        if (gameTime > 1514764800) {
            require(gameTime - 300 > block.timestamp);
        }
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        
        uint256 weiAmount = price.mul(_value);
        msg.sender.transfer(weiAmount);
        
        emit Transfer(msg.sender, _to, _value);
        emit Sell(_to, msg.sender, _value, weiAmount);
        return true;
    }
    
    function() payable public {
        require(status == 0 && price > 0);
        
        if (gameTime > 1514764800) {
            require(gameTime - 300 > block.timestamp);
        }
        
        uint256 amount = msg.value.div(price);
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply = totalSupply.add(amount);
        
        emit Transfer(address(this), msg.sender, amount);
        emit Buy(address(this), msg.sender, amount, msg.value);
    }
    
    function changeStatus(uint8 _status) onlyOwner public {
        require(status != _status);
        status = _status;
        emit ChangeStatus(address(this), _status);
    }
    
    function finish() onlyOwner public {
        require(block.timestamp >= 1529952300);
        feeOwner.transfer(address(this).balance);
    }
    
    function beginGame(address _gameOpponent, uint64 _gameTime) onlyOwner public {
        require(_gameOpponent != address(0) && _gameOpponent != address(this) && gameOpponent == address(0));
        require(_gameTime == 0 || (_gameTime > 1514764800 && _gameTime < 1546300800));
        
        gameOpponent = _gameOpponent;
        gameTime = _gameTime;
        status = 0;
        emit BeginGame(address(this), gameOpponent, _gameTime);
    }
    
    function endGame(address _gameOpponent, uint8 _gameResult) onlyOwner public {
        require(gameOpponent != address(0) && gameOpponent == _gameOpponent);
        
        uint256 amount = address(this).balance;
        uint256 opAmount = gameOpponent.balance;
        
        require(_gameResult == 1 || (_gameResult == 2 && amount >= opAmount) || _gameResult == 3);
        
        TeamToken opponent = TeamToken(gameOpponent);
        
        if (_gameResult == 1) {
            if (amount > 0 && totalSupply > 0) {
                uint256 lostAmount = amount;
                
                if (opponent.totalSupply() > 0) {
                    uint256 feeAmount = lostAmount.div(20);
                    lostAmount = lostAmount.sub(feeAmount);
                    feeOwner.transfer(feeAmount);
                    opponent.transferFundAndEndGame.value(lostAmount)();
                } else {
                    feeOwner.transfer(lostAmount);
                    opponent.transferFundAndEndGame();
                }
            } else {
                opponent.transferFundAndEndGame();
            }
        } else if (_gameResult == 2) {
            if (amount > opAmount) {
                uint256 lostAmount = amount.sub(opAmount).div(2);
                
                if (opponent.totalSupply() > 0) {
                    uint256 feeAmount = lostAmount.div(20);
                    lostAmount = lostAmount.sub(feeAmount);
                    feeOwner.transfer(feeAmount);
                    opponent.transferFundAndEndGame.value(lostAmount)();
                } else {
                    feeOwner.transfer(lostAmount);
                    opponent.transferFundAndEndGame();
                }
            } else if (amount == opAmount) {
                opponent.transferFundAndEndGame();
            } else {
                revert();
            }
        } else if (_gameResult == 3) {
            opponent.transferFundAndEndGame();
        } else {
            revert();
        }
        
        endGameInternal();
        
        if (totalSupply > 0) {
            price = address(this).balance.div(totalSupply);
        }
        
        emit EndGame(address(this), _gameOpponent, _gameResult);
    }
    
    function endGameInternal() private {
        gameOpponent = address(0);
        gameTime = 0;
        status = 0;
    }
    
    function transferFundAndEndGame() payable public {
        require(gameOpponent != address(0) && gameOpponent == msg.sender);
        
        if (msg.value > 0 && totalSupply > 0) {
            price = address(this).balance.div(totalSupply);
        }
        
        endGameInternal();
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
}
```