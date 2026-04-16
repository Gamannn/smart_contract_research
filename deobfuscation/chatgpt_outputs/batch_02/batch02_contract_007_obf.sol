pragma solidity ^0.4.24;

contract Ownable {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier notOwner(address newOwner) {
        require(newOwner != owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner notOwner(newOwner) {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TimelockWallet is Ownable {
    uint256 public unlockTime;

    constructor(uint256 _unlockTime) public {
        unlockTime = _unlockTime;
    }

    function() public payable {}

    function isLocked() public view returns (bool) {
        return now <= unlockTime;
    }

    function destroy() external onlyOwner {
        require(isLocked());
        selfdestruct(owner);
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [0];
}