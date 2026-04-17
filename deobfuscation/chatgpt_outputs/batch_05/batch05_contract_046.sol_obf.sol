```solidity
pragma solidity ^0.4.24;

contract Token {
    string public name = "Yellow Better";
    string public symbol = "YBT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 2000000000000000000000000000;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function _safeSub(uint256 a, uint256 b) private pure returns (uint256) {
        require(a >= b);
        return a - b;
    }

    function getBalance(address account) public view returns (uint256) {
        return balanceOf[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        balanceOf[msg.sender] = _safeSub(balanceOf[msg.sender], value);
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        balanceOf[from] = _safeSub(balanceOf[from], value);
        allowance[from][msg.sender] = _safeSub(allowance[from][msg.sender], value);
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getAllowance(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }

    function burn(uint256 value) public {
        balanceOf[msg.sender] = _safeSub(balanceOf[msg.sender], value);
        totalSupply = _safeSub(totalSupply, value);
        emit Burn(msg.sender, value);
    }
}

contract Crowdsale {
    address public owner;
    address public tokenContract;
    uint256 public tokenPrice;
    uint256 public deadline;

    constructor(address _tokenContract) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setDeadline(uint256 _deadline) public onlyOwner {
        deadline = _deadline;
    }

    function buyTokens(address beneficiary) public payable {
        require(block.timestamp < deadline && tokenPrice > 0);
        uint256 tokens = msg.value * 1000000000000000000 / tokenPrice;
        require(Token(tokenContract).transfer(beneficiary, tokens));
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}
```