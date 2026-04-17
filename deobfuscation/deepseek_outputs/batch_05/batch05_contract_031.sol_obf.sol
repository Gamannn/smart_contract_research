```solidity
pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract SimpleWallet {
    using SafeMath for uint256;
    
    address public owner = 0xdF8AB44409132d358F10bd4a7d1221b418ff8dFF;
    address payable[] public allowedAddresses = [0xdF8AB44409132d358F10bd4a7d1221b418ff8dFF];
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function () external payable {
        owner.transfer(msg.value);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawAll() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function getAddress(uint256 index) internal view returns (address) {
        return allowedAddresses[index];
    }
}
```