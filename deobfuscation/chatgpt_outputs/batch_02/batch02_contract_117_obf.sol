```solidity
pragma solidity ^0.4.21;

interface ITokenReceiver {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}

contract Ownable {
    address public owner;
    bool public ownershipTransferAllowed;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwnershipTransferAllowed(bool allowed) public onlyOwner {
        ownershipTransferAllowed = allowed;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        require(ownershipTransferAllowed);
        owner = newOwner;
    }
}

contract HoneycombToken is Ownable {
    string public name = "Honeycomb";
    string public symbol = "COMB";
    uint256 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        totalSupply = 1048576 * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function calculatePrice(uint256 tokens) internal view returns (uint256) {
        return (tokens * 141421356) / 100000000;
    }

    function buyTokens() payable public returns (uint256) {
        uint256 tokens = (msg.value * totalSupply) / (10 ** decimals);
        require(balanceOf[address(this)] >= tokens);
        balanceOf[msg.sender] += tokens;
        balanceOf[address(this)] -= tokens;
        emit Transfer(address(this), msg.sender, tokens);
        return tokens;
    }

    function () payable public {
        buyTokens();
    }

    function sellTokens(uint256 tokens) public returns (uint256) {
        uint256 etherAmount = (tokens * (10 ** decimals)) / calculatePrice(tokens);
        require(etherAmount >= 1 ether);
        require(balanceOf[msg.sender] >= tokens);
        balanceOf[msg.sender] -= tokens;
        balanceOf[address(this)] += tokens;
        msg.sender.transfer(etherAmount);
        emit Transfer(msg.sender, address(this), tokens);
        return etherAmount;
    }

    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool) {
        allowance[msg.sender][spender] = tokens;
        ITokenReceiver(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(balanceOf[msg.sender] >= tokens);
        balanceOf[msg.sender] -= tokens;
        balanceOf[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(tokens <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= tokens;
        require(balanceOf[from] >= tokens);
        balanceOf[from] -= tokens;
        balanceOf[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        allowance[msg.sender][spender] = tokens;
        return true;
    }

    function setMinimumPayout(uint256 amount) public onlyOwner {
        require(amount >= 1 ether);
        owner.transfer(amount);
    }

    function internalTransfer(address from, address to, uint256 tokens) internal {
        require(to != address(0));
        require(balanceOf[from] >= tokens);
        balanceOf[from] -= tokens;
        balanceOf[to] += tokens;
        emit Transfer(from, to, tokens);
    }
}
```