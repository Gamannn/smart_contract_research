pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }
}

contract Ownable {
    address public owner;

    modifier onlyOwner {
        if (!isOwner(msg.sender)) throw;
        _;
    }

    function Ownable() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }

    function isOwner(address _address) returns (bool) {
        return owner == _address;
    }
}

contract Burnable {
    event Burn(address indexed owner, uint amount);

    function burn(address _owner, uint _amount) public;
}

contract ERC20 {
    function totalSupply() constant returns (uint);
    function balanceOf(address _owner) constant returns (uint);
    function allowance(address _owner, address _spender) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract Mintable {
    event Mint(address indexed to, uint value);

    function mint(address _to, uint _amount) public;
}

contract Token is ERC20, Mintable, Burnable, Ownable {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public totalSupply;
    uint public maxSupply;
    uint public freezeMintUntil;
    mapping (address => mapping (address => uint)) allowed;
    mapping (address => uint) balances;

    modifier canMint {
        require(totalSupply < maxSupply);
        _;
    }

    modifier mintIsNotFrozen {
        require(freezeMintUntil < now);
        _;
    }

    function Token(string _name, string _symbol, uint _maxSupply) {
        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
        totalSupply = 0;
        freezeMintUntil = 0;
    }

    function totalSupply() constant returns (uint) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint _value) returns (bool) {
        if (_value <= 0) {
            return false;
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if (_value <= 0) {
            return false;
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function mint(address _to, uint _amount) public canMint mintIsNotFrozen onlyOwner {
        if (maxSupply < totalSupply.add(_amount)) throw;
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
    }

    function burn(address _owner, uint _amount) public onlyOwner {
        totalSupply = totalSupply.sub(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        Burn(_owner, _amount);
    }

    function freezeMintingFor(uint _weeks) public onlyOwner {
        freezeMintUntil = now + _weeks * 1 weeks;
    }
}

contract TokenSale is Ownable {
    using SafeMath for uint;

    Token public token;
    mapping (address => uint) contributed;
    mapping (address => bool) whitelisted;

    event GoalReached(uint totalCollected);
    event NewContribution(address indexed holder, uint256 tokens, uint256 contributed);
    event Refunded(address indexed holder, uint amount);

    struct SaleConfig {
        bool isFinalized;
        bool capReached;
        uint256 endBlock;
        uint256 startBlock;
        uint256 whitelistStartBlock;
        uint256 purchaseLimit;
        uint256 price;
        uint256 collected;
        uint256 cap;
        address beneficiary;
        uint256 MINT_LOCK_DURATION_IN_WEEKS;
        uint256 freezeMintUntil;
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 decimals;
        uint256 totalSupply;
        address owner;
    }

    SaleConfig public saleConfig;

    modifier onlyAfterSale {
        require(block.number > saleConfig.endBlock);
        _;
    }

    modifier onlyWhenFinalized {
        require(saleConfig.isFinalized);
        _;
    }

    modifier onlyDuringSale {
        require(block.number >= startBlock(msg.sender));
        require(block.number <= saleConfig.endBlock);
        _;
    }

    modifier onlyWhenEnded {
        if (block.number < saleConfig.endBlock && !saleConfig.capReached) throw;
        _;
    }

    function TokenSale(
        uint _cap,
        uint _whitelistStartBlock,
        uint _startBlock,
        uint _endBlock,
        address _token,
        uint _price,
        uint _purchaseLimit,
        address _beneficiary
    ) {
        saleConfig.cap = _cap * 1 ether;
        saleConfig.price = _price;
        saleConfig.purchaseLimit = (_purchaseLimit * 1 ether) * saleConfig.price;
        token = Token(_token);
        saleConfig.beneficiary = _beneficiary;
        saleConfig.whitelistStartBlock = _whitelistStartBlock;
        saleConfig.startBlock = _startBlock;
        saleConfig.endBlock = _endBlock;
    }

    function () payable {
        doPurchase(msg.sender);
    }

    function refund() public onlyWhenFinalized {
        if (saleConfig.capReached) throw;
        uint balance = token.balanceOf(msg.sender);
        if (balance == 0) throw;
        uint refund = balance.div(saleConfig.price);
        if (refund > this.balance) {
            refund = this.balance;
        }
        token.burn(msg.sender, balance);
        contributed[msg.sender] = 0;
        msg.sender.transfer(refund);
        Refunded(msg.sender, refund);
    }

    function finalize() public onlyWhenEnded onlyOwner {
        require(!saleConfig.isFinalized);
        saleConfig.isFinalized = true;
        if (!saleConfig.capReached) {
            return;
        }
        if (!saleConfig.beneficiary.send(saleConfig.collected)) throw;
        token.freezeMintingFor(saleConfig.MINT_LOCK_DURATION_IN_WEEKS);
    }

    function doPurchase(address _owner) internal onlyDuringSale {
        if (msg.value <= 0) throw;
        if (saleConfig.collected >= saleConfig.cap) throw;
        uint value = msg.value;
        if (saleConfig.collected.add(value) > saleConfig.cap) {
            uint difference = saleConfig.cap.sub(saleConfig.collected);
            msg.sender.transfer(value.sub(difference));
            value = difference;
        }
        uint tokens = value.mul(saleConfig.price);
        if (token.balanceOf(msg.sender) + tokens > saleConfig.purchaseLimit) throw;
        saleConfig.collected = saleConfig.collected.add(value);
        token.mint(msg.sender, tokens);
        NewContribution(_owner, tokens, value);
        if (saleConfig.collected != saleConfig.cap) {
            return;
        }
        GoalReached(saleConfig.collected);
        saleConfig.capReached = true;
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelisted[_address] = true;
    }

    function startBlock(address contributor) constant returns (uint) {
        if (whitelisted[contributor]) {
            return saleConfig.whitelistStartBlock;
        }
        return saleConfig.startBlock;
    }

    function tokenTransferOwnership(address _newOwner) public onlyWhenFinalized {
        if (!saleConfig.capReached) throw;
        token.transferOwnership(_newOwner);
    }
}