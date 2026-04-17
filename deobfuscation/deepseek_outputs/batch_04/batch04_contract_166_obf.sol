pragma solidity >=0.4.21 <0.7.0;

contract Oxc262ffda31be0505a965da732b7563ab35dd3435 {
    address payable public owner;
    
    event EventSeeAmount(uint256 amount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function() external payable {
        uint256 amount;
        uint256 fee = 3;
        uint256 base = 30;
        amount = fee + base;
        emit EventSeeAmount(amount);
    }
    
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}