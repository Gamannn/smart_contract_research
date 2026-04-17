pragma solidity ^0.4.21;

contract Ox8549ba2094ecb959c18b3f1431a3a43ac1444d8d {
    address public owner;
    string public banner;
    
    event Quote(address indexed from, string message, uint256 value);
    
    constructor() public {
        owner = msg.sender;
        banner = "";
        emit Quote(msg.sender, "Contract deployed", msg.value);
    }
    
    function donate() public payable {
        require(msg.sender != owner);
        emit Quote(msg.sender, banner, msg.value);
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
    
    function setMessage(string memory _message) public {
        require(msg.sender == owner);
        emit Quote(msg.sender, _message, 0);
    }
    
    function setBanner(string memory _banner) public {
        require(msg.sender == owner);
        banner = _banner;
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        uint256[] memory _integer_constant = new uint256[](1);
        _integer_constant[0] = 0;
        return _integer_constant[index];
    }
    
    function getAddrFunc(uint256 index) internal view returns(address payable) {
        address payable[] memory _address_constant = new address payable[](1);
        _address_constant[0] = 0x7Ec915B8d3FFee3deaAe5Aa90DeF8Ad826d2e110;
        return _address_constant[index];
    }
    
    function getStrFunc(uint256 index) internal view returns(string memory) {
        string[] memory _string_constant = new string[](2);
        _string_constant[0] = "";
        _string_constant[1] = "OMG CHEATER ATTEMPTING TO WITHDRAW";
        return _string_constant[index];
    }
}