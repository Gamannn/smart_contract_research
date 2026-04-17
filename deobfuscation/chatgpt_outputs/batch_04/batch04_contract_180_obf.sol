```solidity
pragma solidity ^0.5.6;

contract Ownable {
    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }

    function() external payable {}

    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

interface IContractReceiver {
    function tokenFallback(address from, uint value, bytes32 data) external;
}

contract Token is Ownable, IERC20 {
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 20000000000000000000000000000;
    string public constant name = "SATT";
    string public constant symbol = "Smart Advertising Transaction Token";

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 && codehash != bytes32(0));
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transfer(address to, uint256 value, bytes memory data) public returns (bool) {
        if (data.length != 0) {
            _transfer(msg.sender, to, value);
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);

        balanceOf[from] -= value;
        balanceOf[to] += value;

        if (isContract(to)) {
            IContractReceiver receiver = IContractReceiver(to);
            receiver.tokenFallback(msg.sender, value, bytes32(0));
        }

        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function externalTransfer(address tokenAddress, address to, uint256 value) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(to, value);
    }

    function tokenFallback(address from, uint value, bytes memory data) pure public {}
}
```