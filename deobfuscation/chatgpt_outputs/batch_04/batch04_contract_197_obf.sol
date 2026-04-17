```solidity
pragma solidity ^0.4.13;

contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function balanceOf(address owner) constant returns (uint256 balance);
}

contract Crowdsale {
    mapping (address => uint256) public ethBalances;
    mapping (address => uint256) public tokenBalances;
    bool public tokensBought;
    bool public killSwitchActivated;
    uint256 public ethCollected;
    uint256 public refundAmount;
    uint256 public refundEthValue;
    bool public killSwitch;
    bytes32 private passwordHash = 0x8bf0720c6e610aace867eba51b03ab8ca908b665898b10faddc95a96e829539d;
    address public developer;
    address public tokenAddress = 0x05ea986c4f0202d5e9fa62a9c630d4dcbeba1bbf;
    Token public tokenContract;
    uint256 public ethMinimum;

    function setTokenAddress(address _tokenAddress) {
        require(msg.sender == developer);
        tokenContract = Token(_tokenAddress);
        tokensBought = true;
    }

    function activateKillSwitch(string _password) {
        require(msg.sender == developer || sha3(_password) == passwordHash);
        killSwitchActivated = true;
    }

    function withdrawTokens(string _password, uint256 _amount) {
        require(msg.sender == developer || sha3(_password) == passwordHash);
        msg.sender.transfer(_amount);
    }

    function withdraw() {
        Token token = Token(tokenAddress);
        if (ethBalances[msg.sender] == 0) return;
        require(msg.sender != tokenAddress);
        if (!tokensBought) {
            uint256 ethToWithdraw = ethBalances[msg.sender];
            ethBalances[msg.sender] = 0;
            msg.sender.transfer(ethToWithdraw);
        } else {
            uint256 tokenBalance = token.balanceOf(address(this));
            require(tokenBalance != 0);
            uint256 tokensToWithdraw = (ethBalances[msg.sender] * tokenBalance) / ethCollected;
            ethCollected -= ethBalances[msg.sender];
            uint256 fee = tokensToWithdraw / 100;
            require(token.transfer(developer, fee));
            require(token.transfer(msg.sender, tokensToWithdraw - fee));
        }
    }

    function refund() {
        require(refundAmount != 0);
        require(tokenBalances[msg.sender] != 0);
        uint256 refundValue = (tokenBalances[msg.sender] * refundAmount) / ethMinimum;
        refundEthValue += refundValue;
        tokenBalances[msg.sender] = 0;
        msg.sender.transfer(refundValue);
    }

    function () payable {
        if (!tokensBought) {
            ethBalances[msg.sender] += msg.value;
            tokenBalances[msg.sender] += msg.value;
            if (this.balance < ethMinimum) return;
            if (killSwitchActivated) return;
            require(tokenAddress != 0x0);
            tokensBought = true;
            ethCollected = this.balance;
            refundAmount = 0;
        } else {
            require(msg.sender == tokenAddress);
            refundAmount += msg.value;
        }
    }

    function getAddress(uint256 index) internal view returns(address) {
        return _address_constant[index];
    }

    function getInteger(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    function getBoolean(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }

    address payable[] public _address_constant = [0x0e7CE7D6851F60A1eF2CAE9cAD765a5a62F32A84, 0xc4740f71323129669424d1Ae06c42AEE99da30e2];
    uint256[] public _integer_constant = [3235000000000000000000, 100, 6329];
    bool[] public _bool_constant = [true];
}
```