```solidity
pragma solidity ^0.4.19;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);
}

contract Exchange is SafeMath {
    address public admin;
    address public feeAccount;
    uint256 public feeMake;
    uint256 public feeTake;
    uint256 public lastFreeBlock;
    address public freeToken;
    
    mapping(bytes32 => uint256) public sellOrders;
    mapping(bytes32 => uint256) public buyOrders;
    
    event MakeBuyOrder(bytes32 orderHash, address indexed token, uint256 amount, uint256 price, address indexed maker);
    event MakeSellOrder(bytes32 orderHash, address indexed token, uint256 amount, uint256 price, address indexed maker);
    event CancelBuyOrder(bytes32 orderHash, address indexed token, uint256 amount, uint256 price, address indexed maker);
    event CancelSellOrder(bytes32 orderHash, address indexed token, uint256 amount, uint256 price, address indexed maker);
    event TakeBuyOrder(bytes32 orderHash, address indexed token, uint256 amount, uint256 price, uint256 tokens, address indexed maker, address indexed taker);
    event TakeSellOrder(bytes32 orderHash, address indexed token, uint256 amount, uint256 price, uint256 ethers, address indexed maker, address indexed taker);
    
    function Exchange(
        address _admin,
        address _feeAccount,
        uint256 _feeMake,
        uint256 _feeTake,
        address _freeToken,
        uint256 _lastFreeBlock
    ) public {
        admin = _admin;
        feeAccount = _feeAccount;
        feeMake = _feeMake;
        feeTake = _feeTake;
        freeToken = _freeToken;
        lastFreeBlock = _lastFreeBlock;
    }
    
    function() public {
        revert();
    }
    
    function changeAdmin(address _admin) public {
        require(msg.sender == admin);
        admin = _admin;
    }
    
    function changeFreeToken(address _freeToken) public {
        require(msg.sender == admin);
        require(block.number > ERC20(freeToken).totalSupply());
        freeToken = _freeToken;
    }
    
    function changeLastFreeBlock(uint256 _lastFreeBlock) public {
        require(msg.sender == admin);
        require(_lastFreeBlock > block.number + 100);
        lastFreeBlock = _lastFreeBlock;
    }
    
    function changeFeeAccount(address _feeAccount) public {
        require(msg.sender == admin);
        feeAccount = _feeAccount;
    }
    
    function changeFeeMake(uint256 _feeMake) public {
        require(msg.sender == admin);
        require(_feeMake < feeMake);
        feeMake = _feeMake;
    }
    
    function changeFeeTake(uint256 _feeTake) public {
        require(msg.sender == admin);
        require(_feeTake < feeTake);
        feeTake = _feeTake;
    }
    
    function calcFeeForAccount(uint256 amount, uint256 fee, address account) public constant returns (uint256) {
        if (ERC20(freeToken).balanceOf(account) > 0) {
            return 0;
        }
        if (block.number <= lastFreeBlock) {
            return 0;
        }
        return feeFromAmount(amount, fee);
    }
    
    function feeFromAmount(uint256 amount, uint256 fee) public constant returns (uint256) {
        uint256 feeAmount = safeMul(amount, (1 ether)) / safeAdd((1 ether), fee);
        uint256 remainder = safeMul(amount, (1 ether)) % safeAdd((1 ether), fee);
        
        if (remainder != 0) {
            feeAmount = safeAdd(feeAmount, 1);
        }
        
        uint256 result = safeSub(amount, feeAmount);
        return result;
    }
    
    function calcFeeForMaker(uint256 amount, uint256 fee, address maker) public constant returns (uint256) {
        if (ERC20(freeToken).balanceOf(maker) > 0) {
            return 0;
        }
        if (block.number <= lastFreeBlock) {
            return 0;
        }
        return feeForMaker(amount, fee);
    }
    
    function feeForMaker(uint256 amount, uint256 fee) public constant returns (uint256) {
        uint256 feeAmount = safeMul(amount, fee) / (1 ether);
        return feeAmount;
    }
    
    function makeSellOrder(address token, uint256 amount, uint256 price) public {
        require(amount != 0);
        require(price != 0);
        
        bytes32 orderHash = sha256(token, amount, price, msg.sender);
        sellOrders[orderHash] = safeAdd(sellOrders[orderHash], amount);
        
        require(amount <= ERC20(token).allowance(msg.sender, this));
        
        if (!ERC20(token).transferFrom(msg.sender, this, amount)) {
            revert();
        }
        
        MakeSellOrder(orderHash, token, amount, price, msg.sender);
    }
    
    function makeBuyOrder(address token, uint256 amount) public payable {
        require(amount != 0);
        require(msg.value != 0);
        
        uint256 fee = feeFromAmount(msg.value, feeMake);
        uint256 amountMinusFee = safeSub(msg.value, fee);
        
        bytes32 orderHash = sha256(token, amount, amountMinusFee, msg.sender);
        buyOrders[orderHash] = safeAdd(buyOrders[orderHash], msg.value);
        
        MakeBuyOrder(orderHash, token, amount, amountMinusFee, msg.sender);
    }
    
    function cancelSellOrder(address token, uint256 amount, uint256 price) public {
        bytes32 orderHash = sha256(token, amount, price, msg.sender);
        uint256 orderAmount = sellOrders[orderHash];
        delete sellOrders[orderHash];
        
        ERC20(token).transfer(msg.sender, orderAmount);
        
        CancelSellOrder(orderHash, token, amount, price, msg.sender);
    }
    
    function cancelBuyOrder(address token, uint256 amount, uint256 price) public {
        bytes32 orderHash = sha256(token, amount, price, msg.sender);
        uint256 orderAmount = buyOrders[orderHash];
        delete buyOrders[orderHash];
        
        if (!msg.sender.send(orderAmount)) {
            revert();
        }
        
        CancelBuyOrder(orderHash, token, amount, price, msg.sender);
    }
    
    function takeBuyOrder(address token, uint256 amount, uint256 price, uint256 tokens, address maker) public {
        require(amount != 0);
        require(price != 0);
        require(tokens != 0);
        
        bytes32 orderHash = sha256(token, amount, price, maker);
        uint256 ethers = safeMul(tokens, price) / amount;
        uint256 makerFee = feeForMaker(ethers, feeTake);
        uint256 totalEthers = safeAdd(ethers, makerFee);
        
        require(buyOrders[orderHash] >= totalEthers);
        
        uint256 takerFee = calcFeeForAccount(ethers, feeTake, msg.sender);
        uint256 currentMakerFee = calcFeeForMaker(ethers, feeTake, maker);
        
        buyOrders[orderHash] = safeSub(buyOrders[orderHash], totalEthers);
        
        require(ERC20(token).allowance(msg.sender, this) >= tokens);
        
        if (currentMakerFee < makerFee) {
            uint256 refund = safeSub(makerFee, currentMakerFee);
            if (!maker.send(refund)) {
                revert();
            }
        }
        
        if (!ERC20(token).transferFrom(msg.sender, maker, tokens)) {
            revert();
        }
        
        if (safeAdd(takerFee, currentMakerFee) > 0) {
            if (!feeAccount.send(safeAdd(takerFee, currentMakerFee))) {
                revert();
            }
        }
        
        if (!msg.sender.send(safeSub(ethers, takerFee))) {
            revert();
        }
        
        TakeBuyOrder(orderHash, token, amount, price, tokens, maker, msg.sender);
    }
    
    function takeSellOrder(address token, uint256 amount, uint256 price, address maker) public payable {
        require(amount != 0);
        require(price != 0);
        
        bytes32 orderHash = sha256(token, amount, price, maker);
        uint256 takerFee = calcFeeForAccount(msg.value, feeTake, msg.sender);
        uint256 ethersMinusFee = safeSub(msg.value, takerFee);
        uint256 tokens = safeMul(ethersMinusFee, amount) / price;
        
        require(sellOrders[orderHash] >= tokens);
        
        uint256 currentMakerFee = calcFeeForMaker(ethersMinusFee, feeTake, maker);
        uint256 totalFee = safeAdd(currentMakerFee, takerFee);
        uint256 makerEthers = safeSub(ethersMinusFee, currentMakerFee);
        
        sellOrders[orderHash] = safeSub(sellOrders[orderHash], tokens);
        
        if (!ERC20(token).transfer(msg.sender, tokens)) {
            revert();
        }
        
        if (totalFee > 0) {
            if (!feeAccount.send(totalFee)) {
                revert();
            }
        }
        
        if (!maker.send(makerEthers)) {
            revert();
        }
        
        TakeSellOrder(orderHash, token, amount, price, ethersMinusFee, msg.sender, maker);
    }
}
```