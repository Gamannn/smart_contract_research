pragma solidity 0.4.21;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TargetContract {
    function withdraw() public;
    function buy(address) public payable returns(uint256);
}

contract Ownable {
    address public owner;
    address public pendingOwner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }
    
    function claimOwnership() public {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
    }
}

contract MainContract is Ownable {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    TargetContract internal constant target = TargetContract(address(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe));
    
    function() payable public {
        distribute();
    }
    
    function distribute() public {
        uint256 contractBalance = address(this).balance;
        if(contractBalance > 1) {
            uint256 halfBalance = contractBalance / 2;
            feeRecipient.call(halfBalance);
            target.buy.value(halfBalance)(msg.sender);
        }
    }
    
    function withdraw(address targetAddress) public {
        TargetContract(targetAddress).withdraw();
        distribute();
    }
    
    function withdraw() public {
        target.withdraw();
        distribute();
    }
    
    function withdrawAll() public {
        target.withdraw();
        distribute();
    }
    
    function deposit() payable public {
        feeRecipient.call(msg.value);
    }
    
    function deposit(address targetAddress) payable public {
        target.buy.value(msg.value)(msg.sender);
    }
    
    function buy() payable public {
        target.buy.value(msg.value)(msg.sender);
    }
    
    struct Storage {
        address feeRecipient;
        address pendingOwner;
        address owner;
    }
    
    Storage storageData = Storage(
        address(0xAfd87E1E1eCe09D18f4834F64F63502718d1b3d4),
        address(0),
        address(0)
    );
    
    address private feeRecipient = storageData.feeRecipient;
}