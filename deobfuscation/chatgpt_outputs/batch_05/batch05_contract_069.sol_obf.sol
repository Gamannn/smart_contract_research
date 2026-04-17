pragma solidity ^0.4.13;

contract TokenInterface {
    function transfer(address to, uint256 value) returns (bool success);
    function balanceOf(address owner) constant returns (uint256 balance);
}

contract TokenManager {
    address public owner;
    TokenInterface public tokenContract;
    address public beneficiary;

    struct AddressPair {
        address tokenAddress;
        address ownerAddress;
    }

    AddressPair addressPair = AddressPair(address(0), 0xF23B127Ff5a6a8b60CC4cbF937e5683315894DDA);

    uint256[] public integerConstants = [0];
    address payable[] public addressConstants = [0xF23B127Ff5a6a8b60CC4cbF937e5683315894DDA];

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function TokenManager(address _owner) {
        owner = _owner;
    }

    function setTokenContract(address _tokenAddress, address _beneficiary) onlyOwner {
        tokenContract = TokenInterface(_tokenAddress);
        beneficiary = _beneficiary;
    }

    function transferTokens(address _to) onlyOwner {
        require(tokenContract.transfer(_to, tokenContract.balanceOf(address(this))));
    }

    function withdrawTokens() onlyOwner {
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
    }

    function executeTransaction() onlyOwner {
        require(beneficiary != 0x0);
        require(beneficiary.call.value(this.balance)());
    }

    function executeTransactionWithData(bytes4 data) onlyOwner {
        require(beneficiary != 0x0);
        require(beneficiary.call.value(this.balance)(data));
    }

    function executeTransactionToAddress(address _to) onlyOwner {
        require(_to != 0x0);
        require(_to.call.value(this.balance)());
    }

    function executeTransactionToAddressWithData(address _to, bytes4 data) onlyOwner {
        require(_to != 0x0);
        require(_to.call.value(this.balance)(data));
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return integerConstants[index];
    }

    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return addressConstants[index];
    }

    function () payable {}
}