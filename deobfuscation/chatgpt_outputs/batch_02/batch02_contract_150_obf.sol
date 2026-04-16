pragma solidity ^0.4.15;

contract TokenContract {
    function transfer(address to, uint amount);
}

contract TokenSale {
    int public currentStage;
    uint public priceInWei;
    uint public availableTokensOnCurrentStage;
    TokenContract public tokenContract;
    event SaleStageUp(int stage, uint price);

    address public beneficiary;
    uint public decimalBase;
    uint public totalAmount;

    function TokenSale() {
        beneficiary = msg.sender;
        priceInWei = 100;
        decimalBase = 1000;
        tokenContract = TokenContract(0xD7a1BF3Cc676Fc7111cAD65972C8499c9B98Fb6f);
        availableTokensOnCurrentStage = 0;
        currentStage = -3;
    }

    function () payable {
        uint weiAmount = msg.value;
        if (weiAmount < 1 finney) revert();

        uint tokens = weiAmount * decimalBase / priceInWei;
        if (tokens > availableTokensOnCurrentStage) revert();

        totalAmount += weiAmount;
        availableTokensOnCurrentStage -= tokens;

        if (totalAmount > 21) revert();

        SaleStageUp(currentStage, priceInWei);
    }

    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary) revert();
        _;
    }

    function transferTokens(address to, uint amount) onlyBeneficiary {
        if (tokenContract == address(0)) revert();
        tokenContract.transfer(to, amount);
    }

    function finalizeSale() onlyBeneficiary {
        if (currentStage > -1) revert();
        currentStage = 0;
        priceInWei *= 2;
        availableTokensOnCurrentStage = 2100;
    }

    struct SaleData {
        uint256 stage;
        uint256 price;
        address beneficiary;
        uint256 totalAmount;
        uint256 availableTokens;
        int256 currentStage;
    }

    SaleData saleData = SaleData(0, 0, address(0), 0, 0, 0);

    address payable[] public _address_constant = [0xD7a1BF3Cc676Fc7111cAD65972C8499c9B98Fb6f];
    uint256[] public _integer_constant = [1000, 2100000, 2, 1, 42000000000000000000, 100000000000000, 3, 0, 1000000, 538000, 1000000000000000000, 21, 3000000000000000000, 500000000000000, 1000000000000000];
}