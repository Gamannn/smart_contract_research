```solidity
pragma solidity 0.5.1;

library ECRecovery {
    function recover(bytes32 hash, bytes memory signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length != 65) {
            return (address(0));
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, hash));
    }

    function recoverFromEthSignedMessage(bytes32 hash, bytes memory signature) public pure returns (address) {
        bytes32 ethSignedMessageHash = toEthSignedMessageHash(hash);
        return recover(ethSignedMessageHash, signature);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

contract Escrow {
    using SafeMath for uint256;

    ERC20 public token;
    mapping (address => bool) public authorizedSigners;
    mapping (address => bool) public fundExecutors;
    mapping (uint256 => bool) public usedNonces;
    address payable public admin;
    uint256 constant public gasRefund = 7901;
    uint256 constant public gasLimit1 = 32831;
    uint256 constant public gasLimit2 = 32323;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized access");
        _;
    }

    modifier onlyFundExecutor() {
        require(fundExecutors[msg.sender], "Unauthorized access");
        _;
    }

    modifier validNonce(uint256 nonce, uint256 gasPrice) {
        require(!usedNonces[nonce], "Nonce already used");
        require(gasPrice == tx.gasprice, "Gas price is different from the signed one");
        _;
    }

    constructor(address tokenAddress, address payable adminAddress, address[] memory executors) public {
        admin = adminAddress;
        token = ERC20(tokenAddress);
        for (uint i = 0; i < executors.length; i++) {
            fundExecutors[executors[i]] = true;
        }
    }

    function fund(uint256 nonce, uint256 gasPrice, address payable recipient, uint256 amount, bytes memory signature) public validNonce(nonce, gasPrice) onlyFundExecutor {
        uint256 gasUsed = gasleft().add(gasLimit2);
        bytes32 hash = keccak256(abi.encodePacked(nonce, address(this), gasPrice, recipient, amount));
        _verifySignature(hash, signature, nonce);
        recipient.transfer(amount);
        _refundGas(gasUsed, gasPrice);
    }

    function fundWithToken(uint256 nonce, uint256 gasPrice, address payable recipient, uint256 ethAmount, uint256 tokenAmount, bytes memory signature) public validNonce(nonce, gasPrice) onlyFundExecutor {
        uint256 gasUsed = gasleft().add(gasLimit1);
        bytes32 hash = keccak256(abi.encodePacked(nonce, address(this), gasPrice, recipient, ethAmount, tokenAmount));
        _verifySignature(hash, signature, nonce);
        token.transfer(recipient, tokenAmount);
        recipient.transfer(ethAmount);
        _refundGas(gasUsed, gasPrice);
    }

    function _verifySignature(bytes32 hash, bytes memory signature, uint256 nonce) internal {
        address signer = ECRecovery.recoverFromEthSignedMessage(hash, signature);
        require(authorizedSigners[signer], "Invalid authorization signature or signer");
        usedNonces[nonce] = true;
    }

    function _refundGas(uint256 gasUsed, uint256 gasPrice) internal {
        uint256 refundAmount = gasUsed.sub(gasleft()).add(gasRefund).mul(gasPrice);
        msg.sender.transfer(refundAmount);
    }

    function withdrawEther(uint256 amount) public onlyAdmin {
        admin.transfer(amount);
    }

    function withdrawTokens(uint256 amount) public onlyAdmin {
        token.transfer(admin, amount);
    }

    function setAuthorizedSigner(address signer, bool authorized) public onlyAdmin {
        authorizedSigners[signer] = authorized;
    }

    function changeAdmin(address payable newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    function setFundExecutor(address executor, bool authorized) public onlyAdmin {
        fundExecutors[executor] = authorized;
    }

    function() external payable {}
}
```