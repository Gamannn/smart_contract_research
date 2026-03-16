```solidity
pragma solidity ^0.4.17;

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

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Noxon is ERC20Interface {
    using SafeMath for uint256;

    string public constant name = "NOXON";
    string public constant symbol = "NOXON";

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    struct ContractState {
        address newManager;
        address pendingOwner;
        address manager;
        address owner;
        bool emissionLocked;
        uint256 initialized;
        uint256 emissionPrice;
        uint256 burnPrice;
        uint256 totalSupply;
    }

    ContractState state;

    modifier onlyOwner() {
        require(msg.sender == state.owner);
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        state.pendingOwner = newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == state.pendingOwner) {
            state.owner = state.pendingOwner;
            state.pendingOwner = address(0);
        }
    }

    function changeManager(address newManager) public onlyOwner {
        state.newManager = newManager;
    }

    function acceptManagership() public {
        if (msg.sender == state.newManager) {
            state.manager = state.newManager;
            state.newManager = address(0);
        }
    }

    function Noxon() public {
        require(state.totalSupply == 0);
        state.owner = msg.sender;
        state.manager = state.owner;
    }

    function initialize() public payable onlyOwner returns (bool) {
        require(state.totalSupply == 0);
        require(state.initialized == 0);
        require(msg.value > 0);
        emit Transfer(0, msg.sender, 1);
        balances[state.owner] = 1;
        state.totalSupply = balances[state.owner];
        state.burnPrice = msg.value;
        state.emissionPrice = state.burnPrice.mul(2);
        state.initialized = block.timestamp;
        return true;
    }

    function lockEmission() public onlyOwner {
        state.emissionLocked = true;
    }

    function unlockEmission() public onlyOwner {
        state.emissionLocked = false;
    }

    function totalSupply() public view returns (uint256) {
        return state.totalSupply;
    }

    function burnPrice() public view returns (uint256) {
        return state.burnPrice;
    }

    function emissionPrice() public view returns (uint256) {
        return state.emissionPrice;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (_to == address(this)) {
            return burnTokens(_amount);
        } else {
            if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]) {
                balances[msg.sender] = balances[msg.sender].sub(_amount);
                balances[_to] = balances[_to].add(_amount);
                emit Transfer(msg.sender, _to, _amount);
                return true;
            } else {
                return false;
            }
        }
    }

    function burnTokens(uint256 _amount) private returns (bool success) {
        state.burnPrice = getBurnPrice();
        uint256 burnPriceTmp = state.burnPrice;
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            state.totalSupply = state.totalSupply.sub(_amount);
            assert(state.totalSupply >= 1);
            msg.sender.transfer(_amount.mul(state.burnPrice));
            state.burnPrice = getBurnPrice();
            assert(state.burnPrice >= burnPriceTmp);
            emit TokenBurned(msg.sender, _amount.mul(state.burnPrice), state.burnPrice, _amount);
            return true;
        } else {
            return false;
        }
    }

    event TokenBought(address indexed buyer, uint256 ethers, uint emissionPrice, uint amountOfTokens);
    event TokenBurned(address indexed buyer, uint256 ethers, uint burnPrice, uint amountOfTokens);

    function () public payable {
        uint256 burnPriceTmp = state.burnPrice;
        require(state.emissionLocked == false);
        require(state.burnPrice > 0 && state.emissionPrice > state.burnPrice);
        require(msg.value > 0);
        uint256 amount = msg.value.div(state.emissionPrice);
        require(balances[msg.sender].add(amount) > balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].add(amount);
        state.totalSupply = state.totalSupply.add(amount);
        uint mg = msg.value.div(2);
        state.manager.transfer(mg);
        emit TokenBought(msg.sender, msg.value, state.emissionPrice, amount);
        state.burnPrice = getBurnPrice();
        state.emissionPrice = state.burnPrice.mul(2);
        assert(state.burnPrice >= burnPriceTmp);
    }

    function getBurnPrice() public view returns (uint) {
        return address(this).balance.div(state.totalSupply);
    }

    event EtherReserved(uint etherReserved);

    function addToReserve() public payable returns (bool) {
        uint256 burnPriceTmp = state.burnPrice;
        if (msg.value > 0) {
            state.burnPrice = getBurnPrice();
            state.emissionPrice = state.burnPrice.mul(2);
            emit EtherReserved(msg.value);
            assert(state.burnPrice >= burnPriceTmp);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to] && _to != address(this)) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(state.owner, amount);
    }

    function burnAll() external returns (bool) {
        return burnTokens(balances[msg.sender]);
    }
}

contract TestProcess {
    Noxon main;

    function TestProcess() payable {
        main = new Noxon();
    }

    function () payable {}

    function init() public returns (uint) {
        if (!main.initialize.value(12)()) revert();
        if (!main.call.value(24)()) revert();
        assert(main.balanceOf(address(this)) == 2);
        if (main.call.value(23)()) revert();
        assert(main.balanceOf(address(this)) == 2);
    }

    function test1() public returns (uint) {
        if (!main.call.value(26)()) revert();
        assert(main.balanceOf(address(this)) == 3);
        assert(main.emissionPrice() == 24);
        return main.totalSupply();
    }

    function test2() public returns (uint) {
        if (!main.call.value(40)()) revert();
        assert(main.balanceOf(address(this)) == 4);
    }

    function test3() public {
        if (!main.transfer(address(main), 2)) revert();
        assert(main.burnPrice() == 14);
    }
}
```