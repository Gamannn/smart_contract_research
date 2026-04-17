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

interface ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function decimals() public view returns(uint256);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface KyberNetwork {
    function trade(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId
    ) public payable returns(uint);
}

interface WrappedEther {
    function deposit() external payable;
}

contract ArbitrageBot is Destructible {
    KyberNetwork public kyberNetwork;
    WrappedEther public wrappedEther;
    
    function ArbitrageBot(address wrappedEtherAddress, address kyberNetworkAddress) public {
        require(wrappedEtherAddress != address(0));
        require(kyberNetworkAddress != address(0));
        
        wrappedEther = WrappedEther(wrappedEtherAddress);
        kyberNetwork = KyberNetwork(kyberNetworkAddress);
    }
    
    function() public payable { }
    
    function executeTrade(
        uint256 maxSrcAmount,
        uint256 maxDestAmount,
        uint256 minConversionRate
    ) external returns(uint) {
        uint256 srcAmount = address(this).balance;
        
        if (maxSrcAmount != 0 && maxSrcAmount < srcAmount) {
            srcAmount = maxSrcAmount;
        }
        
        uint256 actualMaxDestAmount = maxDestAmount != 0 ? maxDestAmount : 2**256 - 1;
        uint256 actualMinConversionRate = minConversionRate != 0 ? minConversionRate : 1;
        
        uint256 result = kyberNetwork.trade.value(srcAmount)(
            ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee),
            srcAmount,
            this,
            actualMaxDestAmount,
            actualMinConversionRate,
            0
        );
        
        wrappedEther.deposit.value(result)();
        return result;
    }
    
    function setKyberNetwork(address newKyberNetwork) external onlyOwner {
        kyberNetwork = KyberNetwork(newKyberNetwork);
    }
}