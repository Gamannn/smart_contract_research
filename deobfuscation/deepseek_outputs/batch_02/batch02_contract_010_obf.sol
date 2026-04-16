pragma solidity ^0.4.4;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract ERC20Token is ERC20Interface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address to, uint256 tokens) public returns (bool success) {
        if (balances[msg.sender] >= tokens && tokens > 0) {
            balances[msg.sender] -= tokens;
            balances[to] += tokens;
            Transfer(msg.sender, to, tokens);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        if (balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0) {
            balances[to] += tokens;
            balances[from] -= tokens;
            allowed[from][msg.sender] -= tokens;
            Transfer(from, to, tokens);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
}

contract DividendCryptoFund is ERC20Token {
    address public fundsWallet;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    string public name;
    uint256 public decimals;
    string public symbol;
    uint8 public version;

    function DividendCryptoFund() {
        balances[msg.sender] = 100000;
        totalSupply = 100000;
        name = "Dividend Crypto Fund";
        decimals = 1;
        symbol = "DCRF";
        version = 1;
        fundsWallet = msg.sender;
        unitsOneEthCanBuy = 1;
    }

    function() payable {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] < amount) {
            return;
        }
        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        Transfer(fundsWallet, msg.sender, amount);
        fundsWallet.transfer(msg.value);
    }

    function approveAndCall(address spender, uint256 tokens, bytes data) returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        if(!spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, tokens, this, data)) {
            throw;
        }
        return true;
    }
}