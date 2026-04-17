```solidity
pragma solidity ^0.4.2;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }
    
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a && c >= b);
        return c;
    }
}

contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint;
    
    mapping(address => uint) balances;
    
    function transfer(address to, uint value) public returns (bool) {
        require(value >= 0);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint)) allowed;
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        uint allowance = allowed[from][msg.sender];
        require(allowance >= value);
        require(value >= 0);
        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowance.sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        require(!((value != 0) && (allowed[msg.sender][spender] != 0)));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public constant returns (uint) {
        return allowed[owner][spender];
    }
}

contract Ownable {
    address public owner;
    mapping (address => bool) private admins;
    mapping (address => bool) private agents;
    mapping (address => bool) private whitelist;
    
    function Ownable() internal {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function getOwner() view public returns (address) {
        return owner;
    }
    
    function isAdmin() view internal returns (bool) {
        return admins[msg.sender];
    }
    
    function isAgent() view internal returns (bool) {
        return agents[msg.sender];
    }
    
    function addAdmin(address admin) onlyOwner() public {
        admins[admin] = true;
    }
    
    function removeAdmin(address admin) onlyOwner() public {
        delete admins[admin];
    }
    
    function addAgent(address agent) onlyOwner() public {
        agents[agent] = true;
    }
    
    function removeAgent(address agent) onlyOwner() public {
        delete agents[agent];
    }
    
    function addToWhitelist(address addr) onlyOwner() public {
        whitelist[addr] = true;
    }
    
    function removeFromWhitelist(address addr) onlyOwner() public {
        delete whitelist[addr];
    }
    
    function transferOwnership(address newOwner) onlyOwner() public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract CrowdsaleToken is StandardToken, Ownable {
    event AirDrop(address indexed from, address indexed to, uint amount);
    event CrowdDistribute(address indexed from, address indexed to, uint amount);
    
    using SafeMath for uint;
    
    mapping (address => bool) private airDropAgents;
    uint private maxAirDropPerAddress = 1000 * 10**18;
    uint private totalAirDropped = 0;
    uint public totalAirDropSupply = 0;
    bool public crowdSaleFinished = false;
    uint private totalCrowdCoin = 0;
    uint public totalCrowdSupply = 0;
    uint private totalDevCoin = 0;
    uint public totalDevSupply = 0;
    uint private totalFoundCoin = 0;
    
    function distributeToFound(address receiver, uint amount) onlyOwner() public returns (uint) {
        require((amount + totalFoundCoin) < totalFoundSupply);
        balances[owner] = balances[owner].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        totalFoundCoin = totalFoundCoin.add(amount);
        addToWhitelist(receiver);
        emit Transfer(owner, receiver, amount);
        return amount;
    }
    
    function distributeToDev(address receiver, uint amount) onlyOwner() public returns (uint) {
        require((amount + totalDevCoin) < totalDevSupply);
        balances[owner] = balances[owner].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        totalDevCoin = totalDevCoin.add(amount);
        addAdmin(receiver);
        emit Transfer(owner, receiver, amount);
        return amount;
    }
    
    function airDrop(address from, address receiver, uint amount) public returns (uint) {
        require(receiver != address(0));
        require(amount <= maxAirDropPerAddress);
        require((amount + totalAirDropped) < totalAirDropSupply);
        require(airDropAgents[msg.sender] == true);
        balances[from] = balances[from].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        totalAirDropped = totalAirDropped.add(amount);
        emit AirDrop(from, receiver, amount);
        return amount;
    }
    
    function buyTokens() payable public returns (uint) {
        require(msg.sender != address(0));
        require(!isContract(msg.sender));
        require(msg.value > 0);
        require(totalCrowdCoin < totalCrowdSupply);
        require(crowdSaleFinished == false);
        uint tokens = calculateTokens(msg.value);
        require(tokens != 0);
        totalCrowdCoin = totalCrowdCoin.add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        updateCrowdState();
        emit CrowdDistribute(owner, msg.sender, tokens);
        return tokens;
    }
    
    function updateCrowdState() internal {
        if (totalCrowdCoin < totalCrowdSupply.mul(10).div(100)) {
            crowdState = 0;
        } else if (totalCrowdCoin < totalCrowdSupply.mul(20).div(100)) {
            crowdState = 1;
        } else if (totalCrowdCoin < totalCrowdSupply.mul(30).div(100)) {
            crowdState = 2;
        } else if (totalCrowdCoin < totalCrowdSupply.mul(40).div(100)) {
            crowdState = 3;
        } else if (totalCrowdCoin < totalCrowdSupply.mul(50).div(100)) {
            crowdState = 4;
        }
        
        if (totalCrowdCoin >= totalCrowdSupply) {
            finishCrowdSale();
        }
    }
    
    function calculateTokens(uint weiAmount) internal view returns (uint) {
        uint price;
        if (crowdState == 0) {
            price = totalCrowdSupply.mul(50000).div(100);
        } else if (crowdState == 1) {
            price = totalCrowdSupply.mul(40000).div(100);
        } else if (crowdState == 2) {
            price = totalCrowdSupply.mul(30000).div(100);
        } else if (crowdState == 3) {
            price = totalCrowdSupply.mul(20000).div(100);
        } else if (crowdState == 4) {
            price = totalCrowdSupply.mul(15000).div(100);
        }
        return weiAmount.mul(price).div(1 ether);
    }
    
    function finishCrowdSale() internal {
        crowdSaleFinished = true;
    }
    
    uint public crowdState = 0;
    uint public totalFoundSupply = 0;
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract ReleasableToken is StandardToken, Ownable {
    address public releaseAgent;
    bool public released = false;
    uint public maxTransferForDev = 40000000 * 10**18;
    uint private maxTransferForFound = 20000000 * 10**18;
    uint private transferredForDev = 0;
    
    mapping (address => bool) public transferAgents;
    
    modifier canTransfer(address from, uint value) {
        if (!released) {
            require(transferAgents[from] || isAdmin() || isAgent());
            if (isAdmin()) {
                require(value <= maxTransferForDev);
                require(transferredForDev + value <= maxTransferForDev);
                transferredForDev = transferredForDev.add(value);
            }
        }
        _;
    }
    
    function setTransferLimits(uint devLimit, uint foundLimit, uint transferLimit) onlyOwner() public {
        require(devLimit < totalSupply);
        require(foundLimit < totalSupply);
        require(transferLimit < totalSupply);
        maxTransferForDev = devLimit;
        maxTransferForFound = foundLimit;
        maxTransferForDev = transferLimit;
    }
    
    function setReleaseAgent(address agent) onlyOwner() whenNotReleased() public {
        releaseAgent = agent;
    }
    
    function releaseTokenTransfer() public onlyReleaseAgent() {
        released = true;
    }
    
    function setTransferAgent(address addr, bool state) onlyOwner() whenNotReleased() public {
        transferAgents[addr] = state;
    }
    
    modifier whenNotReleased() {
        require(!released);
        _;
    }
    
    modifier onlyReleaseAgent() {
        require(msg.sender == releaseAgent);
        _;
    }
    
    function transfer(address to, uint value) public canTransfer(msg.sender, value) returns (bool) {
        return super.transfer(to, value);
    }
    
    function transferFrom(address from, address to, uint value) public canTransfer(from, value) returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

contract RecycleToken is StandardToken, Ownable {
    using SafeMath for uint;
    
    function recycleTokens(address from, uint amount) onlyOwner() public {
        require(from != address(0));
        require(balances[from] >= amount);
        balances[owner] = balances[owner].add(amount);
        balances[from] = balances[from].sub(amount);
        emit Transfer(from, owner, amount);
    }
}

contract MintableToken is StandardToken, Ownable {
    using SafeMath for uint;
    
    bool public mintingFinished = false;
    mapping (address => bool) public mintAgents;
    
    event MintingAgentChanged(address addr, bool state);
    
    function mint(address receiver, uint amount) onlyMintAgent() whenMintingNotFinished() public {
        balances[owner] = balances[owner].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
    }
    
    function setMintAgent(address addr, bool state) onlyOwner() whenMintingNotFinished() public {
        mintAgents[addr] = state;
        emit MintingAgentChanged(addr, state);
    }
    
    modifier onlyMintAgent() {
        require(mintAgents[msg.sender]);
        _;
    }
    
    function finishMinting() onlyOwner() public {
        mintingFinished = true;
    }
    
    modifier whenMintingNotFinished() {
        require(!mintingFinished);
        _;
    }
}

contract CrowdsaleTokenFinal is ReleasableToken, MintableToken, RecycleToken {
    event UpdatedTokenInformation(string newName, string newSymbol);
    
    string public name;
    string public symbol;
    uint public decimals;
    
    function CrowdsaleTokenFinal() public {
        owner = msg.sender;
        addToWhitelist(owner);
        name = "TotalGame Coin";
        symbol = "TTG";
        totalSupply = 2000000000 * 10**18;
        decimals = 18;
        balances[msg.sender] = totalSupply;
        mintingFinished = true;
        totalFoundSupply = totalSupply.mul(20).div(100);
        emit Transfer(address(0), owner, totalSupply);
    }
    
    function releaseTokenTransfer() public onlyReleaseAgent() {
        super.releaseTokenTransfer();
        finishMinting();
    }
    
    function setTokenInformation(string newName, string newSymbol) onlyOwner() public {
        name = newName;
        symbol = newSymbol;
        emit UpdatedTokenInformation(name, symbol);
    }
    
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }
    
    function name() public view returns (string) {
        return name;
    }
}
```