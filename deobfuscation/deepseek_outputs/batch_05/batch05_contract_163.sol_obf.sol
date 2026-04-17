pragma solidity ^0.4.19;

contract Oxbeb03d43420364ee5400c282873e6c60f5c8b7b3 {
    address public owner;
    uint256 public pinCode;
    uint256 public constant MAX_NUMBER = 9999;
    uint256 public constant MIN_BET = 0.1 ether;
    
    struct GameData {
        uint256 pinCode;
        address owner;
    }
    
    GameData public gameData;
    
    function Oxbeb03d43420364ee5400c282873e6c60f5c8b7b3() public payable {
        owner = msg.sender;
        pinCode = 2658;
        gameData = GameData(pinCode, owner);
    }
    
    function fallback() public payable {}
    
    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }
    
    function play(uint256 guess) public payable {
        if(msg.value >= this.balance && msg.value > MIN_BET) {
            if(guess <= MAX_NUMBER && guess == pinCode) {
                msg.sender.transfer(this.balance + msg.value);
            }
        }
    }
    
    function getConstant(uint256 index) internal view returns(uint256) {
        uint256[] memory constants = new uint256[](3);
        constants[0] = MAX_NUMBER;
        constants[1] = pinCode;
        constants[2] = 100000000000000000;
        return constants[index];
    }
    
    uint256[] public _integer_constant = [9999, 2658, 100000000000000000];
}