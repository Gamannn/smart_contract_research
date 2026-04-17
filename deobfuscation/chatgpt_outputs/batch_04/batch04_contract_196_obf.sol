```solidity
pragma solidity ^0.4.24;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract Crowdsale {
    mapping(address => uint256) public contributions;
    bool public isFinalized;
    bool public isPicopsEnabled;
    uint256 public totalRaised;
    uint256 public maxRaisedAmount;
    address public creator;
    address public picopsAddress;
    address public crowdsaleAddress;
    uint256 public drainBlock;
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public picopsFee;
    uint256 public picopsFeePercentage;
    bool public isRefundEnabled;
    bool public isSaleActive;

    struct Scalar2Vector {
        bool isFinalized;
        address picopsAddress;
        uint256 startBlock;
        uint256 drainBlock;
        address crowdsaleAddress;
        address creator;
        uint256 maxRaisedAmount;
        uint256 picopsFee;
        uint256 totalRaised;
        bool isRefundEnabled;
        bool isSaleActive;
    }

    Scalar2Vector s2c = Scalar2Vector(false, address(0), 0, 0, address(0), 0x5777c72Fb022DdF1185D3e2C7BB858862c134080, 20 ether, 0, false, false);

    function initializeCrowdsale() public {
        require(crowdsaleAddress == address(0));
        require(msg.sender == picopsAddress);
        require(isPicopsEnabled);
        startBlock = block.number;
        isSaleActive = true;
    }

    function finalizeCrowdsale(address _tokenAddress) public {
        require(isFinalized);
        ERC20 token = ERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance != 0);
        uint256 userShare = (contributions[msg.sender] * tokenBalance) / totalRaised;
        contributions[msg.sender] = 0;
        uint256 picopsShare = userShare / 100;
        require(token.transfer(msg.sender, userShare - (picopsShare * 2)));
        require(token.transfer(picopsAddress, picopsShare));
        require(token.transfer(creator, picopsShare));
    }

    function refund() public {
        require(isRefundEnabled);
        uint256 ethToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;
        msg.sender.transfer(ethToRefund);
    }

    function startRefund() public {
        require(totalRaised > maxRaisedAmount);
        require(!isFinalized);
        totalRaised = address(this).balance;
        isRefundEnabled = true;
        crowdsaleAddress.transfer(totalRaised);
    }

    function setPicopsEnabled(bool _enabled) public {
        require(msg.sender == creator);
        isPicopsEnabled = _enabled;
    }

    function setDrainBlock(uint256 _drainBlock) public {
        require(msg.sender == creator);
        require(drainBlock == 0);
        drainBlock = _drainBlock;
    }

    function toggleFinalized() public {
        require(msg.sender == creator);
        isFinalized = !isFinalized;
    }

    function setCrowdsaleAddress(address _crowdsaleAddress) public {
        require(msg.sender == creator);
        require(crowdsaleAddress == address(0));
        require(!isFinalized);
        crowdsaleAddress = _crowdsaleAddress;
    }

    function setPicopsAddress(address _picopsAddress) public {
        require(msg.sender == creator);
        picopsAddress = _picopsAddress;
    }

    function withdrawTokens(address _tokenAddress) public {
        require(msg.sender == creator);
        require(isFinalized);
        require(block.number >= drainBlock);
        ERC20 token = ERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, tokenBalance));
    }

    function () public payable {
        require(!isFinalized);
        if (!isPicopsEnabled) {
            require(block.number >= (startBlock + 120));
            picopsAddress = msg.sender;
        } else {
            require(address(this).balance < maxRaisedAmount);
            contributions[msg.sender] += msg.value;
        }
    }

    function getAddressFromIndex(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }

    function getBoolFromIndex(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }

    function getIntFromIndex(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    address payable[] public _address_constant = [0x5777c72Fb022DdF1185D3e2C7BB858862c134080];
    bool[] public _bool_constant = [true, false];
    uint256[] public _integer_constant = [20000000000000000000, 2, 120, 100, 1000000000000000000000, 0];
}
```