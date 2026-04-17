pragma solidity ^0.5.0;

interface AddressResolver {
    function getAddress(bytes32 node) external view returns (address);
    function setAddress(bytes32 node, address addr) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
}

interface NameRegistrar {
    function register(bytes32 node, address owner) external;
    function setRecord(bytes32 node, bytes32 label, bytes32 value) external;
}

interface Token {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint256 value) external returns (bool);
}

contract DomainRegistrar {
    event LabelRegistered(string label, address indexed owner);
    event TopicRegistered(string topic, address indexed owner);

    AddressResolver public addressResolver;
    NameRegistrar public nameRegistrar;
    bytes32 public rootNode;
    address payable public beneficiary;
    uint public registrationFee = 500 szabo;

    constructor(address resolverAddress, address registrarAddress, bytes32 root) public {
        addressResolver = AddressResolver(resolverAddress);
        nameRegistrar = NameRegistrar(registrarAddress);
        rootNode = root;
        beneficiary = msg.sender;
    }

    function computeNode(string memory label) internal view returns (bytes32) {
        bytes32 labelHash = keccak256(abi.encodePacked(label));
        return keccak256(abi.encodePacked(rootNode, labelHash));
    }

    modifier onlyOwnerOrAvailable(string memory label) {
        address currentOwner = addressResolver.getAddress(computeNode(label));
        require(currentOwner == address(0) || currentOwner == msg.sender, "Not authorized");
        _;
    }

    function registerLabel(string memory label, address owner) internal onlyOwnerOrAvailable(label) returns (bytes32) {
        bytes32 labelHash = keccak256(abi.encodePacked(label));
        addressResolver.setSubnodeOwner(rootNode, labelHash, address(this));
        nameRegistrar.register(computeNode(label), owner);
        return labelHash;
    }

    function registerDomain(string calldata label, address owner) payable external {
        require(msg.value >= registrationFee, "Insufficient fee");
        bytes32 labelHash = registerLabel(label, owner);
        addressResolver.setSubnodeOwner(rootNode, labelHash, owner);
        emit LabelRegistered(label, owner);
    }

    function registerTopic(string calldata topic, bytes32 label, bytes32 value, address owner) payable external {
        require(msg.value >= registrationFee, "Insufficient fee");
        bytes32 labelHash = registerLabel(topic, owner);
        nameRegistrar.setRecord(computeNode(topic), label, value);
        addressResolver.setSubnodeOwner(rootNode, labelHash, owner);
        emit TopicRegistered(topic, owner);
    }

    function setRegistrationFee(uint newFee) public onlyOwner {
        registrationFee = newFee;
    }

    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    function withdraw() external {
        beneficiary.transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(msg.sender == beneficiary, "Not authorized");
        _;
    }

    function() payable external {}
}