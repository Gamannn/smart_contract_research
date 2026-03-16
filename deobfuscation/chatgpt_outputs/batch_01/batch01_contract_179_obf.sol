```solidity
pragma solidity ^0.4.19;

contract TokenInterface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address owner) public constant returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint256) {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Exchange is SafeMath {
    mapping (address => mapping (address => uint256)) public tokens;
    mapping (bytes32 => bool) public orders;
    mapping (bytes32 => uint256) public orderFills;
    mapping (address => bool) public admins;
    mapping (address => uint256) public lastActiveTransaction;
    mapping (bytes32 => bool) public withdrawn;
    mapping (address => uint256) public rewards;
    mapping (address => uint256) public feeDiscounts;

    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event Trade(address tokenBuy, address tokenSell, uint256 amountBuy, uint256 amountSell, uint256 fee, address userBuy, address userSell);
    event Cancel(address user, bytes32 orderHash, uint256 nonce);
    event Claim(address user, uint256 amount);

    struct Admin {
        bool locked;
        address feeAccount;
        uint256 feeMake;
        uint256 feeTake;
        uint256 feeRebate;
        uint256 feeDiscount;
        address admin;
        address owner;
    }

    Admin public admin;

    function Exchange(address feeAccount) public {
        admin.owner = msg.sender;
        admin.feeAccount = feeAccount;
    }

    function setOwner(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            admin.owner = newOwner;
        }
    }

    function setFeeAccount(address feeAccount) public onlyOwner {
        admin.feeAccount = feeAccount;
    }

    function addAdmin(address adminAddress) public onlyOwner {
        admins[adminAddress] = true;
    }

    function removeAdmin(address adminAddress) public onlyOwner {
        admins[adminAddress] = false;
    }

    function setFeeDiscount(address user, uint256 discount) public onlyOwner {
        feeDiscounts[user] = discount;
    }

    function setLocked(bool locked) public onlyOwner {
        admin.locked = locked;
    }

    modifier onlyOwner() {
        require(msg.sender == admin.owner);
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }

    modifier notLocked() {
        require(!admin.locked);
        _;
    }

    function() external {
        revert();
    }

    function depositToken(address token, uint amount) public {
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        require(TokenInterface(token).transferFrom(msg.sender, this, amount));
        Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function deposit() public payable {
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function withdrawToken(address token, uint amount, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public {
        require(tokens[token][msg.sender] >= amount);
        require(admins[user]);
        bytes32 hash = keccak256(this, msg.sender, token, amount, nonce);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        require(!withdrawn[hash]);
        withdrawn[hash] = true;
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (token == address(0)) {
            require(msg.sender.send(amount));
        } else {
            require(TokenInterface(token).transfer(msg.sender, amount));
        }
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function balanceOf(address token, address user) public view returns(uint) {
        return tokens[token][user];
    }

    function setLastActiveTransaction(address user, uint256 nonce) public onlyAdmin {
        require(nonce > lastActiveTransaction[user]);
        lastActiveTransaction[user] = nonce;
    }

    function getFeeDiscount(address user) public view returns(uint256) {
        uint256 discount = feeDiscounts[user];
        if (admin.feeMake > 500000000e18) {
            return discount;
        } else if (admin.feeMake > 400000000e18 && admin.feeMake <= 500000000e18) {
            return discount * 9e17 / 1e18;
        } else if (admin.feeMake > 300000000e18 && admin.feeMake <= 400000000e18) {
            return discount * 8e17 / 1e18;
        } else if (admin.feeMake > 200000000e18 && admin.feeMake <= 300000000e18) {
            return discount * 7e17 / 1e18;
        } else if (admin.feeMake > 100000000e18 && admin.feeMake <= 200000000e18) {
            return discount * 6e17 / 1e18;
        } else if(admin.feeMake <= 100000000e18) {
            return discount * 5e17 / 1e18;
        }
    }

    function trade(
        address[5] addresses,
        uint[11] values,
        uint8[3] v,
        bytes32[6] rs
    ) public notLocked returns (bool) {
        require(admins[addresses[4]]);
        require(lastActiveTransaction[addresses[2]] < values[2]);
        require(lastActiveTransaction[addresses[3]] < values[5]);
        require(values[6] > 0 && values[7] > 0 && values[8] > 0);
        require(values[1] >= values[7] && values[4] >= values[7]);
        require(msg.sender == addresses[2] || msg.sender == addresses[3] || msg.sender == addresses[4]);

        bytes32 orderHash1 = keccak256(address(this), addresses[0], addresses[1], addresses[2], values[0], values[1], values[2]);
        bytes32 orderHash2 = keccak256(address(this), addresses[0], addresses[1], addresses[3], values[3], values[4], values[5]);

        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash1), v[0], rs[0], rs[1]) == addresses[2]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash2), v[1], rs[2], rs[3]) == addresses[3]);

        bytes32 tradeHash = keccak256(this, orderHash1, orderHash2, addresses[4], values[6], values[7], values[8], values[9], values[10]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", tradeHash), v[2], rs[4], rs[5]) == addresses[4]);
        require(!orders[tradeHash]);
        orders[tradeHash] = true;

        require(safeAdd(orderFills[orderHash1], values[6]) <= values[0]);
        require(safeAdd(orderFills[orderHash2], values[6]) <= values[3]);

        require(tokens[addresses[1]][addresses[2]] >= values[7]);
        tokens[addresses[1]][addresses[2]] = safeSub(tokens[addresses[1]][addresses[2]], values[7]);

        require(tokens[addresses[0]][addresses[3]] >= values[6]);
        tokens[addresses[0]][addresses[3]] = safeSub(tokens[addresses[0]][addresses[3]], values[6]);

        tokens[addresses[0]][addresses[2]] = safeAdd(tokens[addresses[0]][addresses[2]], safeSub(values[6], (safeMul(values[6], values[9]) / 1 ether)));
        tokens[addresses[1]][addresses[3]] = safeAdd(tokens[addresses[1]][addresses[3]], safeSub(values[7], (safeMul(values[7], values[10]) / 1 ether)));

        tokens[addresses[0]][admin.feeAccount] = safeAdd(tokens[addresses[0]][admin.feeAccount], safeMul(values[6], values[9]) / 1 ether);
        tokens[addresses[1]][admin.feeAccount] = safeAdd(tokens[addresses[1]][admin.feeAccount], safeMul(values[7], values[10]) / 1 ether);

        orderFills[orderHash1] = safeAdd(orderFills[orderHash1], values[6]);
        orderFills[orderHash2] = safeAdd(orderFills[orderHash2], values[6]);

        Trade(addresses[0], addresses[1], values[6], values[7], values[8], addresses[2], addresses[3]);

        if(admin.feeMake > 0) {
            if(feeDiscounts[addresses[1]] > 0){
                uint256 reward = safeMul(safeMul(values[7], getFeeDiscount(addresses[1])), 2) / (1 ether);
                if(admin.feeMake > reward) {
                    rewards[addresses[2]] = safeAdd(rewards[addresses[2]], safeSub(reward, reward / 2));
                    rewards[addresses[3]] = safeAdd(rewards[addresses[3]], reward / 2);
                    admin.feeMake = safeSub(admin.feeMake, reward);
                } else {
                    rewards[addresses[2]] = safeAdd(rewards[addresses[2]], safeSub(admin.feeMake, admin.feeMake / 2));
                    rewards[addresses[3]] = safeAdd(rewards[addresses[3]], admin.feeMake / 2);
                    admin.feeMake = 0;
                }
            }
        }
        return true;
    }

    function claimReward() public returns(bool) {
        require(rewards[msg.sender] > 0);
        require(admin.feeAccount != address(0));
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        require(TokenInterface(admin.feeAccount).transfer(msg.sender, reward));
        Claim(msg.sender, reward);
        return true;
    }

    function distributeFees() public onlyOwner returns(bool) {
        uint256 fee = safeSub(admin.feeMake, admin.feeRebate);
        require(fee > 0);
        uint256 rebate = safeMul(admin.feeDiscount, fee) / admin.feeMake;
        uint256 reward = safeSub(rebate, admin.feeRebate);
        require(reward > 0);
        admin.feeRebate = rebate;
        require(TokenInterface(admin.feeAccount).transfer(msg.sender, reward));
        Claim(msg.sender, reward);
        return true;
    }

    function cancelOrder(
        address tokenBuy,
        address tokenSell,
        address user,
        uint amountBuy,
        uint amountSell,
        uint nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyAdmin returns(bool) {
        bytes32 orderHash = keccak256(this, tokenBuy, tokenSell, user, amountBuy, amountSell, nonce);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v, r, s) == user);
        orderFills[orderHash] = amountBuy;
        Cancel(user, orderHash, nonce);
        return true;
    }

    function ecrecoverVerify(
        address user,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool) {
        return user == ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s);
    }
}
```