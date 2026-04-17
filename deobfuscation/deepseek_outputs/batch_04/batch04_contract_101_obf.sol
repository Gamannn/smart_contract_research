```solidity
pragma solidity ^0.4.24;

contract Ownable {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address public owner;

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
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Counter is Ownable {
    uint256 public constant MAX_COUNT = 100000000000;
    uint256 public count = 0;

    function increment() public {
        require(count < MAX_COUNT);
        count += 1;
    }

    function getCount() external view returns (uint256) {
        return count;
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}
```