```solidity
pragma solidity 0.4.24;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

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
        uint256 c = a / b;
        return c;
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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }
    
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract DeconetToken is StandardToken, Ownable, Pausable {
    string public constant symbol = "DCO";
    string public constant name = "Deconet Token";
    uint8 public constant decimals = 18;
    uint public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
    
    modifier whenNotPausedOrOwner() {
        require(msg.sender == owner || !paused);
        _;
    }
    
    function transfer(address to, uint256 value) public whenNotPausedOrOwner returns (bool) {
        return super.transfer(to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) public whenNotPausedOrOwner returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
    function approve(address spender, uint256 value) public whenNotPausedOrOwner returns (bool) {
        return super.approve(spender, value);
    }
    
    function increaseApproval(address spender, uint addedValue) public whenNotPausedOrOwner returns (bool success) {
        return super.increaseApproval(spender, addedValue);
    }
    
    function decreaseApproval(address spender, uint subtractedValue) public whenNotPausedOrOwner returns (bool success) {
        return super.decreaseApproval(spender, subtractedValue);
    }
}

contract Registry is Ownable {
    address public apiRegistryContractAddress;
    address public moduleRegistryContractAddress;
    address public licenseSalesContractAddress;
    address public tokenContractAddress;
    uint public version;
    
    function setApiRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        apiRegistryContractAddress = newAddress;
    }
    
    function setModuleRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        moduleRegistryContractAddress = newAddress;
    }
}

contract ModuleRegistry is Ownable {
    struct ModuleForSale {
        uint price;
        bytes32 name;
        bytes32 moduleId;
        address seller;
        bytes4 licenseSalesContractFunction;
    }
    
    mapping(string => uint) internal moduleNameToIndex;
    mapping(uint => ModuleForSale) public modulesForSale;
    uint public moduleCount;
    uint public version;
    
    constructor() public {
        moduleCount = 0;
        version = 1;
    }
    
    function registerModule(
        string memory moduleName,
        uint price,
        bytes32 name,
        bytes32 moduleId,
        bytes4 licenseSalesContractFunction
    ) public {
        require(moduleNameToIndex[moduleName] == 0);
        moduleCount += 1;
        moduleNameToIndex[moduleName] = moduleCount;
        
        ModuleForSale storage module = modulesForSale[moduleCount];
        module.price = price;
        module.name = name;
        module.moduleId = moduleId;
        module.seller = msg.sender;
        module.licenseSalesContractFunction = licenseSalesContractFunction;
    }
    
    function getModuleIndex(string memory moduleName) public view returns (uint) {
        return moduleNameToIndex[moduleName];
    }
    
    function getModuleForSale(
        uint moduleIndex
    ) public view returns (
        uint price,
        bytes32 name,
        bytes32 moduleId,
        address seller,
        bytes4 licenseSalesContractFunction
    ) {
        ModuleForSale storage module = modulesForSale[moduleIndex];
        if (module.seller == address(0)) {
            return;
        }
        price = module.price;
        name = module.name;
        moduleId = module.moduleId;
        seller = module.seller;
        licenseSalesContractFunction = module.licenseSalesContractFunction;
    }
    
    function getModuleForSaleByName(
        string memory moduleName
    ) public view returns (
        uint price,
        bytes32 name,
        bytes32 moduleId,
        address seller,
        bytes4 licenseSalesContractFunction
    ) {
        uint moduleIndex = moduleNameToIndex[moduleName];
        if (moduleIndex == 0) {
            return;
        }
        ModuleForSale storage module = modulesForSale[moduleIndex];
        price = module.price;
        name = module.name;
        moduleId = module.moduleId;
        seller = module.seller;
        licenseSalesContractFunction = module.licenseSalesContractFunction;
    }
    
    function updateModuleForSale(
        uint moduleIndex,
        uint price,
        address seller,
        bytes4 licenseSalesContractFunction
    ) public {
        require(moduleIndex != 0 && price != 0 && seller != address(0) && licenseSalesContractFunction != 0);
        
        ModuleForSale storage module = modulesForSale[moduleIndex];
        require(
            module.price != 0 &&
            module.name != "" &&
            module.moduleId != "" &&
            module.licenseSalesContractFunction != 0 &&
            module.seller != address(0)
        );
        
        require(msg.sender == module.seller || msg.sender == owner);
        
        module.price = price;
        module.seller = seller;
        module.licenseSalesContractFunction = licenseSalesContractFunction;
    }
}

contract LicenseSales is Ownable {
    using SafeMath for uint;
    
    uint public tokenReward;
    uint public saleFee;
    address public registryContractAddress;
    address public tokenContractAddress;
    uint public version;
    address private tokenRewardAddress;
    
    event LicenseSale(
        bytes32 indexed moduleId,
        bytes32 name,
        address indexed seller,
        address indexed buyer,
        uint price,
        uint timestamp,
        uint tokenReward,
        uint fee,
        bytes4 licenseSalesContractFunction
    );
    
    function withdrawTokens() public {
        require(msg.sender == tokenRewardAddress);
        DeconetToken(tokenContractAddress).transfer(this.balanceOf(this));
    }
    
    function setTokenRewardAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        tokenRewardAddress = newAddress;
    }
    
    function setRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        registryContractAddress = newAddress;
    }
    
    function setTokenContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        tokenContractAddress = newAddress;
    }
    
    function setTokenReward(uint newTokenReward) public onlyOwner {
        tokenReward = newTokenReward;
    }
    
    function setSaleFee(uint newSaleFee) public onlyOwner {
        saleFee = newSaleFee;
    }
    
    function buyLicense(uint moduleIndex) public payable {
        require(moduleIndex != 0);
        
        Registry registry = Registry(registryContractAddress);
        address moduleRegistryAddress = registry.moduleRegistryContractAddress();
        ModuleRegistry moduleRegistry = ModuleRegistry(moduleRegistryAddress);
        
        uint price;
        bytes32 name;
        bytes32 moduleId;
        address seller;
        bytes4 licenseSalesContractFunction;
        
        (price, name, moduleId, seller, licenseSalesContractFunction) = moduleRegistry.getModuleForSale(moduleIndex);
        
        require(msg.value >= price);
        require(name != "" && moduleId != "" && seller != address(0) && licenseSalesContractFunction != 0);
        
        uint fee = msg.value.mul(saleFee).div(100);
        uint sellerProceeds = msg.value.sub(fee);
        
        emit LicenseSale(
            moduleId,
            name,
            seller,
            msg.sender,
            price,
            block.timestamp,
            tokenReward,
            fee,
            licenseSalesContractFunction
        );
        
        rewardSeller(seller);
        seller.transfer(sellerProceeds);
    }
    
    function rewardSeller(address seller) private {
        DeconetToken token = DeconetToken(tokenContractAddress);
        address tokenOwner = token.owner();
        uint tokenOwnerBalance = token.balanceOf(tokenOwner);
        uint allowance = token.allowance(tokenOwner, address(this));
        
        if (tokenOwnerBalance >= tokenReward && allowance >= tokenReward) {
            token.transferFrom(tokenOwner, seller, tokenReward);
        }
    }
}
```