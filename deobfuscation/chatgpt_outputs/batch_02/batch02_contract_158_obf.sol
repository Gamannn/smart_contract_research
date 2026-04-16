```solidity
pragma solidity ^0.4.25;

interface IExternalContract {
    function() payable external;
    function deposit(address recipient) external payable;
    function withdraw() external;
    function getBalance() external view returns(uint256);
    function execute() external;
    function transfer(address recipient, uint256 amount) external payable;
    function approve(address spender) external;
    function revoke() external;
    function authorize(address account) external;
}

contract BaseContract {
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

contract MainContract is BaseContract {
    using SafeMath for uint;

    IExternalContract constant externalContract = IExternalContract(0x31cF8B6E8bB6cB16F23889F902be86775bB1d0B3);
    uint256 public contractBalance;

    function getContractBalance() view public returns(uint256) {
        return contractBalance;
    }

    function getExternalBalance() view public returns(uint256) {
        return externalContract.getBalance();
    }

    function deposit() public payable {
        contractBalance = contractBalance.add(msg.value);
    }

    function transferToExternal(address recipient) public {
        require(contractBalance > 0.1 ether);
        externalContract.transfer.value(1 ether)(recipient, 1);
    }

    function withdraw() public {
        uint256 amount = address(this).balance.sub(contractBalance);
        msg.sender.transfer(amount);
    }

    function () external payable {}
}

function getIntegerConstant(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

function getAddressConstant(uint256 index) internal view returns(address payable) {
    return _address_constant[index];
}

uint256[] public _integer_constant = [0, 1, 100000000000000000];
address payable[] public _address_constant = [0x31cF8B6E8bB6cB16F23889F902be86775bB1d0B3, 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220];
```