pragma solidity ^0.4.21;

contract SmartFirstTime7WayDistributor {
    address public owner;
    address public admin;
    address public manager;
    address public partner1;
    address public partner2;
    address public partner3;
    address public distributor;
    
    string public name = "Smart First Time 7 Way Distributor";
    string public symbol = "SFT7";
    uint8 public decimals = 18;
    
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
    
    constructor() public {
        owner = msg.sender;
        distributor = _address_constant[0];
    }
    
    function setOwner(address _newOwner) public {
        require(msg.sender == owner);
        owner = _newOwner;
    }
    
    function setAdmin(address _newAdmin) public {
        require(msg.sender == admin);
        admin = _newAdmin;
    }
    
    function setManager(address _newManager) public {
        require(msg.sender == manager);
        manager = _newManager;
    }
    
    function setPartner1(address _newPartner1) public {
        require(msg.sender == partner1);
        partner1 = _newPartner1;
    }
    
    function setPartner2(address _newPartner2) public {
        require(msg.sender == partner2);
        partner2 = _newPartner2;
    }
    
    function setPartner3(address _newPartner3) public {
        require(msg.sender == partner3);
        partner3 = _newPartner3;
    }
    
    function setDistributor(address _newDistributor) public {
        require(msg.sender == distributor);
        distributor = _newDistributor;
    }
    
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    function getStrFunc(uint256 index) internal view returns(string storage) {
        return _string_constant[index];
    }
    
    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }
}