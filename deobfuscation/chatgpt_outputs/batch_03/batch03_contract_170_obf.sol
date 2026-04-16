```solidity
pragma solidity 0.4.21;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ExternalContract {
    function execute() public;
    function deposit(address) public payable returns(uint256);
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

contract TokenHandler is Ownable {
    ExternalContract internal constant externalContract = ExternalContract(address(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe));

    function() payable public {
        handleTokens();
    }

    function handleTokens() public {
        uint256 balance = address(this).balance;
        if (balance > 1) {
            uint256 halfBalance = balance / 2;
            s2c.tokenReceiver.call(halfBalance);
            externalContract.deposit.value(halfBalance)(msg.sender);
        }
    }

    function executeExternal(address externalAddress) public {
        ExternalContract(externalAddress).execute();
        handleTokens();
    }

    function execute() public {
        externalContract.execute();
        handleTokens();
    }

    function executeAndHandle() public {
        externalContract.execute();
        handleTokens();
    }

    function deposit() payable public {
        s2c.tokenReceiver.call(msg.value);
    }

    function depositTo(address externalAddress) payable public {
        externalContract.deposit.value(msg.value)(msg.sender);
    }

    function depositAndHandle() payable public {
        externalContract.deposit.value(msg.value)(msg.sender);
    }

    struct Scalar2Vector {
        address tokenReceiver;
        address pendingOwner;
        address owner;
    }

    Scalar2Vector s2c = Scalar2Vector(
        address(0xAfd87E1E1eCe09D18f4834F64F63502718d1b3d4),
        address(0),
        address(0)
    );
}
```