```solidity
pragma solidity ^0.4.24;

contract TokenExchange {
    function exchangeTokens(address from, address to, uint256 amount) public;
}

contract CoEvalToken {
    string public name = "CoEval";
    string public symbol = "COE";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public circulatingSupply;
    uint256 public rate;
    address public owner;
    address public devAddress;
    bool public feesEnabled;
    bool public frozenTokens;
    bool public receiveEth;
    mapping(address => uint256) public balances;
    mapping(address => bool) public exchangePartners;
    mapping(address => uint256) public exchangeRates;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Exchanged(address indexed from, address indexed to, uint256 value);

    constructor() public {
        owner = msg.sender;
        devAddress = 0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c;
        totalSupply = 32664750000000000000000;
        circulatingSupply = 0;
        rate = 17700000000000;
        feesEnabled = true;
        frozenTokens = false;
        receiveEth = true;
        balances[owner] = totalSupply;
    }

    function transfer(address to, uint256 value) public {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
    }

    function exchange(address to, uint256 value) public {
        require(balances[msg.sender] >= value);
        if (to == address(this)) {
            circulatingSupply -= value;
            balances[msg.sender] -= value;
            emit Transfer(msg.sender, to, value);
        } else {
            uint256 codeLength;
            assembly {
                codeLength := extcodesize(to)
            }
            if (codeLength != 0) {
                TokenExchange(to).exchangeTokens(msg.sender, to, value);
            } else {
                balances[msg.sender] -= value;
                balances[to] += value;
                emit Transfer(msg.sender, to, value);
            }
        }
    }

    function setRate(uint256 newRate) public {
        require(msg.sender == owner || msg.sender == devAddress);
        rate = newRate;
    }

    function enableFees(bool enable) public {
        require(msg.sender == owner || msg.sender == devAddress);
        feesEnabled = enable;
    }

    function toggleReceiveEth() public {
        require(msg.sender == owner || msg.sender == devAddress);
        receiveEth = !receiveEth;
    }

    function toggleFrozenTokens() public {
        require(msg.sender == owner || msg.sender == devAddress);
        frozenTokens = !frozenTokens;
    }

    function setExchangePartner(address partner, uint256 rate) public {
        require(msg.sender == owner || msg.sender == devAddress);
        exchangeRates[partner] = rate;
    }

    function addExchangePartner(address partner) public {
        require(msg.sender == owner || msg.sender == devAddress);
        exchangePartners[partner] = true;
    }

    function removeExchangePartner(address partner) public {
        require(msg.sender == owner || msg.sender == devAddress);
        exchangePartners[partner] = false;
    }

    function isExchangePartner(address partner) public view returns (bool) {
        return exchangePartners[partner];
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return circulatingSupply;
    }
}
```