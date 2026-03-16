```solidity
pragma solidity ^0.4.21;

contract Ownable {
    struct OwnerData {
        uint256 feeRate;
        uint256 conversionRate;
        address feeRecipient;
        address owner;
    }
    
    OwnerData ownerData = OwnerData(0, 0, address(0), address(0));

    function Ownable() public {
        ownerData.owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerData.owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            ownerData.owner = newOwner;
        }
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint256) {
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint64 a, uint64 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint64 a, uint64 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return whitelist[addr];
    }

    function addToWhitelist(address addr) public onlyOwner {
        whitelist[addr] = true;
    }

    function removeFromWhitelist(address addr) public onlyOwner {
        delete whitelist[addr];
    }
}

contract TokenInterface {
    function balanceOf(uint tokenAmount) public view returns (uint);
    function transfer(address to) public payable;
}

contract TokenSale is TokenInterface, Ownable, Whitelist {
    using SafeMath for uint256;

    mapping(address => uint) public balances;

    function TokenSale(address feeRecipient, uint conversionRate, uint feeRate) public {
        ownerData.feeRecipient = feeRecipient;
        ownerData.conversionRate = conversionRate;
        ownerData.feeRate = feeRate;
    }

    function setFeeRecipient(address feeRecipient) public onlyOwner {
        ownerData.feeRecipient = feeRecipient;
    }

    function setConversionRate(uint conversionRate) public onlyOwner {
        ownerData.conversionRate = conversionRate;
    }

    function setFeeRate(uint feeRate) public onlyOwner {
        ownerData.feeRate = feeRate;
    }

    function balanceOf(uint tokenAmount) public view returns (uint) {
        return SafeMath.mul(tokenAmount, ownerData.conversionRate) / (1 ether);
    }

    function calculateFee(uint tokenAmount) public view returns (uint) {
        return SafeMath.mul(tokenAmount, ownerData.feeRate) / (1 ether);
    }

    function transfer(address to) public payable onlyWhitelisted {
        if (to == address(0)) {
            balances[ownerData.feeRecipient] = balances[ownerData.feeRecipient].add(msg.value);
        } else {
            uint fee = calculateFee(msg.value);
            balances[to] = balances[to].add(fee);
            balances[ownerData.feeRecipient] = balances[ownerData.feeRecipient].add(SafeMath.sub(msg.value, fee));
        }
    }

    function withdraw() public {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}
```