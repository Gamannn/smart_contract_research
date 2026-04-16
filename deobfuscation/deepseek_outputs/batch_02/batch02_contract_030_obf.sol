```solidity
pragma solidity ^0.4.16;

contract ERC20Interface {
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    mapping(address => bool) internal owners;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() {
        owners[msg.sender] = true;
    }
    
    modifier onlyOwner() {
        require(owners[msg.sender] == true);
        _;
    }
    
    function addOwner(address newOwner) onlyOwner public {
        owners[newOwner] = true;
    }
    
    function removeOwner(address oldOwner) onlyOwner public {
        owners[oldOwner] = false;
    }
}

contract BigToken is ERC20Interface, Ownable {
    using SafeMath for uint256;
    
    string public name = "Big Token";
    string public symbol = "BIG";
    uint256 public decimals = 18;
    uint256 public totalSupply;
    
    uint256 public commissionPercent = 3;
    uint256 public mintPerBlock = 333333333333333;
    bool public enabledMint = true;
    
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(uint256 => BigTransaction) public transactions;
    mapping(address => uint256) public balances;
    mapping(address => uint) public lastMint;
    mapping(address => bool) public isInvestor;
    mapping(address => bool) public isConfirmed;
    mapping(address => bool) public isMember;
    
    uint256 public totalTransactions;
    uint256 public totalMembers;
    
    event Mint(address indexed to, uint256 value);
    event Commission(uint256 value);
    
    struct BigTransaction {
        uint256 blockNumber;
        uint256 commissionPerMember;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        
        uint256 currentBalance = balances[msg.sender];
        uint256 balanceToMint = getMintableBalance(msg.sender);
        uint256 commission = _value.mul(commissionPercent).div(100);
        
        require((_value.add(commission)) <= (currentBalance.add(balanceToMint)));
        
        if(balanceToMint > 0) {
            currentBalance = currentBalance.add(balanceToMint);
            balances[msg.sender] = currentBalance;
            Mint(msg.sender, balanceToMint);
            lastMint[msg.sender] = block.number;
            totalSupply = totalSupply.add(balanceToMint);
        }
        
        if(totalTransactions > 0 && block.number == transactions[totalTransactions - 1].blockNumber) {
            transactions[totalTransactions - 1].commissionPerMember = transactions[totalTransactions - 1].commissionPerMember.add(commission.div(totalMembers));
        } else {
            uint transactionID = totalTransactions++;
            transactions[transactionID] = BigTransaction(block.number, commission.div(totalMembers));
        }
        
        balances[msg.sender] = currentBalance.sub(_value.add(commission));
        balances[_to] = balances[_to].add(_value);
        
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= allowed[_from][msg.sender]);
        
        uint256 currentBalance = balances[_from];
        uint256 balanceToMint = getMintableBalance(_from);
        uint256 commission = _value.mul(commissionPercent).div(100);
        
        require((_value.add(commission)) <= (currentBalance.add(balanceToMint)));
        
        if(balanceToMint > 0) {
            currentBalance = currentBalance.add(balanceToMint);
            balances[_from] = currentBalance;
            Mint(_from, balanceToMint);
            lastMint[_from] = block.number;
            totalSupply = totalSupply.add(balanceToMint);
        }
        
        if(totalTransactions > 0 && block.number == transactions[totalTransactions - 1].blockNumber) {
            transactions[totalTransactions - 1].commissionPerMember = transactions[totalTransactions - 1].commissionPerMember.add(commission.div(totalMembers));
        } else {
            uint transactionID = totalTransactions++;
            transactions[transactionID] = BigTransaction(block.number, commission.div(totalMembers));
        }
        
        balances[_from] = currentBalance.sub(_value.add(commission));
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        Transfer(_from, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        if(lastMint[_owner] != 0) {
            return balances[_owner].add(getMintableBalance(_owner));
        } else {
            return balances[_owner];
        }
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function setInvestor(address _address) public returns (uint256) {
        if(!isMember[_address]) return 0;
        
        uint256 balanceToMint = getMintableBalance(_address);
        totalSupply = totalSupply.add(balanceToMint);
        balances[_address] = balances[_address].add(balanceToMint);
        lastMint[_address] = block.number;
    }
    
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }
    
    function getMintableBalance(address _address) public constant returns (uint256) {
        if(!enabledMint) return 0;
        if(!isMember[_address]) return 0;
        if(lastMint[_address] == 0) return 0;
        
        uint256 balanceToMint = (block.number.sub(lastMint[_address])).mul(mintPerBlock);
        
        for(uint i = totalTransactions - 1; i >= 0; i--) {
            if(block.number == transactions[i].blockNumber) continue;
            if(transactions[i].blockNumber < lastMint[_address]) return balanceToMint;
            if(transactions[i].commissionPerMember > mintPerBlock) {
                balanceToMint = balanceToMint.add(transactions[i].commissionPerMember.sub(mintPerBlock));
            }
        }
        return balanceToMint;
    }
    
    function stopMint() public onlyOwner {
        enabledMint = false;
    }
    
    function startMint() public onlyOwner {
        enabledMint = true;
    }
    
    function confirm(address _address) onlyOwner public {
        isConfirmed[_address] = true;
        if(!isMember[_address] && isInvestor[_address]) {
            isMember[_address] = true;
            totalMembers = totalMembers.add(1);
            setInvestor(_address);
        }
    }
    
    function unconfirm(address _address) onlyOwner public {
        isConfirmed[_address] = false;
        if(isMember[_address]) {
            isMember[_address] = false;
            totalMembers = totalMembers.sub(1);
        }
    }
    
    function setLastMint(address _address, uint _blockNumber) onlyOwner public {
        lastMint[_address] = _blockNumber;
    }
    
    function setCommissionPercent(uint _percent) onlyOwner public {
        commissionPercent = _percent;
    }
    
    function setMintPerBlock(uint256 _amount) onlyOwner public {
        mintPerBlock = _amount;
    }
    
    function setInvestor(address _address) onlyOwner public {
        isInvestor[_address] = true;
        if(isConfirmed[_address] && !isMember[_address]) {
            isMember[_address] = true;
            totalMembers = totalMembers.add(1);
            setInvestor(_address);
        }
    }
    
    function isMember(address _address) public constant returns (bool) {
        return isMember[_address];
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint;
    
    BigToken public token;
    uint public collected;
    address public beneficiary;
    
    function Crowdsale(address _tokenAddress, address _beneficiary) {
        token = BigToken(_tokenAddress);
        beneficiary = _beneficiary;
        owners[msg.sender] = true;
    }
    
    function () payable {
        require(msg.value >= 0.01 ether);
        
        uint256 amount = msg.value.div(0.01 ether).mul(1 ether);
        
        if(msg.value >= 100 ether && msg.value < 500 ether) 
            amount = amount.mul(11).div(10);
        if(msg.value >= 500 ether && msg.value < 1000 ether) 
            amount = amount.mul(12).div(10);
        if(msg.value >= 1000 ether && msg.value < 5000 ether) 
            amount = amount.mul(13).div(10);
        if(msg.value >= 5000 ether && msg.value < 10000 ether) 
            amount = amount.mul(14).div(10);
        if(msg.value >= 10000 ether) 
            amount = amount.mul(15).div(10);
            
        collected = collected.add(msg.value);
        beneficiary.transfer(msg.value);
        token.setInvestor(msg.sender);
    }
    
    function confirmAddress(address _address) public onlyOwner {
        token.confirm(_address);
    }
    
    function unconfirmAddress(address _address) public onlyOwner {
        token.unconfirm(_address);
    }
    
    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }
    
    function withdrawTokens() public onlyOwner {
        beneficiary.transfer(this.balance);
    }
}
```