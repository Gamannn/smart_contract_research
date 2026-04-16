```solidity
pragma solidity ^0.4.21;

contract Token {
    function transfer(uint amount, address recipient) payable {
        amount;
        recipient;
    }
}

contract MainContract {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    address public owner;
    Token public tokenContract;
    bool public isActive;
    
    uint256[] public _integer_constant = [200000000000000000, 51];
    bool[] public _bool_constant = [true];
    
    struct Storage {
        bool isActive;
        address owner;
    }
    
    Storage s2c = Storage(false, address(0));
    
    function MainContract() public {
        owner = msg.sender;
    }
    
    function setTokenContract(address tokenAddress) public onlyOwner {
        tokenContract = Token(tokenAddress);
    }
    
    function setActive(bool active) public onlyOwner {
        isActive = active;
    }
    
    function() payable {
        if (isActive == true) {
            require(msg.value == _integer_constant[0]);
            tokenContract.transfer(_integer_constant[1], msg.sender);
        } else {
            return;
        }
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    function getBoolFunc(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }
}
```