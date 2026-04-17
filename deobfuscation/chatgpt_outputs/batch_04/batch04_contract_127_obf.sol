pragma solidity ^0.4.13;

contract Token {
    function balanceOf(address account) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
}

contract HodlParty {
    event Hodl(address indexed user, uint indexed amount);
    event Party(address indexed user, uint indexed amount);

    mapping (address => uint) public balances;
    uint public partyTime;

    struct Scalar2Vector {
        uint256 partyTime;
    }
    Scalar2Vector s2c = Scalar2Vector(1522093545);

    uint256[] public _integer_constant = [1522093545, 120, 100, 0];
    address payable[] public _address_constant = [0x239C09c910ea910994B320ebdC6bB159E71d0b30];

    function() payable {
        balances[msg.sender] += msg.value;
        Hodl(msg.sender, msg.value);
    }

    function releaseFunds() {
        require(block.timestamp > s2c.partyTime && balances[msg.sender] > 0);
        uint value = balances[msg.sender];
        uint fee = value / 100;
        balances[msg.sender] = 0;
        msg.sender.transfer(value - fee);
        Party(msg.sender, value - fee);
        s2c.partyTime += 120;
    }

    function withdrawForeignTokens(address tokenAddress) returns (bool) {
        if (msg.sender != 0x239C09c910ea910994B320ebdC6bB159E71d0b30) return false;
        require(block.timestamp > s2c.partyTime);
        Token token = Token(tokenAddress);
        uint256 fee = token.balanceOf(address(this)) / 100;
        return token.transfer(getAddrFunc(0), fee);
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }
}