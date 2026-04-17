pragma solidity ^0.4.24;

contract Ownable {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Token is Ownable {
    uint private totalSupply = 100000000000;
    uint private balance = 0;

    function incrementBalance() public onlyOwner {
        balance = balance + 1;
    }

    function getBalance() external view returns (uint) {
        return balance;
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    struct Scalar2Vector {
        uint256 balance;
        uint256 totalSupply;
        address owner;
    }

    Scalar2Vector private s2c = Scalar2Vector(0, 0, address(0));

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [1000000000000000, 0];
}