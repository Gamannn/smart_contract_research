```solidity
pragma solidity ^0.4.16;

contract TokenInterface {
    function balanceOf(address owner) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function addOwner(address newOwner) public onlyOwner {
        owners[newOwner] = true;
    }

    function removeOwner(address owner) public onlyOwner {
        owners[owner] = false;
    }
}

contract BigToken is TokenInterface, Ownable {
    using SafeMath for uint256;

    string public name = "Big Token";
    string public symbol = "BIG";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => uint) public lastMintBlock;
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isConfirmed;
    mapping(address => bool) public isBlacklisted;

    event Mint(address indexed to, uint256 amount);
    event Commission(uint256 amount);

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        uint256 senderBalance = balances[msg.sender];
        uint256 mintAmount = calculateMintAmount(msg.sender);
        uint256 commission = value.mul(commissionPercent).div(100);
        require((value + commission) <= (senderBalance + mintAmount));

        if (mintAmount > 0) {
            senderBalance = senderBalance.add(mintAmount);
            Mint(msg.sender, mintAmount);
            lastMintBlock[msg.sender] = block.number;
            totalSupply = totalSupply.add(mintAmount);
        }

        balances[msg.sender] = senderBalance.sub(value + commission);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= allowed[from][msg.sender]);

        uint256 fromBalance = balances[from];
        uint256 mintAmount = calculateMintAmount(from);
        uint256 commission = value.mul(commissionPercent).div(100);
        require((value + commission) <= (fromBalance + mintAmount));

        if (mintAmount > 0) {
            fromBalance = fromBalance.add(mintAmount);
            Mint(from, mintAmount);
            lastMintBlock[from] = block.number;
            totalSupply = totalSupply.add(mintAmount);
        }

        balances[from] = fromBalance.sub(value + commission);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

    function balanceOf(address owner) public constant returns (uint256) {
        if (lastMintBlock[owner] != 0) {
            return balances[owner] + calculateMintAmount(owner);
        } else {
            return balances[owner];
        }
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowed[owner][spender];
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function calculateMintAmount(address owner) public constant returns (uint256) {
        if (!isMinter[owner]) return 0;
        if (!isConfirmed[owner]) return 0;
        if (lastMintBlock[owner] == 0) return 0;

        uint256 balanceToMint = (block.number - lastMintBlock[owner]) * mintPerBlock;
        for (uint i = totalTransactions - 1; i >= 0; i--) {
            if (transactions[i].blockNumber == block.number) continue;
            if (transactions[i].blockNumber < lastMintBlock[owner]) return balanceToMint;
            if (balanceToMint > mintPerBlock) {
                balanceToMint = balanceToMint.add(transactions[i].amount - mintPerBlock);
            }
        }
        return balanceToMint;
    }

    function disableMinting() public onlyOwner {
        mintingEnabled = false;
    }

    function enableMinting() public onlyOwner {
        mintingEnabled = true;
    }

    function confirmMinter(address owner) public onlyOwner {
        isConfirmed[owner] = true;
        if (!isMinter[owner] && isBlacklisted[owner]) {
            isMinter[owner] = true;
            totalMembers++;
            setLastMint(owner, block.number);
        }
    }

    function unconfirmMinter(address owner) public onlyOwner {
        isConfirmed[owner] = false;
        if (isMinter[owner]) {
            isMinter[owner] = false;
            totalMembers--;
        }
    }

    function setLastMint(address owner, uint blockNumber) public onlyOwner {
        lastMintBlock[owner] = blockNumber;
    }

    function setCommissionPercent(uint percent) public onlyOwner {
        commissionPercent = percent;
    }

    function setMintPerBlock(uint amount) public onlyOwner {
        mintPerBlock = amount;
    }

    function blacklist(address owner) public onlyOwner {
        isBlacklisted[owner] = true;
        if (isConfirmed[owner] && !isMinter[owner]) {
            isMinter[owner] = true;
            calculateMintAmount(owner);
        }
    }

    function isMinter(address owner) public constant returns (bool) {
        return isMinter[owner];
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint;

    BigToken public token;
    uint public collected;
    address public beneficiary;

    function Crowdsale(address tokenAddress, address beneficiaryAddress) {
        token = BigToken(tokenAddress);
        beneficiary = beneficiaryAddress;
        owners[msg.sender] = true;
    }

    function () payable {
        require(msg.value >= 0.01 ether);
        uint256 tokens = msg.value.div(0.01 ether).mul(1 ether);
        if (msg.value >= 100 ether && msg.value < 500 ether) tokens = tokens.mul(11).div(10);
        if (msg.value >= 500 ether && msg.value < 1000 ether) tokens = tokens.mul(12).div(10);
        if (msg.value >= 1000 ether && msg.value < 5000 ether) tokens = tokens.mul(13).div(10);
        if (msg.value >= 5000 ether && msg.value < 10000 ether) tokens = tokens.mul(14).div(10);
        if (msg.value >= 10000 ether) tokens = tokens.mul(15).div(10);

        collected = collected.add(msg.value);
        beneficiary.transfer(msg.value);
        token.transfer(msg.sender, tokens);
    }

    function setBeneficiary(address newBeneficiary) public onlyOwner {
        beneficiary = newBeneficiary;
    }

    function withdraw() public onlyOwner {
        beneficiary.transfer(this.balance);
    }
}
```