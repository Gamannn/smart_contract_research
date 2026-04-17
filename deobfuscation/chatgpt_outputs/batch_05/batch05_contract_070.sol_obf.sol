pragma solidity ^0.4.21;

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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract TokenContract is Ownable {
    function TokenContract() public {
        owner = msg.sender;
    }

    function withdrawBalance() public onlyOwner {
        msg.sender.transfer(this.balance);
    }

    function transferTokens(address tokenAddress, uint256 amount) public onlyOwner {
        ERC20Interface(tokenAddress).transfer(msg.sender, amount);
    }

    function () public payable {}

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [0];
}