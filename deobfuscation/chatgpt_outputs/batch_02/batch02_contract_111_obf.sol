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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Token {
    function transfer(address to, uint256 value) public returns (bool);
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    uint public startTime = 1512118800;
    uint public endTime;
    uint public tokensSold = 0;
    bool public isFinalized = false;
    address public wallet;
    Token public token;
    mapping(address => bool) public whitelist;

    function Crowdsale(address _tokenAddress, address _wallet, address _whitelistAddress) public {
        token = Token(_tokenAddress);
        wallet = _wallet;
        whitelist[_whitelistAddress] = true;
    }

    function buyTokens(address beneficiary) public payable {
        require(msg.value != 0);
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.div(0.005 ether);
        _processPurchase(beneficiary, tokens);
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) private {
        require(beneficiary != address(0));
        require(_isWhitelisted(beneficiary));
        uint256 minPurchase = 20000;
        if (tokensSold < 860000000.sub(minPurchase)) {
            require(tokenAmount >= minPurchase);
        }
        require(tokensSold.add(tokenAmount) <= 860000000);
        tokensSold = tokensSold.add(tokenAmount);
        token.transfer(beneficiary, tokenAmount);
    }

    function _isWhitelisted(address beneficiary) internal view returns (bool) {
        return whitelist[beneficiary];
    }

    function setWhitelist(address beneficiary, bool isWhitelisted) external onlyOwner {
        whitelist[beneficiary] = isWhitelisted;
    }

    function setStartTime(uint newStartTime) external onlyOwner {
        startTime = newStartTime;
    }

    function setEndTime(uint newEndTime) external onlyOwner {
        endTime = newEndTime;
    }

    function finalize() external onlyOwner {
        require(!isFinalized);
        isFinalized = true;
        wallet.transfer(this.balance / 2);
        owner.transfer(this.balance / 2);
    }
}
```