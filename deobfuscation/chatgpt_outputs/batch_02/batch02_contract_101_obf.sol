pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract HeartContract {
    using SafeMath for uint256;

    address public contractOwner;
    address public lastSender;
    mapping(uint256 => uint256) public heartsByDapp;

    uint256[] public integerConstants = [1900000000000000, 0, 2];

    constructor() public {
        contractOwner = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == contractOwner);
        contractOwner.transfer(address(this).balance);
    }

    function sendHearts(uint256 dappId) public payable {
        require(msg.value > integerConstants[0]);
        heartsByDapp[dappId] = heartsByDapp[dappId].add(msg.value);
        lastSender.transfer(msg.value.div(integerConstants[2]));
        lastSender = msg.sender;
    }

    function getTotalHeartsByDapp(uint256 dappId) public view returns (uint256) {
        return heartsByDapp[dappId];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return integerConstants[index];
    }
}