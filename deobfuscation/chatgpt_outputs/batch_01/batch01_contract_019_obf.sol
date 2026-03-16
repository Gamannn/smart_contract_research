pragma solidity ^0.5.0;

contract SimpleWallet {
    address payable private owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function deposit() external payable {
    }

    function withdrawAll() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}