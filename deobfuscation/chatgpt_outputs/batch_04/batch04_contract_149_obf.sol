pragma solidity ^0.4.21;

contract SimpleContract {
    address public owner = 0x7Ec915B8d3FFee3deaAe5Aa90DeF8Ad826d2e110;
    string public banner = "";

    event Quote(address indexed sender, string message, uint256 value);

    function withdraw() public {
        if (msg.sender != owner) {
            emit Quote(msg.sender, "OMG CHEATER ATTEMPTING TO WITHDRAW", 0);
            return;
        }
        msg.sender.transfer(address(this).balance);
    }

    function emitMessage(string message) public {
        require(msg.sender == owner);
        emit Quote(msg.sender, message, 0);
    }

    function setBanner(string newBanner) public {
        require(msg.sender == owner);
        banner = newBanner;
    }

    function() public payable {
        require(msg.sender != owner);
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    uint256[] public _integer_constant = [0];
    address payable[] public _address_constant = [0x7Ec915B8d3FFee3deaAe5Aa90DeF8Ad826d2e110];
    string[] public _string_constant = ["", "OMG CHEATER ATTEMPTING TO WITHDRAW"];
}