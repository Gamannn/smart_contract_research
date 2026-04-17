```solidity
pragma solidity ^0.5.0;

interface IENSRegistry {
    function owner(bytes32 node) external view returns (address);
    function setOwner(bytes32 node, address owner) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
}

interface IResolver {
    function setAddr(bytes32 node, address addr) external;
    function setContent(bytes32 node, bytes32 hash) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Registrar {
    event LabelRegistered(string label, address indexed owner);
    event TopicRegistered(string topic, address indexed owner);
    
    IENSRegistry public ens;
    IResolver public resolver;
    bytes32 public rootNode;
    address payable public beneficiary;
    
    uint public labelFee = 500 szabo;
    uint public contentFee;
    uint public topicFee;
    
    modifier onlyOwner() {
        require(msg.sender == beneficiary, "Only owner");
        _;
    }
    
    modifier available(string memory name) {
        bytes32 node = keccak256(abi.encodePacked(rootNode, keccak256(abi.encodePacked(name))));
        address currentOwner = ens.owner(node);
        require(currentOwner == address(0) || currentOwner == msg.sender, "Name not available");
        _;
    }
    
    function namehash(string memory name) internal view returns (bytes32) {
        bytes32 labelHash = keccak256(abi.encodePacked(name));
        return keccak256(abi.encodePacked(rootNode, labelHash));
    }
    
    function registerLabel(string memory name, address owner) internal available(name) returns (bytes32) {
        bytes32 labelHash = keccak256(abi.encodePacked(name));
        ens.setSubnodeOwner(rootNode, labelHash, address(this));
        resolver.setAddr(namehash(name), owner);
        return labelHash;
    }
    
    function register(string calldata name, address owner) payable external {
        require(msg.value >= labelFee, "Insufficient fee");
        bytes32 labelHash = registerLabel(name, owner);
        ens.setSubnodeOwner(rootNode, labelHash, owner);
        emit LabelRegistered(name, owner);
    }
    
    function registerWithContent(string calldata name, bytes32 contentHash, address owner) payable external {
        require(msg.value >= contentFee, "Insufficient fee");
        bytes32 labelHash = registerLabel(name, owner);
        resolver.setContent(namehash(name), contentHash);
        ens.setSubnodeOwner(rootNode, labelHash, owner);
        emit LabelRegistered(name, owner);
    }
    
    function registerTopic(string calldata topic, address owner) payable external {
        require(msg.value >= topicFee, "Insufficient fee");
        bytes32 labelHash = registerLabel(topic, owner);
        ens.setSubnodeOwner(rootNode, labelHash, owner);
        emit TopicRegistered(topic, owner);
    }
    
    constructor(address ensAddress, address resolverAddress, bytes32 _rootNode) public {
        ens = IENSRegistry(ensAddress);
        resolver = IResolver(resolverAddress);
        rootNode = _rootNode;
        beneficiary = msg.sender;
    }
    
    function setLabelFee(uint newFee) public onlyOwner {
        labelFee = newFee;
    }
    
    function setContentFee(uint newFee) public onlyOwner {
        contentFee = newFee;
    }
    
    function setTopicFee(uint newFee) public onlyOwner {
        topicFee = newFee;
    }
    
    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }
    
    function setResolver(address newResolver) external onlyOwner {
        resolver = IResolver(newResolver);
    }
    
    function transferRootOwnership(address newOwner) external onlyOwner {
        ens.setOwner(rootNode, newOwner);
    }
    
    function withdraw() external {
        beneficiary.transfer(address(this).balance);
    }
    
    function withdrawTokens(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(beneficiary, token.balanceOf(address(this)));
    }
    
    function() payable external {}
}
```