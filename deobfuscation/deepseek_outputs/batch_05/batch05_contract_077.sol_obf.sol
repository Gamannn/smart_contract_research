pragma solidity ^0.4.24;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PaymentContract is Ownable {
    mapping (address => mapping (bytes32 => uint)) public payments;
    mapping (address => uint) public balances;
    uint8 public feeRate;

    event PayForUrl(address indexed payer, address indexed recipient, string url, uint amount);
    event Withdraw(address indexed recipient, uint amount);

    constructor (uint8 _feeRate) public {
        feeRate = _feeRate;
    }

    function pay(address recipient, string memory url) public payable {
        uint fee = (msg.value * feeRate) / 100;
        balances[owner()] += fee;
        balances[recipient] += msg.value - fee;
        payments[msg.sender][keccak256(bytes(url))] += msg.value;
        emit PayForUrl(msg.sender, recipient, url, msg.value);
    }

    function setFeeRate(uint8 newFeeRate) public onlyOwner {
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