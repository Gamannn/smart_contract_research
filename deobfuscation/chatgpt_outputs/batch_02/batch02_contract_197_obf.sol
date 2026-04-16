pragma solidity ^0.4.0;

contract BaseContract {
    address public owner;

    function BaseContract() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TokenContract is BaseContract {
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function TokenContract() payable BaseContract() {
        totalSupply = 21000000;
        balances[owner] = 20000000;
        balances[this] = totalSupply - balances[owner];
        Transfer(this, owner, balances[owner]);
    }

    function () payable {
        require(balances[this] > 0);
        uint256 tokensPerOneEth = 3000;
        uint256 tokensToTransfer = tokensPerOneEth * msg.value / 1 ether;
        if (tokensToTransfer > balances[this]) {
            tokensToTransfer = balances[this];
            uint256 refund = tokensToTransfer * 1 ether / tokensPerOneEth;
            msg.sender.transfer(msg.value - refund);
        }
        require(tokensToTransfer > 0);
        balances[msg.sender] += tokensToTransfer;
        balances[this] -= tokensToTransfer;
        Transfer(this, msg.sender, tokensToTransfer);
    }
}

contract TransferContract {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 value) public {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
    }
}

contract FinalContract is TransferContract {
    function FinalContract() payable TransferContract() {}

    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }

    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}

struct Scalar2Vector {
    uint8 someUint;
    string name;
    string symbol;
    string description;
    uint256 totalSupply;
    address owner;
}

Scalar2Vector s2c = Scalar2Vector("OSM", "Osmiu", "Token 0.1", "", 0, address(0));

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

function getStrFunc(uint256 index) internal view returns(string storage) {
    return _string_constant[index];
}

uint256[] public _integer_constant = [3000, 20000000, 0, 21000000, 1000000000000000000];
string[] public _string_constant = ["Token 0.1", "OSM", "Ox701b98a5caebfdbd430561a20c25e79f93895dcb"];