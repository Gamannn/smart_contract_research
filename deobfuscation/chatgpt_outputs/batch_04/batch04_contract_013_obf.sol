pragma solidity ^0.4.18;

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract Owned {
    address public owner;

    function Owned() public {
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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

contract StandardToken is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
}

contract ApproveAndCallFallback {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Token is StandardToken, Owned {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public buyPriceInWei;
    uint256 public sellPriceInWei;
    uint256 public minBalanceForAccounts;
    address public companyWallet;
    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    function Token() public {
        symbol = "GEO";
        name = "Geocash";
        decimals = 18;
        totalSupply = 500000000 * (10 ** uint256(decimals));
        balances[this] = totalSupply;
        companyWallet = msg.sender;
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[to]);
        require(tokens <= balances[msg.sender]);

        if (msg.sender.balance < minBalanceForAccounts) {
            sell((minBalanceForAccounts.sub(msg.sender.balance)).div(sellPriceInWei));
        }

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPriceInWei = newSellPrice;
        buyPriceInWei = newBuyPrice;
    }

    function setMinBalance(uint256 minimumBalanceInWei) public onlyOwner {
        minBalanceForAccounts = minimumBalanceInWei;
    }

    function setCompanyWallet(address newWallet) public onlyOwner {
        require(newWallet != address(0));
        companyWallet = newWallet;
    }

    function buy() public payable returns (uint256 amount) {
        require(msg.sender != address(0));
        require(msg.value > 0);

        amount = msg.value.div(buyPriceInWei);
        require(amount > 0);
        require(balances[this] >= amount);

        balances[this] = balances[this].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        Transfer(this, msg.sender, amount);
        return amount;
    }

    function sell(uint256 amount) internal returns (uint256 revenue) {
        require(amount > 0);
        require(balances[msg.sender] >= amount);

        balances[this] = balances[this].add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);

        revenue = amount.mul(sellPriceInWei);
        require(revenue > 0);

        if (!msg.sender.send(revenue)) {
            revert();
        } else {
            Transfer(msg.sender, this, amount);
            return amount;
        }
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setSellPrice(uint256 newSellPrice) public onlyOwner {
        sellPriceInWei = newSellPrice;
    }

    function withdrawEther(uint256 amount) public onlyOwner {
        require(amount > 0);
        companyWallet.transfer(amount);
    }

    function mintToken(address target, uint256 mintedAmount) public onlyOwner returns (bool) {
        require(target != address(0));

        balances[this] = balances[this].sub(mintedAmount);
        balances[target] = balances[target].add(mintedAmount);
        Transfer(this, target, mintedAmount);
        return true;
    }

    function () external payable {
        buy();
    }
}