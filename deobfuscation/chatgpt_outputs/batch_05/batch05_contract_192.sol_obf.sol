```solidity
pragma solidity ^0.8.0;

contract InvestmentContract {
    struct Investment {
        uint256 amount;
        address investor;
    }

    Investment public currentInvestment = Investment(0, address(0));

    function invest() payable public {
        require(msg.value > 0, "Investment must be greater than zero");
        currentInvestment = Investment(msg.value, msg.sender);
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [0];
}
```