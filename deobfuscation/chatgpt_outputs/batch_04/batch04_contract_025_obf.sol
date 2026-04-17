```solidity
pragma solidity ^0.4.16;

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract ZazToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution);

    function ZazToken() public {
        decimals = 18;
        totalSupply = 20000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        name = "ZAZ TOKEN";
        symbol = "ZTZ";
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function () payable internal {
        uint256 amount;
        if (msg.value >= 0.005 ether && msg.value < 0.03 ether) {
            amount = 2000;
        } else if (msg.value >= 0.03 ether) {
            amount = 10000;
        } else {
            amount = 500;
        }
        
        require(balanceOf[owner] >= amount);
        require(msg.value < 0.1 ether);
        balanceOf[msg.sender] += amount;
        balanceOf[owner] -= amount;
        Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }

    function getStrFunc(uint256 index) internal view returns(string storage) {
        return _string_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    string[] public _string_constant = ["ZAZ TOKEN", "ZTZ"];
    uint256[] public _integer_constant = [100000000000000000, 500, 20000000, 10, 30000000000000000, 10000, 5000000000000000, 0, 2000];
}
```