```solidity
pragma solidity ^0.4.25;

contract MainContract {
    TokenContract public tokenContract = TokenContract(0x0);
    AnotherContract anotherContract = AnotherContract(0x0);

    event TokenPurchase(address buyer, uint256 amount, uint256 value);

    struct State {
        address owner;
        address anotherAddress;
        address someAddress;
        uint256 balance1;
        uint256 balance2;
    }

    State state = State(address(0), address(0xdf0960778c6e6597f197ed9a25f12f5d971da86c), address(0), 0, 0);

    constructor() public {
        state.owner = msg.sender;
    }

    function() payable external {}

    function setAnotherContractAddress(address newAddress) external {
        require(msg.sender == state.owner);
        anotherContract = AnotherContract(newAddress);
    }

    function distributeFunds(uint256 percentage1, uint256 percentage2) payable external {
        require(percentage1 <= 100);
        require(percentage2 <= 100);
        require(percentage1 + percentage2 <= 100);

        state.balance1 += (msg.value * percentage1) / 100;
        state.balance2 += (msg.value * percentage2) / 100;
    }

    function setTokenContractAddress(address newAddress) external {
        require(msg.sender == state.owner);
        tokenContract = TokenContract(newAddress);
    }

    function executePurchase(uint256 id, uint256 amount, uint256 value) external {
        require(msg.sender == state.owner);
        require(amount > 0);
        require(anotherContract.isValidId(id));

        address buyer = anotherContract.getAddressById(id);
        require(ExternalContract(buyer).executeTransaction(state.owner, address(anotherContract), amount));

        require(value >= state.balance2);
        state.balance2 -= value;
        state.owner.transfer(value);

        emit TokenPurchase(buyer, amount, value);
    }

    function updateBalance1(uint256 newBalance) external {
        require(msg.sender == state.owner);
        require(newBalance < (address(this).balance - state.balance2));
        state.balance1 = newBalance;
    }

    function updateBalance2(uint256 newBalance) external {
        require(msg.sender == state.owner);
        require(newBalance < (address(this).balance - state.balance1));
        state.balance2 = newBalance;
    }

    function processTransaction(address recipient, uint256 amount, address, bytes) external {
        require(msg.sender == state.anotherAddress);

        uint256 calculatedValue = tokenContract.calculateValue(amount);
        require(calculatedValue <= state.balance1);

        ExternalContract(msg.sender).executeTransaction(recipient, address(0), amount);
        state.balance1 -= calculatedValue;
        recipient.transfer(calculatedValue);
    }
}

contract TokenContract {
    MainContract constant mainContract = MainContract(0x66a9f1e53173de33bec727ef76afa84956ae1b25);
    ExternalContract constant externalContract = ExternalContract(0xdf0960778c6e6597f197ed9a25f12f5d971da86c);

    constructor() public {
        owner = msg.sender;
    }

    function calculateValue(uint256 amount) external view returns(uint256 value) {
        value = (mainContract.balance1() * amount) / (externalContract.getSomeValue() * 2);
    }

    function getSomeValue() external view returns(uint256 value) {
        value = mainContract.balance1() / (externalContract.getSomeValue() * 2);
    }
}

contract AnotherContract {
    function isValidId(uint256 id) public view returns (bool);
    mapping(uint256 => address) public getAddressById;
}

contract ExternalContract {
    function getSomeValue() external view returns(uint256);
    function executeTransaction(address from, address to, uint amount) external returns (bool success);
}
```