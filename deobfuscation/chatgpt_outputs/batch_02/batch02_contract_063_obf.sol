```solidity
pragma solidity ^0.4.25;

interface ExternalContractInterface {
    function() payable external;
    function deposit(address recipient) external payable;
    function withdraw() external;
    function getBalance() external view returns(uint256);
    function execute() external;
    function transfer(address recipient) external payable;
    function approve(address spender) external;
    function finalize() external;
}

contract OwnerContract {
    address public owner;

    constructor() public {
        owner = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        return a / b;
    }
}

contract MainContract is OwnerContract {
    using SafeMath for uint;

    ExternalContractInterface constant externalContract = ExternalContractInterface(0xb172BB8BAae74F27Ade3211E0c145388d3b4f8d8);

    uint256 public contractBalance;

    function getExternalBalance() view public returns(uint256) {
        return externalContract.getBalance();
    }

    function deposit() public payable {
        contractBalance = contractBalance.add(msg.value);
    }

    function transferToExternal(address recipient) public {
        require(contractBalance > 0.1 ether);
        contractBalance = contractBalance.sub(0.1 ether);
        externalContract.deposit.value(0.1 ether)(recipient);
        externalContract.finalize();
    }

    function executeExternal() public {
        externalContract.execute();
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance.sub(contractBalance);
        msg.sender.transfer(amount);
    }

    function() external payable {}
}

function getAddress(uint256 index) internal view returns(address payable) {
    return _address_constant[index];
}

function getInteger(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

address payable[] public _address_constant = [0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220, 0xb172BB8BAae74F27Ade3211E0c145388d3b4f8d8];
uint256[] public _integer_constant = [0, 100000000000000000];
```