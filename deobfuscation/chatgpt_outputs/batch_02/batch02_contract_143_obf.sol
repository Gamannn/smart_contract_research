```solidity
pragma solidity ^0.4.25;

interface ExternalContract {
    function() payable external;
    function deposit(address recipient) external payable;
    function withdraw() external;
    function getBalance() external view returns(uint256);
    function execute() external;
    function transfer(address recipient, uint256 amount) external payable;
    function authorize(address account) external;
    function finalize() external;
    function register(address account) external;
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
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract MainContract is OwnerContract {
    using SafeMath for uint;

    ExternalContract constant externalContract = ExternalContract(0x31cF8B6E8bB6cB16F23889F902be86775bB1d0B3);

    uint256 public balance;

    function getContractBalance() view public returns(uint256) {
        return balance;
    }

    function getExternalBalance() view public returns(uint256) {
        return externalContract.getBalance();
    }

    function deposit() public payable {
        balance = balance.add(msg.value);
    }

    function transferFunds(address recipient, uint256 amount) public {
        require(balance > amount.mul(0.1 ether));
        balance = balance.sub(amount.mul(0.1 ether));
        externalContract.transfer.value(amount.mul(0.1 ether))(recipient, amount);
    }

    function registerContract() public {
        externalContract.register(address(this));
    }

    function finalizeContract() public {
        externalContract.finalize();
    }

    function withdrawFunds() public {
        uint256 withdrawAmount = address(this).balance.sub(balance);
        msg.sender.transfer(withdrawAmount);
    }

    function() external payable {}

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }

    uint256[] public _integer_constant = [100000000000000000, 0];
    address payable[] public _address_constant = [0x31cF8B6E8bB6cB16F23889F902be86775bB1d0B3, 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220];
}
```