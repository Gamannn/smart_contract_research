pragma solidity ^0.5.10;

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MainContract {
    using SafeMath for uint256;
    
    IERC20 public token = IERC20(0x063b98a414EAA1D4a5D4fC235a22db1427199024);
    
    struct Config {
        uint256 feePercent;
        address payable feeReceiver;
    }
    
    Config public config = Config(16, 0x17654d41806F446262cab9D0C586a79EBE7e457a);
    
    modifier onlyOwner() {
        assert(msg.sender == config.feeReceiver);
        _;
    }
    
    function setFeeReceiver(address payable newReceiver) public onlyOwner {
        config.feeReceiver = newReceiver;
    }
    
    function withdrawToken(uint256 amount) public onlyOwner {
        config.feeReceiver.transfer(amount);
    }
    
    function transferToken(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20(tokenAddress).transfer(config.feeReceiver, amount);
    }
    
    function setFeePercent(uint256 newFeePercent) public onlyOwner {
        config.feePercent = newFeePercent;
    }
    
    function getBalances() view public returns (uint256 ethBalance, uint256 tokenBalance) {
        ethBalance = address(this).balance;
        tokenBalance = token.balanceOf(address(this));
    }
    
    function() payable external {
        assert(msg.sender == tx.origin);
        if (msg.sender == config.feeReceiver) return;
        
        uint256 feeAmount = msg.value.mul(config.feePercent);
        assert(feeAmount <= token.balanceOf(address(this)));
        
        token.transfer(msg.sender, feeAmount);
    }
}