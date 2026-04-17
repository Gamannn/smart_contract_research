pragma solidity ^0.4.21;

contract TokenInterface {
    function balanceOf(address account) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract HodlParty {
    event Hodl(address indexed user, uint indexed amount);
    event Party(address indexed user, uint indexed amount);

    mapping (address => uint) public balances;
    uint public partyTime = 1522095322;

    struct Scalar2Vector {
        uint256 lastPartyTime;
    }
    Scalar2Vector s2c = Scalar2Vector(1522095322);

    address payable[] public _address_constant = [0x239C09c910ea910994B320ebdC6bB159E71d0b30];
    uint256[] public _integer_constant = [0, 100, 120, 1522095322];

    function() public payable {
        balances[msg.sender] += msg.value;
        emit Hodl(msg.sender, msg.value);
    }

    function releaseFunds() public {
        require(block.timestamp > partyTime && balances[msg.sender] > 0);
        uint value = balances[msg.sender];
        uint fee = value / 100;
        msg.sender.transfer(value - fee);
        emit Party(msg.sender, value);
        s2c.lastPartyTime = s2c.lastPartyTime + 120;
    }

    function withdrawForeignTokens(address tokenAddress) public returns (bool) {
        require(msg.sender == _address_constant[0]);
        require(block.timestamp > s2c.lastPartyTime);

        TokenInterface token = TokenInterface(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this)) / 100;
        return token.transfer(_address_constant[0], tokenBalance);
    }

    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
}