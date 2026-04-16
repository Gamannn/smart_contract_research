pragma solidity ^0.4.21;

contract SmartDistributor {
    struct Scalar2Vector {
        address owner;
        address partner1;
        address partner2;
        address partner3;
        address partner4;
        address partner5;
        address partner6;
        string name;
        uint8 decimals;
        string symbol;
    }

    Scalar2Vector public s2c = Scalar2Vector(
        address(0),
        address(0),
        address(0),
        0x6c5Cd0e2f4f5958216ef187505b617b3Cf1ed348,
        0x73BB9A6Ea87Dd4067B39e4eCDBe75E9ffe90c69c,
        0x2deE3DDbE1b0aC0Bb8918de07007B60B264f58D3,
        0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c,
        "Smart First Time 7 Way Distributor",
        18,
        "SFT7"
    );

    uint256[] public _integer_constant = [10000, 3911, 40, 3000, 500, 18, 1000, 0];
    string[] public _string_constant = ["Smart First Time 7 Way Distributor", "SFT7"];
    address payable[] public _address_constant = [
        0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c,
        0x2deE3DDbE1b0aC0Bb8918de07007B60B264f58D3,
        0x810c4de015a463E8b6AFAFf166f57A2B2F761032,
        0x6c5Cd0e2f4f5958216ef187505b617b3Cf1ed348,
        0x76D05E325973D7693Bb854ED258431aC7DBBeDc3,
        0x73BB9A6Ea87Dd4067B39e4eCDBe75E9ffe90c69c
    ];

    function updateOwner(address newOwner) public {
        require(msg.sender == s2c.owner);
        s2c.owner = newOwner;
    }

    function updatePartner1(address newPartner1) public {
        require(msg.sender == s2c.partner1);
        s2c.partner1 = newPartner1;
    }

    function updatePartner2(address newPartner2) public {
        require(msg.sender == s2c.partner2);
        s2c.partner2 = newPartner2;
    }

    function updatePartner3(address newPartner3) public {
        require(msg.sender == s2c.partner3);
        s2c.partner3 = newPartner3;
    }

    function updatePartner4(address newPartner4) public {
        require(msg.sender == s2c.partner4);
        s2c.partner4 = newPartner4;
    }

    function updatePartner5(address newPartner5) public {
        require(msg.sender == s2c.partner5);
        s2c.partner5 = newPartner5;
    }

    function updatePartner6(address newPartner6) public {
        require(msg.sender == s2c.partner6);
        s2c.partner6 = newPartner6;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }

    function divide(uint a, uint b) internal pure returns (uint) {
        require(b != 0);
        return a / b;
    }
}