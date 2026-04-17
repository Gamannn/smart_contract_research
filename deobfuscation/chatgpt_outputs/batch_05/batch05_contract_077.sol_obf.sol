pragma solidity ^0.4.24;

contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
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

contract PaymentContract is Ownable {
    mapping (address => mapping (bytes32 => uint)) public payments;
    mapping (address => uint) public balances;
    uint8 public feeRate;

    event PayForUrl(address indexed payer, address indexed payee, string url, uint amount);
    event Withdraw(address indexed payee, uint amount);

    constructor (uint8 initialFeeRate) public {
        feeRate = initialFeeRate;
    }

    function payForUrl(address payee, string url) public payable {
        uint fee = (msg.value * feeRate) / 100;
        balances[getOwner()] += fee;
        balances[payee] += msg.value - fee;
        payments[msg.sender][keccak256(url)] += msg.value;
        emit PayForUrl(msg.sender, payee, url, msg.value);
    }

    function updateFeeRate(uint8 newFeeRate) public onlyOwner {
        require(newFeeRate < feeRate, "Cannot raise fee rate");
        feeRate = newFeeRate;
    }

    function withdraw() public {
        uint balance = balances[msg.sender];
        require(balance > 0, "Balance must be greater than zero");
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
        emit Withdraw(msg.sender, balance);
    }
}