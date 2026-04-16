```solidity
pragma solidity ^0.4.13;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData);
}

contract MyToken is Ownable {
    string public name;
    string public symbol;
    bool public icoFinished;
    uint256 public exchangeRate = 1;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event IcoFinished();

    function transfer(address to, uint256 value) public {
        require(!icoFinished);
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool success) {
        TokenRecipient recipient = TokenRecipient(spender);
        if (approve(spender, value)) {
            recipient.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(!icoFinished);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }

    function buyTokens(uint256 ethAmount, uint256 currentTime) internal {
        require(!icoFinished);
        require(currentTime >= _integer_constant[7] && currentTime <= _integer_constant[6]);
        require(ethAmount > 0);
        uint256 tokenAmount = ethAmount / exchangeRate;
        require(balanceOf[this] >= tokenAmount);
        balanceOf[msg.sender] += tokenAmount;
        balanceOf[this] -= tokenAmount;
        Transfer(this, msg.sender, tokenAmount);
    }

    function () payable public {
        buyTokens(msg.value, now);
    }

    function finalizeIco(uint256 currentTime) internal returns (bool) {
        if (currentTime > _integer_constant[6]) {
            uint256 remainingTokens = balanceOf[this];
            balanceOf[owner] += remainingTokens;
            balanceOf[this] = 0;
            Transfer(this, owner, remainingTokens);
            IcoFinished();
            icoFinished = true;
            return true;
        }
        return false;
    }

    function finalize() public onlyOwner {
        finalizeIco(now);
    }

    function withdrawEther() public onlyOwner {
        owner.transfer(this.balance);
    }

    function setExchangeRate(uint256 newRate) public onlyOwner {
        exchangeRate = newRate;
    }

    function setIcoFinished(bool finished) public onlyOwner {
        icoFinished = finished;
    }

    string[] public _string_constant = ["MyToken 0.1"];
    uint256[] public _integer_constant = [90, 0, 100, 10, 1, 14, 1505865600, 1503187200];
    bool[] public _bool_constant = [true, false];
}
```