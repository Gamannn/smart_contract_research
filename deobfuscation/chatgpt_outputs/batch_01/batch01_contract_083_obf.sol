pragma solidity ^0.5.10;

contract TokenContract {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract MainContract {
    using SafeMath for uint256;

    TokenContract public tokenContract = TokenContract(0x063b98a414EAA1D4a5D4fC235a22db1427199024);

    modifier onlyOwner() {
        require(msg.sender == ownerData.owner, "Not authorized");
        _;
    }

    function setOwner(address payable newOwner) public onlyOwner {
        ownerData.owner = newOwner;
    }

    function transferTokens(uint256 amount) public onlyOwner {
        ownerData.owner.transfer(amount);
    }

    function transferTokensTo(address tokenAddress, uint256 amount) public onlyOwner {
        TokenContract(tokenAddress).transfer(ownerData.owner, amount);
    }

    function setMultiplier(uint256 multiplier) public onlyOwner {
        ownerData.multiplier = multiplier;
    }

    function getContractData() view public returns (uint256 balance, uint256 tokenBalance) {
        balance = address(this).balance;
        tokenBalance = tokenContract.balances(address(this));
    }

    function() payable external {
        require(msg.sender == tx.origin, "No contract calls");
        if (msg.sender == ownerData.owner) return;

        uint256 tokenAmount = msg.value.mul(ownerData.multiplier);
        require(tokenAmount <= tokenContract.balances(address(this)), "Insufficient tokens");

        tokenContract.transfer(msg.sender, tokenAmount);
    }

    struct OwnerData {
        uint256 multiplier;
        address payable owner;
    }

    OwnerData public ownerData = OwnerData(16, 0x17654d41806F446262cab9D0C586a79EBE7e457a);
}