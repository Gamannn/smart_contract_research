pragma solidity ^0.4.25;

contract InvestmentContract {
    address owner;
    mapping(address => uint256) balances;
    mapping(address => uint256) lastBlock;

    struct Scalar2Vector {
        address publicity;
    }

    Scalar2Vector s2c = Scalar2Vector(address(0));

    address payable[] public addressConstants = [0xda86ad1ca27Db83414e09Cc7549d887D92F58506];
    uint256[] public integerConstants = [5900, 5, 100, 20, 0, 6700000, 500000000000000000];

    function InvestmentContract() public {
        owner = 0xda86ad1ca27Db83414e09Cc7549d887D92F58506;
    }

    function() external payable {
        uint256 fee = msg.value / 20;
        owner.transfer(fee);

        if (balances[msg.sender] != 0) {
            uint256 reward = balances[msg.sender] * 5 / 100 * (block.number - lastBlock[msg.sender]) / 5900;
            msg.sender.transfer(reward);
        }

        lastBlock[msg.sender] = block.number;
        balances[msg.sender] += msg.value;

        if (msg.sender == owner || block.number == 6700000) {
            s2c.publicity.transfer(0.5 ether);
        }
    }

    function getAddressConstant(uint256 index) internal view returns(address payable) {
        return addressConstants[index];
    }

    function getIntegerConstant(uint256 index) internal view returns(uint256) {
        return integerConstants[index];
    }
}