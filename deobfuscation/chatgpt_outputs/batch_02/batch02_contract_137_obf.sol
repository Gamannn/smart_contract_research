```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract ERC20 {
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address owner) public constant returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract TokenSale is Ownable {
    using SafeMath for uint256;

    uint256 public constant COINS_PER_ETH = 12000;
    uint256 public constant BONUS_PERCENTAGE = 25;
    uint256 public constant MIN_CONTRIBUTION = 1 ether;
    uint8 public saleState = 0; // 0: Not started, 1: Active, 2: Failed, 3: Successful

    ERC20 public token;
    uint256 public totalEthCollected;
    uint256 public totalTokensSold;

    mapping(address => uint256) public ethContributed;
    mapping(address => uint256) public tokensPurchased;

    event SaleStarted();
    event SaleClosedSuccess(uint256 totalTokensSold);
    event SaleClosedFail(uint256 totalTokensSold);

    constructor(address tokenAddress) public {
        token = ERC20(tokenAddress);
        owner = msg.sender;
    }

    function getTokenBalance() public view returns (uint256) {
        return token.allowance(owner, address(this));
    }

    function () payable public {
        if ((saleState == 3 || saleState == 4) && msg.value == 0) {
            refund();
        } else if (saleState == 2 && msg.value == 0) {
            claimTokens();
        } else {
            buyTokens();
        }
    }

    function buyTokens() payable public {
        require(saleState == 1);
        uint256 tokens = msg.value.mul(COINS_PER_ETH).div(MIN_CONTRIBUTION).mul(1 ether);
        tokens = applyBonus(tokens);
        require(tokens > 0);

        token.transferFrom(owner, msg.sender, tokens);
        tokensPurchased[msg.sender] = tokensPurchased[msg.sender].add(tokens);
        ethContributed[msg.sender] = ethContributed[msg.sender].add(msg.value);
        totalEthCollected = totalEthCollected.add(msg.value);
        totalTokensSold = totalTokensSold.add(tokens);
    }

    function applyBonus(uint256 tokens) internal pure returns (uint256) {
        uint256 bonus = tokens.mul(BONUS_PERCENTAGE).div(100);
        return tokens.add(bonus);
    }

    function isSaleActive() public constant returns (bool) {
        return saleState == 1;
    }

    function claimTokens() public {
        require(saleState == 2);
        uint256 tokens = tokensPurchased[msg.sender];
        require(tokens > 0);

        uint256 ethAmount = ethContributed[msg.sender];
        msg.sender.transfer(ethAmount);

        token.transferFrom(owner, msg.sender, tokens);
        ethContributed[msg.sender] = 0;
        tokensPurchased[msg.sender] = 0;
        totalEthCollected = totalEthCollected.sub(ethAmount);
    }

    function withdraw() public onlyOwner {
        require(saleState == 3);
        owner.transfer(totalEthCollected);
        totalEthCollected = 0;
    }

    function refund() public {
        require(saleState == 3 || saleState == 4);
        require(ethContributed[msg.sender] > 0);

        uint256 ethAmount = ethContributed[msg.sender];
        msg.sender.transfer(ethAmount);
        ethContributed[msg.sender] = 0;
    }

    function startSale() public onlyOwner {
        require(saleState == 0);
        saleState = 1;
        emit SaleStarted();
    }

    function closeSaleSuccess() public onlyOwner {
        require(saleState == 1);
        saleState = 3;
        emit SaleClosedSuccess(totalTokensSold);
    }

    function closeSaleFail() public onlyOwner {
        require(saleState == 1);
        saleState = 2;
        emit SaleClosedFail(totalTokensSold);
    }
}
```