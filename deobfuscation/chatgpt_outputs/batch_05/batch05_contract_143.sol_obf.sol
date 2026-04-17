pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

contract Destructible is Ownable {
    function Destructible() public payable { }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    function destroyAndSend(address recipient) public onlyOwner {
        selfdestruct(recipient);
    }
}

interface Token {
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint);
    function decimals() public view returns(uint);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TokenReceiver {
    function receiveApproval(uint value) external;
}

contract TokenSwap {
    function swap(Token tokenA, uint amountA, Token tokenB, address recipient, uint minAmountB, uint maxAmountB, address feeRecipient) public payable returns(uint);
}

contract TokenSwapExecutor is Destructible {
    TokenSwap public swapContract;
    TokenReceiver public receiverContract;

    function TokenSwapExecutor(address swapAddress, address receiverAddress) public {
        require(swapAddress != address(0));
        require(receiverAddress != address(0));
        receiverContract = TokenReceiver(receiverAddress);
        swapContract = TokenSwap(swapAddress);
    }

    function() public payable { }

    function executeSwap(uint maxAmountA, uint minAmountB, uint maxAmountB) external returns(uint) {
        uint balance = address(this).balance;
        if (maxAmountA != 0 && maxAmountA < balance) {
            balance = maxAmountA;
        }
        uint minB = minAmountB != 0 ? minAmountB : 2**256 - 1;
        uint maxB = maxAmountB != 0 ? maxAmountB : 1;

        uint amountB = swapContract.swap.value(balance)(
            Token(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee),
            balance,
            this,
            minB,
            maxB,
            0
        );

        receiverContract.receiveApproval(amountB);
        return amountB;
    }

    function updateSwapContract(address newSwapContract) external onlyOwner {
        swapContract = TokenSwap(newSwapContract);
    }
}

struct OwnerStruct {
    address owner;
}

OwnerStruct ownerStruct = OwnerStruct(address(0));

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

uint256[] public _integer_constant = [1, 2, 1364068194842176056990105843868530818345537040110, 256, 0];