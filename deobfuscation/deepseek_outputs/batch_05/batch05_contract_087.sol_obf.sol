```solidity
pragma solidity 0.4.21;

interface ITotlePrimary {
    function performSwap(
        address[8] tokenAddresses,
        uint256[6] amounts,
        uint256 minimumReturn,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);
    
    function performSwapWithLimit(
        address[8] tokenAddresses,
        uint256[6] amounts,
        uint256 minimumReturn,
        uint256 targetAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (uint256);
    
    function performSwapFromToken(
        address[8] tokenAddresses,
        uint256[6] amounts,
        uint256 minimumReturn,
        uint256 targetAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);
}

contract WETH {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;
    
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    function() public payable {
        deposit();
    }
    
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        Withdrawal(msg.sender, wad);
    }
    
    function totalSupply() public view returns (uint) {
        return this.balance;
    }
    
    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }
    
    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    
    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        require(balanceOf[src] >= wad);
        
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }
        
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
        Transfer(src, dst, wad);
        return true;
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITotleTransferHandler {
    function checkHash(
        bytes32 hash
    ) external view returns (bool);
    
    function submitOrder(
        address tokenFrom,
        uint amountFrom,
        address tokenTo,
        address destination,
        uint amountTo,
        address tokenForFee,
        uint256 feeAmount,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

contract TotlePrimary is ITotlePrimary, Ownable {
    ITotleTransferHandler public transferHandler;
    WETH public weth;
    address public totlePrimary;
    
    uint256 constant MAX_UINT = 2**256 - 1;
    
    modifier onlyTotlePrimary() {
        require(msg.sender == totlePrimary);
        _;
    }
    
    function TotlePrimary(
        address _transferHandler,
        address _totlePrimary
    ) public {
        require(_transferHandler != address(0x0));
        transferHandler = ITotleTransferHandler(_transferHandler);
        weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        totlePrimary = _totlePrimary;
    }
    
    function performSwap(
        address[8] tokenAddresses,
        uint256[6] amounts,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external returns (uint256) {
        return amounts[1];
    }
    
    function performSwapWithLimit(
        address[8] tokenAddresses,
        uint256[6] amounts,
        uint256,
        uint256,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyTotlePrimary payable returns (uint256) {
        return swapEtherToToken(tokenAddresses, amounts, v, r, s);
    }
    
    function performSwapFromToken(
        address[8] tokenAddresses,
        uint256[6] amounts,
        uint256,
        uint256,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyTotlePrimary returns (uint256) {
        return swapTokenToEther(tokenAddresses, amounts, v, r, s);
    }
    
    function setTotlePrimary(address _totlePrimary) external onlyOwner {
        require(_totlePrimary != address(0));
        totlePrimary = _totlePrimary;
    }
    
    function transferToken(address token, uint amount) external onlyOwner returns (bool) {
        return ERC20(token).transfer(owner, amount);
    }
    
    function transferEther(uint amount) external onlyOwner returns (bool) {
        owner.transfer(amount);
    }
    
    function approveToken(address token, uint amount) external onlyOwner {
        require(ERC20(token).approve(address(transferHandler), amount));
    }
    
    function() public payable {}
    
    function checkHash(
        address tokenFrom,
        uint amountFrom,
        address tokenTo,
        address destination,
        uint amountTo,
        address tokenForFee,
        uint256 feeAmount,
        uint256 expiry
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            tokenFrom,
            amountFrom,
            tokenTo,
            destination,
            amountTo,
            tokenForFee,
            feeAmount,
            expiry
        );
        return transferHandler.checkHash(hash);
    }
    
    function swapEtherToToken(
        address[8] tokenAddresses,
        uint256[6] amounts,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private returns (uint) {
        transferHandler.submitOrder.value(msg.value)(
            tokenAddresses[0],
            amounts[0],
            tokenAddresses[1],
            address(this),
            amounts[1],
            tokenAddresses[3],
            amounts[2],
            amounts[3],
            v,
            r,
            s
        );
        
        require(checkHash(
            tokenAddresses[0],
            amounts[0],
            tokenAddresses[1],
            address(this),
            amounts[1],
            tokenAddresses[3],
            amounts[2],
            amounts[3]
        ));
        
        require(ERC20(tokenAddresses[1]).transfer(tokenAddresses[2], amounts[0]));
        return amounts[0];
    }
    
    function swapTokenToEther(
        address[8] tokenAddresses,
        uint256[6] amounts,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private returns (uint) {
        assert(msg.sender == totlePrimary);
        require(tokenAddresses[1] == address(weth));
        
        uint amountTo = amounts[1];
        
        if(ERC20(tokenAddresses[3]).allowance(address(this), address(transferHandler)) == 0) {
            require(ERC20(tokenAddresses[3]).approve(address(transferHandler), MAX_UINT));
        }
        
        transferHandler.submitOrder(
            tokenAddresses[0],
            amounts[0],
            tokenAddresses[1],
            address(this),
            amountTo,
            tokenAddresses[3],
            amounts[2],
            amounts[3],
            v,
            r,
            s
        );
        
        require(checkHash(
            tokenAddresses[0],
            amounts[0],
            tokenAddresses[1],
            address(this),
            amountTo,
            tokenAddresses[3],
            amounts[2],
            amounts[3]
        ));
        
        weth.withdraw(amounts[0]);
        msg.sender.transfer(amounts[0]);
        return amounts[0];
    }
}
```