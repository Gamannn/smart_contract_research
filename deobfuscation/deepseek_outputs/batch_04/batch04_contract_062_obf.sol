```solidity
pragma solidity ^0.4.17;

contract ERC20Interface {
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenRecipient {
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

contract ERC20Token is ERC20Interface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
        require(transfer(_to, _value));
        
        uint codeLength;
        assembly {
            codeLength := extcodesize(_to)
        }
        
        if (codeLength > 0) {
            TokenRecipient receiver = TokenRecipient(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0);
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
}

contract BurnableToken is ERC20Token {
    string public name = "Oxa524069202bf8ba6186be81265b603d492f9b5ee";
    string public symbol = "MTO";
    uint8 public decimals = 18;
    
    function BurnableToken() public {
        totalSupply = 300312502 * 10**17;
        balances[msg.sender] = totalSupply;
        emit Transfer(0x0, msg.sender, totalSupply);
        assert(totalSupply == balances[msg.sender]);
    }
    
    function burn(uint256 _value) public {
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(totalSupply >= _value);
        
        uint256 previousBalance = balances[msg.sender];
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        
        emit Transfer(msg.sender, 0x0, _value);
        assert(balances[msg.sender] == previousBalance - _value);
    }
}

contract Crowdsale {
    BurnableToken public token;
    address public beneficiary;
    address public team;
    uint public amountRaised;
    uint public tokenSold;
    uint public alfatokenFee;
    uint public constant PRE_SALE_START = 1523952000;
    
    enum Stages {Deployed, Ready, Ended, Canceled}
    
    Stages public stage = Stages.Deployed;
    
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == beneficiary);
        _;
    }
    
    function Crowdsale(
        address _beneficiary,
        address _alfatoken,
        address _team
    ) public {
        beneficiary = _beneficiary;
        team = _team;
        alfatokenFee = 5 ether;
        stage = Stages.Deployed;
    }
    
    function setToken(address _tokenAddress) public onlyOwner atStage(Stages.Deployed) {
        require(_tokenAddress != 0x0);
        token = BurnableToken(_tokenAddress);
        stage = Stages.Ready;
    }
    
    function () payable public atStage(Stages.Ready) {
        require((now >= PRE_SALE_START && now <= PRE_SALE_END) || (now >= SALE_START && now <= SALE_END));
        
        uint256 amount = msg.value;
        require(amountRaised + msg.value >= msg.value);
        
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            require(amountRaised + amount >= amount);
        }
        
        uint256 tokenAmount = amount * getPrice();
        require(tokenAmount > getMinBuy());
        
        uint256 tokens = tokenAmount + getBonusAmount(tokenAmount);
        tokenSold += tokens;
        
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            require(tokenSold <= PRE_SALE_CAP);
        }
        
        if (now >= SALE_START && now <= SALE_END) {
            require(tokenSold <= SALE_CAP);
        }
        
        token.transfer(msg.sender, tokens);
    }
    
    function withdrawEther(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance);
        require(now < SALE_END || stage == Stages.Ended);
        _to.transfer(_amount);
    }
    
    function withdrawTokens(address _to, uint256 _amount) public onlyOwner {
        require(msg.sender == team);
        require(_amount <= alfatokenFee);
        alfatokenFee -= _amount;
        _to.transfer(_amount);
    }
    
    function finalize(address _to) public onlyOwner {
        require(amountRaised >= SOFT_CAP);
        token.transfer(_to, tokenSold * 3 / 7);
        token.burn(token.balanceOf(address(this)));
        stage = Stages.Ended;
    }
    
    function cancel() public {
        require(amountRaised < SOFT_CAP);
        require(now > SALE_END);
        stage = Stages.Canceled;
    }
    
    function refund() public atStage(Stages.Canceled) returns (bool) {
        return takeEtherBack(msg.sender);
    }
    
    function takeEtherBack(address _receiver) public atStage(Stages.Canceled) returns (bool) {
        require(_receiver != 0x0);
        
        if (contributions[_receiver] == 0) {
            return false;
        }
        
        uint256 amount = contributions[_receiver];
        contributions[_receiver] = 0;
        _receiver.transfer(amount);
        
        assert(contributions[_receiver] == 0);
        return true;
    }
    
    function getBonusAmount(uint256 amount) public view returns (uint256) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            uint256 timePassed = now - PRE_SALE_START;
            
            if (timePassed < 1 weeks) {
                return amount * PRE_SALE_1WEEK_BONUS / 100;
            }
            
            if (timePassed > 1 weeks && timePassed < 2 weeks) {
                return amount * PRE_SALE_2WEEK_BONUS / 100;
            }
            
            if (timePassed > 2 weeks && timePassed <= 3 weeks) {
                return amount * PRE_SALE_3WEEK_BONUS / 100;
            }
            
            if (timePassed > 3 weeks && timePassed <= 4 weeks) {
                return amount * PRE_SALE_4WEEK_BONUS / 100;
            }
            
            return 0;
        }
        
        if (now >= SALE_START && now <= SALE_END) {
            uint256 saleTimePassed = now - SALE_START;
            
            if (saleTimePassed < 1 weeks) {
                return amount * SALE_1WEEK_BONUS / 100;
            }
            
            if (saleTimePassed > 1 weeks && saleTimePassed <= 2 weeks) {
                return amount * SALE_2WEEK_BONUS / 100;
            }
            
            if (saleTimePassed > 2 weeks && saleTimePassed < 3 weeks) {
                return amount * SALE_3WEEK_BONUS / 100;
            }
            
            if (saleTimePassed > 3 weeks && saleTimePassed <= 4 weeks) {
                return amount * SALE_4WEEK_BONUS / 100;
            }
        }
        
        return 0;
    }
    
    function getPrice() public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            return PRE_SALE_PRICE;
        }
        
        if (now >= SALE_START && now <= SALE_END) {
            return SALE_PRICE;
        }
        
        return 0;
    }
    
    function getMinBuy() public view returns (uint256) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            return PRE_SALE_MIN_BUY;
        }
        
        if (now >= SALE_START && now <= SALE_END) {
            return SALE_MIN_BUY;
        }
        
        return 0;
    }
    
    uint public constant PRE_SALE_END = 1526543999;
    uint public constant SALE_START = 1528617600;
    uint public constant SALE_END = 1531209599;
    uint public constant PRE_SALE_CAP = 1250 * 10**18;
    uint public constant SALE_CAP = 2500000000000000000000;
    uint public constant SOFT_CAP = 5000000000000000000;
    uint public constant PRE_SALE_PRICE = 42901786;
    uint public constant SALE_PRICE = 2531250;
    uint public constant PRE_SALE_MIN_BUY = 10 * 10**18;
    uint public constant SALE_MIN_BUY = 100 * 10**18;
    uint public constant PRE_SALE_1WEEK_BONUS = 35;
    uint public constant PRE_SALE_2WEEK_BONUS = 25;
    uint public constant PRE_SALE_3WEEK_BONUS = 15;
    uint public constant PRE_SALE_4WEEK_BONUS = 5;
    uint public constant SALE_1WEEK_BONUS = 35;
    uint public constant SALE_2WEEK_BONUS = 25;
    uint public constant SALE_3WEEK_BONUS = 15;
    uint public constant SALE_4WEEK_BONUS = 7;
    
    mapping(address => uint256) public contributions;
}
```