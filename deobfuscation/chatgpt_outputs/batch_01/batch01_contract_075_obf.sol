```solidity
pragma solidity ^0.4.19;

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

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Token {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract FeeModifiersInterface {
    function accountFeeModifiers(address user) public view returns (uint256 feeDiscount, uint256 feeRebate);
    function tradingFeeModifiers(address _maker, address _taker) public view returns (uint256 feeMakeDiscount, uint256 feeTakeDiscount, uint256 feeRebate);
}

contract TradeTrackerInterface {
    function tradeEventHandler(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, address _maker, address _taker, bytes32 _orderHash, uint256 _gasLimit) public;
}

contract ETHERCExchange is Ownable {
    using SafeMath for uint256;

    struct ExchangeData {
        uint256 feeTake;
        uint256 feeMake;
        address feeAccount;
        address feeModifiers;
        address tradeTracker;
    }

    ExchangeData public exchangeData;

    mapping (address => mapping (address => uint256)) public balances;
    mapping (bytes32 => bool) public cancelledOrders;
    mapping (bytes32 => uint256) public orderFills;

    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event Cancel(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address maker, uint8 v, bytes32 r, bytes32 s, bytes32 orderHash, uint256 amountFilled);
    event Trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, address maker, address taker, bytes32 orderHash);

    function ETHERCExchange() public {
        exchangeData.feeAccount = owner;
    }

    function() public {
        revert();
    }

    function getAccountFeeModifiers(address user) public view returns(uint256 feeDiscount, uint256 feeRebate) {
        if (exchangeData.feeModifiers != address(0)) {
            (feeDiscount, feeRebate) = FeeModifiersInterface(exchangeData.feeModifiers).accountFeeModifiers(user);
        }
    }

    function deposit() public payable {
        balances[address(0)][msg.sender] = balances[address(0)][msg.sender].add(msg.value);
        Deposit(address(0), msg.sender, msg.value, balances[address(0)][msg.sender]);
    }

    function depositToken(address _token, uint256 _amount) public {
        require(_token != address(0));
        if (!Token(_token).transferFrom(msg.sender, this, _amount)) revert();
        balances[_token][msg.sender] = balances[_token][msg.sender].add(_amount);
        Deposit(_token, msg.sender, _amount, balances[_token][msg.sender]);
    }

    function withdraw(uint256 _amount) public {
        require(balances[address(0)][msg.sender] >= _amount);
        balances[address(0)][msg.sender] = balances[address(0)][msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        Withdraw(address(0), msg.sender, _amount, balances[address(0)][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        require(_token != address(0));
        require(balances[_token][msg.sender] >= _amount);
        balances[_token][msg.sender] = balances[_token][msg.sender].sub(_amount);
        if (!Token(_token).transfer(msg.sender, _amount)) revert();
        Withdraw(_token, msg.sender, _amount, balances[_token][msg.sender]);
    }

    function balanceOf(address _token, address user) public view returns (uint256) {
        return balances[_token][user];
    }

    function trade(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker, uint8 _v, bytes32 _r, bytes32 _s, uint256 _amountTrade) public {
        uint256 executionGasLimit = msg.gas;
        bytes32 orderHash = getOrderHash(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker);
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), _v, _r, _s) != _maker || cancelledOrders[orderHash] || block.number > _expires || orderFills[orderHash].add(_amountTrade) > _amountGet) revert();
        tradeBalances(_tokenGet, _amountGet, _tokenGive, _amountGive, _maker, _amountTrade);
        orderFills[orderHash] = orderFills[orderHash].add(_amountTrade);
        uint256 amountTradeGive = _amountGive.mul(_amountTrade) / _amountGet;
        if(exchangeData.tradeTracker != address(0)){
            TradeTrackerInterface(exchangeData.tradeTracker).tradeEventHandler(_tokenGet, _amountTrade, _tokenGive, amountTradeGive, _maker, msg.sender, orderHash, executionGasLimit);
        }
        Trade(_tokenGet, _amountTrade, _tokenGive, amountTradeGive, _maker, msg.sender, orderHash);
    }

    function tradeBalances(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, address _maker, uint256 _amountTrade) private {
        uint256 feeMakeValue = _amountTrade.mul(exchangeData.feeMake) / (1 ether);
        uint256 feeTakeValue = _amountTrade.mul(exchangeData.feeTake) / (1 ether);
        uint256 feeRebateValue = 0;
        if (exchangeData.feeModifiers != address(0)) {
            uint256 feeMakeDiscount;
            uint256 feeTakeDiscount;
            uint256 feeRebate;
            (feeMakeDiscount, feeTakeDiscount, feeRebate) = FeeModifiersInterface(exchangeData.feeModifiers).tradingFeeModifiers(_maker, msg.sender);
            if (feeMakeValue > 0 && feeMakeDiscount > 0 && feeMakeDiscount <= 100 ) feeMakeValue = feeMakeValue.mul(100 - feeMakeDiscount) / 100;
            if (feeTakeValue > 0 && feeTakeDiscount > 0 && feeTakeDiscount <= 100 ) feeTakeValue = feeTakeValue.mul(100 - feeTakeDiscount) / 100;
            if (feeTakeValue > 0 && feeRebate > 0 && feeRebate <= 100) feeRebateValue = feeTakeValue.mul(feeRebate) / 100;
        }
        balances[_tokenGet][msg.sender] = balances[_tokenGet][msg.sender].sub(_amountTrade.add(feeTakeValue));
        balances[_tokenGet][_maker] = balances[_tokenGet][_maker].add(_amountTrade.sub(feeMakeValue).add(feeRebateValue));
        balances[_tokenGive][msg.sender] = balances[_tokenGive][msg.sender].add(_amountGive.mul(_amountTrade) / _amountGet);
        balances[_tokenGive][_maker] = balances[_tokenGive][_maker].sub(_amountGive.mul(_amountTrade) / _amountGet);
        balances[_tokenGet][exchangeData.feeAccount] = balances[_tokenGet][exchangeData.feeAccount].add(feeMakeValue.add(feeTakeValue).sub(feeRebateValue));
    }

    function validateTrade(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker, uint8 _v, bytes32 _r, bytes32 _s, uint256 _amountTrade, address _taker) public view returns (uint8) {
        uint256 feeTakeValue = calculateTakerFee(_taker, _amountTrade);
        if (_amountTrade.add(feeTakeValue) > balances[_tokenGet][_taker]) return 1;
        if (availableVolume(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker, _v, _r, _s) < _amountTrade) return 2;
        return 0;
    }

    function calculateTakerFee(address _taker, uint256 _amountTrade) public view returns (uint256) {
        uint256 feeTakeValue = _amountTrade.mul(exchangeData.feeTake) / (1 ether);
        uint256 feeDiscount;
        uint256 feeRebate;
        (feeDiscount, feeRebate) = getAccountFeeModifiers(_taker);
        if (feeTakeValue > 0 && feeDiscount > 0 && feeDiscount <= 100 ) feeTakeValue = feeTakeValue.mul(100 - feeDiscount) / 100;
        return feeTakeValue;
    }

    function getOrderHash(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker) public view returns (bytes32) {
        return keccak256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker);
    }

    function availableVolume(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker, uint8 _v, bytes32 _r, bytes32 _s) public view returns (uint256) {
        bytes32 orderHash = getOrderHash(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker);
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), _v, _r, _s) != _maker || cancelledOrders[orderHash] || block.number > _expires || _amountGet <= orderFills[orderHash]) return 0;
        uint256[2] memory available;
        available[0] = _amountGet.sub(orderFills[orderHash]);
        available[1] = balances[_tokenGive][_maker].mul(_amountGet) / _amountGive;
        if (available[0] < available[1]) return available[0];
        return available[1];
    }

    function amountFilled(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker) public view returns (uint256) {
        bytes32 orderHash = getOrderHash(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker);
        return orderFills[orderHash];
    }

    function cancelOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) public {
        bytes32 orderHash = getOrderHash(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender);
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), _v, _r, _s) != msg.sender) revert();
        cancelledOrders[orderHash] = true;
        Cancel(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender, _v, _r, _s, orderHash, orderFills[orderHash]);
    }

    function changeFeeAccount(address _feeAccount) public onlyOwner {
        require(_feeAccount != address(0));
        exchangeData.feeAccount = _feeAccount;
    }

    function changeFeeMake(uint256 _feeMake) public onlyOwner {
        require(_feeMake != exchangeData.feeMake);
        exchangeData.feeMake = _feeMake;
    }

    function changeFeeTake(uint256 _feeTake) public onlyOwner {
        require(_feeTake != exchangeData.feeTake);
        exchangeData.feeTake = _feeTake;
    }

    function changeFeeModifiers(address _feeModifiers) public onlyOwner {
        require(exchangeData.feeModifiers != _feeModifiers);
        exchangeData.feeModifiers = _feeModifiers;
    }

    function changeTradeTracker(address _tradeTracker) public onlyOwner {
        require(exchangeData.tradeTracker != _tradeTracker);
        exchangeData.tradeTracker = _tradeTracker;
    }
}
```