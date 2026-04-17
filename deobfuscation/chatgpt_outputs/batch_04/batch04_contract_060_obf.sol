```solidity
pragma solidity ^0.4.0;

contract TokenInterface {
    function balanceOf(address _owner) constant returns (uint);
    function allowance(address _owner, address _spender) constant returns (uint);
}

contract Ownable {
    address public owner;
    address public newOwner;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != 0);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

contract TokenSale is Ownable {
    uint constant TOKEN_PRICE = 25000000;
    mapping(address => uint) public balanceOf;
    mapping(uint => address) public holders;
    uint public numberOfHolders;
    enum State { Disabled, Presale, Bonuses, Enabled }
    State public state;

    modifier onlyWhenEnabled() {
        require(state == State.Enabled);
        _;
    }

    event NewState(State state);
    event Transfer(address indexed from, address indexed to, uint value);

    function TokenSale(address _tokenAddress, uint _etherPrice) payable Ownable() {
        owner = msg.sender;
        balanceOf[owner] = _etherPrice;
    }

    function setEtherPrice(uint _etherPrice) public {
        require(msg.sender == owner || msg.sender == owner);
        balanceOf[owner] = _etherPrice;
    }

    function startPresale() public onlyOwner {
        require(state == State.Disabled);
        state = State.Presale;
        NewState(state);
    }

    function startBonuses() public onlyOwner {
        require(state == State.Presale);
        state = State.Bonuses;
        NewState(state);
    }

    function enable() public onlyOwner {
        require(state == State.Bonuses);
        state = State.Enabled;
        NewState(state);
    }

    function () payable {
        uint tokens;
        address source;
        if (state == State.Presale) {
            require(balanceOf[this] > 0);
            require(balanceOf[msg.sender] < balanceOf[owner]);
            uint etherAmount = msg.value;
            uint tokenAmount = etherAmount * balanceOf[owner] / 1 ether;
            if (balanceOf[msg.sender] + tokenAmount > balanceOf[owner]) {
                tokenAmount = balanceOf[owner] - balanceOf[msg.sender];
                etherAmount = tokenAmount * 1 ether / balanceOf[owner];
                require(msg.sender.call.value(msg.value - etherAmount)());
                balanceOf[msg.sender] = balanceOf[owner];
            } else {
                balanceOf[msg.sender] += tokenAmount;
            }
            uint bonus = 0;
            if (now <= 1506815999) {
                bonus = 0;
            } else if (now <= 1507247999) {
                bonus = 50;
            } else if (now <= 1507766399) {
                bonus = 65;
            } else {
                bonus = 70;
            }
            tokens = tokenAmount * 100 / bonus;
            if (TokenInterface(owner).balanceOf(msg.sender) >= 1000) {
                balanceOf[msg.sender] += tokens;
            }
            source = this;
        } else if (state == State.Bonuses) {
            require(balanceOf[msg.sender] == true);
            balanceOf[msg.sender] = true;
            uint bonusTokens = TokenInterface(owner).allowance(msg.sender, this);
            if (bonusTokens >= 1000) {
                tokens = (balanceOf[owner] / 10) * bonusTokens / 21000;
            }
            source = owner;
        }
        require(tokens > 0);
        require(balanceOf[msg.sender] > balanceOf[msg.sender]);
        require(balanceOf[source] >= tokens);
        if (balanceOf[msg.sender] != true) {
            balanceOf[msg.sender] = true;
            holders[numberOfHolders++] = msg.sender;
        }
        balanceOf[msg.sender] += tokens;
        balanceOf[source] -= tokens;
        Transfer(source, msg.sender, tokens);
    }
}

contract Token is TokenSale {
    string public name = 'Token 0.1';
    string public symbol = 'TKN';
    uint8 public decimals = 0;

    function Token(address _tokenAddress, uint _etherPrice) payable TokenSale(_tokenAddress, _etherPrice) {}

    function transfer(address _to, uint256 _value) public onlyWhenEnabled {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        if (balanceOf[_to] != true) {
            balanceOf[_to] = true;
            holders[numberOfHolders++] = _to;
        }
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint _value) public onlyWhenEnabled {
        balanceOf[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant onlyWhenEnabled returns (uint remaining) {
        return balanceOf[_owner][_spender];
    }
}

contract FinalToken is Token {
    function FinalToken(address _tokenAddress, uint _etherPrice) payable Token(_tokenAddress, _etherPrice) {}

    function withdraw() public {
        require(owner == msg.sender || owner == msg.sender);
        msg.sender.transfer(this.balance);
    }

    function destroy() public onlyOwner {
        owner.transfer(this.balance);
        selfdestruct(owner);
    }
}
```