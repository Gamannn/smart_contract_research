pragma solidity ^0.4.16;

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ZAZToken {
    string public name = "ZAZ TOKEN";
    string public symbol = "ZTZ";
    uint8 public decimals = 8;
    uint256 public totalSupply = 20000000 * 10 ** uint256(decimals);
    address public creator;
    uint256 public amountRaised;
    uint256 public price;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution);

    function ZAZToken() public {
        creator = msg.sender;
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
        price = 0.0000000001 ether;
        uint256 amount;
        if (msg.value >= price && msg.value < 0.005 ether) {
            amount = 500;
            amountRaised += msg.value;
            require(balanceOf[creator] >= amount);
            require(msg.value < 0.1 ether);
            balanceOf[msg.sender] += amount;
            balanceOf[creator] -= amount;
            Transfer(creator, msg.sender, amount);
            creator.transfer(amountRaised);
        }
        if (msg.value >= 0.005 ether && msg.value < 0.03 ether) {
            amount = 2000;
            amountRaised += msg.value;
            require(balanceOf[creator] >= amount);
            require(msg.value < 0.1 ether);
            balanceOf[msg.sender] += amount;
            balanceOf[creator] -= amount;
            Transfer(creator, msg.sender, amount);
            creator.transfer(amountRaised);
        }
        if (msg.value >= 0.03 ether) {
            amount = 10000;
            amountRaised += msg.value;
            require(balanceOf[creator] >= amount);
            require(msg.value < 0.1 ether);
            balanceOf[msg.sender] += amount;
            balanceOf[creator] -= amount;
            Transfer(creator, msg.sender, amount);
            creator.transfer(amountRaised);
        }
    }
}