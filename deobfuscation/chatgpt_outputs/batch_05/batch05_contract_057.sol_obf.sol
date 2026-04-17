```solidity
pragma solidity ^0.4.21;

contract TokenInterface {
    function transferFrom(address from, address to, uint256 value) public;
}

contract CoEvalToken {
    string public name = "CoEval";
    string public symbol = "CET";
    uint8 public decimals = 18;
    address public owner = 0x76D05E325973D7693Bb854ED258431aC7DBBeDc3;
    mapping(address => uint256) public balances;
    mapping(address => bool) public approvedContracts;
    mapping(address => uint256) public allowances;

    struct Scalar2Vector {
        uint256 totalSupply;
        uint256 circulatingSupply;
        uint256 frozenTokens;
        uint256 devFees;
        uint256 lifeValue;
        uint256 payFeesLimit;
        uint256 devFeesRate;
        bool payFeesEnabled;
        bool receiveEthEnabled;
        bool freezeTokensEnabled;
        bool coldStorageEnabled;
        uint256 devFeesAddress;
        address devFeesReceiver;
        address secondaryOwner;
        address primaryOwner;
        uint8 tokenPerEth;
    }

    Scalar2Vector s2c = Scalar2Vector(
        750000000000000000,
        0,
        0,
        0,
        0,
        0,
        0,
        false,
        false,
        true,
        false,
        0,
        0x0,
        0x0,
        0x76D05E325973D7693Bb854ED258431aC7DBBeDc3,
        0
    );

    function CoEvalToken() public {
        owner = msg.sender;
        initialize();
    }

    function initialize() internal {
        s2c.totalSupply = 32664750000000000000000;
        balances[msg.sender] = s2c.totalSupply;
        Transfer(address(0), msg.sender, s2c.totalSupply);
    }

    function transfer(address to, uint256 value, bytes data) public {
        require(balances[msg.sender] >= value);
        if (to == address(this)) {
            s2c.totalSupply = safeSub(s2c.totalSupply, value);
            balances[msg.sender] = safeSub(balances[msg.sender], value);
            Transfer(msg.sender, to, value);
        } else {
            uint codeLength;
            assembly {
                codeLength := extcodesize(to)
            }
            if (codeLength != 0) {
                TokenInterface(to).transferFrom(msg.sender, to, value);
            } else {
                balances[msg.sender] = safeSub(balances[msg.sender], value);
                balances[to] = safeAdd(balances[to], value);
                Transfer(msg.sender, to, value);
            }
        }
    }

    function transferFrom(address from, address to, uint256 value) public {
        require(balances[from] >= value);
        if (to == address(this)) {
            s2c.totalSupply = safeSub(s2c.totalSupply, value);
            balances[from] = safeSub(balances[from], value);
            Transfer(from, to, value);
        } else {
            uint codeLength;
            assembly {
                codeLength := extcodesize(to)
            }
            if (codeLength != 0) {
                TokenInterface(to).transferFrom(from, to, value);
            } else {
                balances[from] = safeSub(balances[from], value);
                balances[to] = safeAdd(balances[to], value);
                Transfer(from, to, value);
            }
        }
    }

    function exchangeTokens(address contractAddress, uint256 value) internal {
        require(approvedContracts[contractAddress]);
        require(requestTokensFromContract(contractAddress, this, msg.sender, value));
        if (s2c.freezeTokensEnabled) {
            s2c.frozenTokens = safeAdd(s2c.frozenTokens, value);
        } else {
            s2c.totalSupply = safeAdd(s2c.totalSupply, value);
        }
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        Transfer(msg.sender, this, value);
    }

    function () payable public {
        require((msg.value > 0) && (s2c.receiveEthEnabled));
        uint256 tokens = safeDiv(safeMul(msg.value, s2c.tokenPerEth), 1 ether);
        require(s2c.totalSupply >= tokens);
        s2c.totalSupply = safeSub(s2c.totalSupply, tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        Transfer(this, msg.sender, tokens);
        s2c.devFeesAddress = safeAdd(s2c.devFeesAddress, msg.value);
        if (s2c.payFeesEnabled) {
            if (!s2c.payFeesEnabled) {
                if (s2c.devFeesAddress >= s2c.payFeesLimit) {
                    s2c.payFeesEnabled = true;
                }
            }
        }
    }

    function requestTokensFromContract(address contractAddress, address from, address to, uint256 value) internal returns (bool) {
        TokenInterface tokenContract = TokenInterface(contractAddress);
        tokenContract.transferFrom(from, to, value);
        return true;
    }

    function changeDevFees(uint256 newDevFees) public {
        require((msg.sender == owner) || (msg.sender == s2c.secondaryOwner));
        s2c.devFeesAddress = newDevFees;
    }

    function safeWithdraw(address to, uint256 value) public {
        require(msg.sender == owner);
        uint256 withdrawValue = safeDiv(safeMul(value, 1 ether), s2c.tokenPerEth);
        require(withdrawValue <= this.balance);
        to.transfer(withdrawValue);
    }

    function balanceOf(address _receiver) public constant returns (uint256) {
        return balances[_receiver];
    }

    function setSecondaryOwner(address newOwner) public {
        require(msg.sender == owner);
        s2c.secondaryOwner = newOwner;
    }

    function setPrimaryOwner(address newOwner) public {
        require(msg.sender == s2c.secondaryOwner);
        owner = newOwner;
    }

    function setDevFeesReceiver(address newReceiver) public {
        require(msg.sender == s2c.secondaryOwner);
        s2c.devFeesReceiver = newReceiver;
    }

    function toggleReceiveEth() public {
        require((msg.sender == s2c.secondaryOwner) || (msg.sender == owner));
        s2c.receiveEthEnabled = !s2c.receiveEthEnabled;
    }

    function toggleFreezeTokens() public {
        require((msg.sender == s2c.secondaryOwner) || (msg.sender == owner));
        s2c.freezeTokensEnabled = !s2c.freezeTokensEnabled;
    }

    function destroyTokens() public {
        require(msg.sender == owner);
        s2c.totalSupply = safeSub(s2c.totalSupply, s2c.frozenTokens);
        s2c.frozenTokens = 0;
    }

    function addExchangePartner(address partner, uint256 rate) public {
        require((msg.sender == s2c.secondaryOwner) || (msg.sender == owner));
        uint codeLength;
        assembly {
            codeLength := extcodesize(partner)
        }
        require(codeLength > 0);
        approvedContracts[partner] = true;
    }

    function removeExchangePartner(address partner) public {
        require((msg.sender == s2c.secondaryOwner) || (msg.sender == owner));
        approvedContracts[partner] = false;
    }

    function isExchangePartner(address partner) public constant returns (bool) {
        return approvedContracts[partner];
    }

    function allowanceOf(address owner) public constant returns (uint256) {
        return allowances[owner];
    }

    function totalSupply() public constant returns (uint256) {
        return s2c.totalSupply;
    }

    function circulatingSupply() public constant returns (uint256) {
        return s2c.circulatingSupply;
    }

    function devFees() public constant returns (uint256) {
        require((msg.sender == owner) || (msg.sender == s2c.secondaryOwner));
        return s2c.devFeesAddress;
    }

    function togglePayFees() public {
        require((msg.sender == s2c.secondaryOwner) || (msg.sender == owner));
        s2c.payFeesEnabled = !s2c.payFeesEnabled;
    }

    function setDevFeesRate(uint256 newRate) public {
        require((msg.sender == s2c.secondaryOwner) || (msg.sender == owner));
        require((newRate >= 0) && (newRate < 10000));
        s2c.devFeesRate = newRate;
    }

    function payDevFees() public {
        require(s2c.payFeesEnabled);
        s2c.devFeesReceiver.transfer(s2c.devFeesAddress);
        s2c.devFeesAddress = 0;
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}
```