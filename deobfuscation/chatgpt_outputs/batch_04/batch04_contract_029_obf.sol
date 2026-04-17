```solidity
pragma solidity ^0.4.21;

contract TokenContract {
    uint256 constant INITIAL_SUPPLY = 10000000;
    uint256 constant MAX_FEE_PERCENTAGE = 2500;
    uint256 constant FEE_PERCENTAGE = 1250;
    uint256 constant DIVIDEND_CONSTANT = 10000000;
    uint256 constant MINIMUM_BALANCE = 400000;
    uint256 constant SELL_ORDER_CONSTANT = 1600000;
    uint256 constant PRICE_CONSTANT = 0.5 szabo;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastDividendPoints;
    mapping(address => uint256[2]) public sellOrders;

    struct Scalar2Vector {
        address owner;
        uint16 feePercentage;
        uint256 totalPaid;
        uint256 totalSupply;
    }

    Scalar2Vector s2c = Scalar2Vector({
        owner: 0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285,
        feePercentage: FEE_PERCENTAGE,
        totalPaid: 0,
        totalSupply: INITIAL_SUPPLY
    });

    function TokenContract() public {
        balances[msg.sender] = INITIAL_SUPPLY - MINIMUM_BALANCE;
        balances[0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285] = MINIMUM_BALANCE;
        balances[0x26581d1983ced8955C170eB4d3222DCd3845a092] = MINIMUM_BALANCE;
        placeSellOrder(SELL_ORDER_CONSTANT, PRICE_CONSTANT);
    }

    function getSellOrder(address user) public view returns (uint256, uint256) {
        return (sellOrders[user][0], sellOrders[user][1]);
    }

    function viewMyTokens(address user) public view returns (uint256) {
        return balances[user];
    }

    function getDividend(address user) public view returns (uint256) {
        uint256 balance = balances[user];
        if (balance == 0) {
            return 0;
        }
        return calculateDividend(user, balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function calculateDividend(address user, uint256 balance) internal view returns (uint256) {
        if (balance == 0) {
            return 0;
        }
        uint256 totalPaid = address(this).balance + s2c.totalPaid;
        uint256 dividend = (totalPaid * balance) / s2c.totalSupply;
        return dividend;
    }

    event Sold(address seller, address buyer, uint256 price, uint256 amount);

    function sellTokens(address buyer) public payable {
        uint256[2] memory order = sellOrders[buyer];
        uint256 amount = order[0];
        uint256 price = order[1];
        uint256 excess = 0;

        if (amount == 0) {
            revert();
        }

        uint256 totalPrice = amount * PRICE_CONSTANT;
        uint256 payment = msg.value;

        if (payment > totalPrice) {
            excess = payment - totalPrice;
            payment = totalPrice;
        }

        uint256 tokensToTransfer = payment / price;
        if (tokensToTransfer == 0) {
            revert();
        }

        excess += calculateDividend(payment, tokensToTransfer * price);

        if (excess > 0) {
            msg.sender.transfer(excess);
        }

        uint256 fee = (s2c.feePercentage * payment) / 10000;
        s2c.owner.transfer(fee);
        buyer.transfer(payment - fee);

        updateBalances(buyer, balances[buyer]);
        if (balances[msg.sender] > 0) {
            updateBalances(msg.sender, balances[msg.sender]);
        }

        balances[buyer] -= tokensToTransfer;
        sellOrders[buyer][0] -= tokensToTransfer;
        balances[msg.sender] += tokensToTransfer;
        lastDividendPoints[msg.sender] = address(this).balance + s2c.totalPaid;

        emit Sold(msg.sender, buyer, price, tokensToTransfer);
    }

    function updateBalances(address user, uint256 balance) internal {
        if (balances[user] == 0) {
            revert();
        }
        uint256 dividend = calculateDividend(user, balance);
        user.transfer(dividend);
        s2c.totalPaid += dividend;
        lastDividendPoints[user] = s2c.totalPaid + address(this).balance;
    }

    event SellOrderPlaced(address user, uint256 amount, uint256 price);

    function placeSellOrder(uint256 amount, uint256 price) public {
        if (amount > balances[msg.sender]) {
            revert();
        }
        sellOrders[msg.sender] = [amount, price];
        emit SellOrderPlaced(msg.sender, amount, price);
    }

    function updateFeePercentage(uint16 newFeePercentage) public {
        require(newFeePercentage <= MAX_FEE_PERCENTAGE);
        require(msg.sender == s2c.owner);
        s2c.feePercentage = newFeePercentage;
    }

    function() public payable {}

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}
```