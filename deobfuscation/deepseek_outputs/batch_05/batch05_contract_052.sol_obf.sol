```solidity
pragma solidity >=0.4.22 <0.6.0;

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

contract PrimeBet {
    using SafeMath for uint256;
    
    mapping(uint256 => uint256) public bets;
    
    function placeBet(uint256 number) public payable {
        bets[number] = bets[number].add(msg.value);
    }
    
    event NotPrime(uint256 number);
    
    function claimPrize(uint256 a, uint256 b) public {
        require(a > 1);
        require(b > 1);
        
        uint256 product = a.mul(b);
        uint256 prize = bets[product];
        
        bets[product] = 0;
        msg.sender.transfer(prize);
        
        emit NotPrime(product);
    }
    
    function getBetAmount(uint256 number) public view returns(uint256 amount) {
        return bets[number];
    }
}

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

uint256[] public _integer_constant = [1, 0];
```