pragma solidity ^0.5.8;

contract Oxd85ff4ec43031b3488562baa03f00e0412b18296 {
    struct Pool {
        uint256 redAmount;
        uint256 blueAmount;
        address payable beneficiary;
    }
    
    Pool public pool = Pool(0, 0, 0x82338B1b27cfC0C27D79c3738B748f951Ab1a7A0);

    function withdraw() public {
        pool.beneficiary.transfer(address(this).balance);
    }

    function contributeToRed() public payable {
        pool.redAmount += msg.value;
    }

    function contributeToBlue() public payable {
        pool.blueAmount += msg.value;
    }

    function() external payable {
        if(msg.value % 2 == 0) {
            pool.redAmount += msg.value;
        } else {
            pool.blueAmount += msg.value;
        }
    }

    function getWinnerAmount() public view returns (uint256) {
        if(pool.redAmount > pool.blueAmount) {
            return pool.redAmount;
        } else if (pool.redAmount < pool.blueAmount) {
            return pool.blueAmount;
        }
        return 0;
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }

    uint256[] public _integer_constant = [0, 2, 1];
    address payable[] public _address_constant = [0x82338B1b27cfC0C27D79c3738B748f951Ab1a7A0];
}