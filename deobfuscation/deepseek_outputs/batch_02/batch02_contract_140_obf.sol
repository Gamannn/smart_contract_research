pragma solidity ^0.4.18;

contract Ox3cd2c94fb9bf35e0eb24ecd52379297199b75eff {
    address public owner;
    address public winner;
    uint256 public deadline;
    uint256 public reward;
    uint256 public tip;
    uint256 public buttonClicks;

    function Ox3cd2c94fb9bf35e0eb24ecd52379297199b75eff() public payable {
        owner = msg.sender;
        deadline = now;
        winner = msg.sender;
        reward += msg.value;
    }

    function Oxc4fdcb4f0537047ff514696c803d1e3e1bdb4eb3() public payable {
        require(msg.value >= 0.001 ether);
        
        if (now > deadline) {
            deadline = now;
        }
        
        reward += msg.value * 8 / 10;
        tip += msg.value * 2 / 10;
        winner = msg.sender;
        deadline = now + 30 minutes;
        buttonClicks += 1;
    }

    function Ox9eb81d2d7811f83fbd83a79f7b264d1fecd5adfe() public {
        require(msg.sender == winner);
        require(now > deadline);
        
        uint256 payout = reward;
        reward = 0;
        winner.transfer(payout);
    }

    function withdrawTip() public {
        uint256 tipAmount = tip;
        tip = 0;
        owner.transfer(tipAmount);
    }

    function getIntegerConstant(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    uint256[] public _integer_constant = [10, 10800, 1, 0, 8, 2, 1800, 1000000000000000];
}