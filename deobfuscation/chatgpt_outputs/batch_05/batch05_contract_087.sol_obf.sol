```solidity
pragma solidity 0.4.21;

interface IExchange {
    function executeTrade(
        address[8] addresses,
        uint256[6] values,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    function executeTradeWithEth(
        address[8] addresses,
        uint256[6] values,
        uint256 amount,
        uint256 ethAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (uint256);

    function executeTradeWithoutEth(
        address[8] addresses,
        uint256[6] values,
        uint256 amount,
        uint256 ethAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);
}

contract WrappedEther {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Deposit(address indexed account, uint256 value);
    event Withdrawal(address indexed account, uint256 value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function() public payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        msg.sender.transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        return transferFrom(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value);
        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1)) {
            require(allowance[from][msg.sender] >= value);
            allowance[from][msg.sender] -= value;
        }
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
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

contract Token {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Token is Token {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IVerifier {
    function verify(bytes32 hash) external view returns (bool);
    function execute(
        address from,
        uint256 amount,
        address to,
        address feeRecipient,
        uint256 feeAmount,
        address token,
        uint256 tokenAmount,
        uint256 ethAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

contract Exchange is IExchange, Ownable {
    IVerifier public verifier;
    WrappedEther public weth;
    address public admin;
    uint256 constant MAX_UINT = 2**256 - 1;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function Exchange(address verifierAddress, address wethAddress, address adminAddress) public {
        require(verifierAddress != address(0));
        verifier = IVerifier(verifierAddress);
        weth = WrappedEther(wethAddress);
        admin = adminAddress;
    }

    function executeTrade(
        address[8] addresses,
        uint256[6] values,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external returns (uint256) {
        return values[1];
    }

    function executeTradeWithEth(
        address[8] addresses,
        uint256[6] values,
        uint256,
        uint256 ethAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyAdmin payable returns (uint256) {
        return _executeTrade(addresses, values, v, r, s);
    }

    function executeTradeWithoutEth(
        address[8] addresses,
        uint256[6] values,
        uint256,
        uint256 ethAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyAdmin returns (uint256) {
        return _executeTrade(addresses, values, v, r, s);
    }

    function setAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0));
        admin = newAdmin;
    }

    function withdrawToken(address token, uint256 amount) external onlyOwner returns (bool) {
        return ERC20Token(token).transfer(owner, amount);
    }

    function withdrawEth(uint256 amount) external onlyOwner returns (bool) {
        owner.transfer(amount);
    }

    function approveToken(address token, uint256 amount) external onlyOwner {
        require(ERC20Token(token).approve(address(verifier), amount));
    }

    function() public payable {}

    function verifyTrade(
        address from,
        uint256 amount,
        address to,
        address feeRecipient,
        uint256 feeAmount,
        address token,
        uint256 tokenAmount,
        uint256 ethAmount
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            from,
            amount,
            to,
            feeRecipient,
            feeAmount,
            token,
            tokenAmount,
            ethAmount
        );
        return verifier.verify(hash);
    }

    function _executeTrade(
        address[8] addresses,
        uint256[6] values,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private returns (uint) {
        verifier.execute.value(msg.value)(
            addresses[0],
            values[0],
            addresses[1],
            address(this),
            values[1],
            addresses[3],
            values[2],
            values[3],
            v,
            r,
            s
        );

        require(
            verifyTrade(
                addresses[0],
                values[0],
                addresses[1],
                address(this),
                values[1],
                addresses[3],
                values[2],
                values[3]
            )
        );

        require(
            ERC20Token(addresses[1]).transferFrom(
                addresses[2],
                addresses[0],
                values[0]
            )
        );

        return values[0];
    }
}
```