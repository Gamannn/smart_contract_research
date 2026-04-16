```solidity
pragma solidity ^0.4.25;

contract SafeMath {
    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function safeSub(int a, int b) internal pure returns (int) {
        if (b < 0) assert(a - b > a);
        else assert(a - b <= a);
        return a - b;
    }
    
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
    
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
}

contract Token {
    function transfer(address to, uint value) public returns (bool);
    function balanceOf(address holder) public view returns (uint);
    function approve(address spender, uint value) public returns (bool);
}

contract Casino {
    function deposit(address receiver, uint amount, bool chargeGas) public;
}

contract Owned {
    address public owner;
    address public receiver;
    mapping(address => bool) public moderator;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyModerator {
        require(moderator[msg.sender]);
        _;
    }
    
    modifier onlyAdmin {
        require(moderator[msg.sender] || msg.sender == owner);
        _;
    }
    
    constructor() internal {
        owner = msg.sender;
        receiver = msg.sender;
    }
    
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function setReceiver(address newReceiver) public onlyAdmin {
        receiver = newReceiver;
    }
    
    function addModerator(address moderatorAddress) public onlyOwner {
        moderator[moderatorAddress] = true;
    }
    
    function removeModerator(address moderatorAddress) public onlyOwner {
        moderator[moderatorAddress] = false;
    }
}

contract RequiringAuthorization is Owned {
    mapping(address => bool) public authorized;
    
    modifier onlyAuthorized {
        require(authorized[msg.sender]);
        _;
    }
    
    constructor() internal {
        authorized[msg.sender] = true;
    }
    
    function authorize(address addressToAuthorize) public onlyAdmin {
        authorized[addressToAuthorize] = true;
    }
    
    function deauthorize(address addressToDeauthorize) public onlyAdmin {
        authorized[addressToDeauthorize] = false;
    }
}

contract Pausable is Owned {
    bool public paused = false;
    
    event Paused(bool paused);
    
    modifier whenPaused {
        require(paused == true);
        _;
    }
    
    modifier whenActive {
        require(paused == false);
        _;
    }
    
    function pause() public whenActive onlyAdmin {
        paused = true;
        emit Paused(true);
    }
    
    function activate() public whenPaused onlyOwner {
        paused = false;
        emit Paused(false);
    }
}

contract BankWallet is Pausable, RequiringAuthorization, SafeMath {
    address public edgelessToken;
    address public edgelessCasino;
    uint public oneEdg = 100000;
    uint public maxFundAmount = 0.22 ether;
    
    event Withdrawal(address token, uint amount);
    event Deposit(address receiver, uint amount);
    event Fund(address receiver, uint amount);
    
    constructor(address token, address casino) public {
        edgelessToken = token;
        edgelessCasino = casino;
        owner = msg.sender;
    }
    
    function() public payable {}
    
    function withdraw(address token, uint amount) public onlyAdmin returns (bool success) {
        success = false;
        
        if (token == address(0)) {
            uint weiAmount = amount;
            if (weiAmount > address(this).balance) {
                return false;
            }
            success = receiver.send(weiAmount);
        } else {
            Token tokenContract = Token(token);
            uint tokenAmount = amount;
            if (tokenAmount > tokenContract.balanceOf(this)) {
                return false;
            }
            success = tokenContract.transfer(receiver, tokenAmount);
        }
        
        if (success) {
            emit Withdrawal(token, amount);
        }
    }
    
    function approve(uint amount) public onlyAuthorized {
        _approveForCasino(edgelessCasino, amount);
    }
    
    function deposit(address receiverAddress, uint amount, bool chargeGas) public onlyAuthorized {
        Casino casino = Casino(edgelessCasino);
        casino.deposit(receiverAddress, amount, chargeGas);
        emit Deposit(receiverAddress, amount);
    }
    
    function fund(address receiverAddress, uint amount) public onlyAuthorized returns (bool success) {
        require(amount <= maxFundAmount);
        success = receiverAddress.send(amount);
        if (success) {
            emit Fund(receiverAddress, amount);
        }
    }
    
    function setCasinoContract(address casino) public onlyAdmin {
        edgelessCasino = casino;
        _approveForCasino(casino, 1000000000);
    }
    
    function setMaxFundAmount(uint amount) public onlyAdmin {
        maxFundAmount = amount;
    }
    
    function _approveForCasino(address casinoAddress, uint amount) internal returns (bool success) {
        Token token = Token(edgelessToken);
        success = token.approve(casinoAddress, safeMul(amount, oneEdg));
    }
}
```