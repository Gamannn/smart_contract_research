pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier notOwner(address _address) {
        require(_address != owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) external onlyOwner notOwner(_newOwner) {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract TimeLockedWallet is Ownable {
    uint256 public unlockTime;

    constructor(uint256 _unlockTime) public {
        unlockTime = _unlockTime;
    }

    function isLocked() public view returns (bool) {
        return now <= unlockTime;
    }

    function withdraw() external onlyOwner {
        require(!isLocked());
        selfdestruct(owner);
    }
}