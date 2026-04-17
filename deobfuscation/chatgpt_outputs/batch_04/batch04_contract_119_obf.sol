```solidity
pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract Presale is Pausable {
    mapping(address => uint256) public packageCount;
    uint256 public totalPackages = 10000;
    uint256 public remainingPackages = 10000;

    event BuyPresale(address indexed buyer);

    function buyPackage() public payable whenNotPaused {
        require(packageCount[msg.sender] + 1 <= 5); // Assuming a limit of 5 packages per address
        require(remainingPackages > 0);

        uint256 price = 20 finney + (10000 - remainingPackages) * 10 finney;
        require(msg.value >= price);

        packageCount[msg.sender] += 1;
        remainingPackages -= 1;

        BuyPresale(msg.sender);
    }

    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }
}
```