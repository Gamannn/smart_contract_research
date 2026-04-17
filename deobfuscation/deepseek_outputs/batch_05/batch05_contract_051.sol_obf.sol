```solidity
pragma solidity ^0.5.7;

interface IPriceOracle {
    function getUnderlyingPrice(address) external view returns (address);
}

interface IComptroller {
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

interface ICToken {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
}

interface ICEther {
    function mint() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function transfer(address, uint) external returns (bool);
    function borrowBalanceCurrent(address account) external returns (uint);
}

interface ICompoundLens {
    function cTokenBalancesAll(address[] calldata cTokens) external returns (uint[] memory);
    function cTokenMetadata(address cToken) external returns (uint);
    function cTokenUnderlyingPrice(address cToken) external view returns (address[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
}

contract SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        require((c = a + b) >= a, "math-not-safe");
    }
    
    function mul(uint a, uint b) internal pure returns (uint c) {
        require(b == 0 || (c = a * b) / b == a, "math-not-safe");
    }
    
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    
    function wmul(uint a, uint b) internal pure returns (uint c) {
        c = add(mul(a, b), WAD / 2) / WAD;
    }
    
    function rmul(uint a, uint b) internal pure returns (uint c) {
        c = add(mul(a, RAY), b / 2) / b;
    }
    
    function wdiv(uint a, uint b) internal pure returns (uint c) {
        c = add(mul(a, WAD), b / 2) / b;
    }
    
    function rdiv(uint a, uint b) internal pure returns (uint c) {
        c = add(mul(a, RAY), b / 2) / b;
    }
    
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
    }
}

contract CompoundBasicProxy is SafeMath {
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant DAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant COMPTROLLER_ADDRESS = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant CDAI_ADDRESS = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;
    address public constant CUSDC_ADDRESS = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address payable public constant ADMIN1 = 0x0f0EBD0d7672362D11e0b6d219abA30b0588954E;
    address public constant ADMIN2 = 0xd8db02A498E9AFbf4A32BC006DC1940495b4e592;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    
    mapping (address => mapping (address => uint)) public deposits;
    mapping (address => uint) public totalDeposits;
    
    event LogDepositToken(address token, address cToken, uint amount);
    event LogWithdrawToken(address token, address cToken, uint amount);
    event LogDepositCToken(address cToken, uint amount);
    event LogWithdrawCToken(address cToken, uint amount);
    
    function deposit(address token, address cToken, uint amount) public payable {
        if (token != ETH_ADDRESS) {
            IERC20 tokenContract = IERC20(token);
            require(tokenContract.transferFrom(msg.sender, address(this), amount), "Not enough token allowance");
            
            ICToken cTokenContract = ICToken(cToken);
            uint balanceBefore = tokenContract.balanceOf(address(this));
            assert(cTokenContract.mint(amount) == 0);
            uint balanceAfter = tokenContract.balanceOf(address(this));
            assert(balanceBefore != balanceAfter);
            
            uint exchangeRate = cTokenContract.exchangeRateCurrent();
            uint cTokenAmount = rdiv(amount, exchangeRate);
            cTokenAmount = wmul(cTokenAmount, exchangeRate) <= amount ? cTokenAmount : cTokenAmount - 1;
            
            deposits[msg.sender][cToken] += cTokenAmount;
            totalDeposits[cToken] += cTokenAmount;
            
            emit LogDepositToken(token, cToken, amount);
        } else {
            ICEther cEtherContract = ICEther(cToken);
            uint balanceBefore = address(this).balance;
            cEtherContract.mint.value(msg.value)();
            uint balanceAfter = address(this).balance;
            assert(balanceBefore != balanceAfter);
            
            uint exchangeRate = cEtherContract.exchangeRateCurrent();
            uint cTokenAmount = rdiv(msg.value, exchangeRate);
            cTokenAmount = wmul(cTokenAmount, exchangeRate) <= msg.value ? cTokenAmount : cTokenAmount - 1;
            
            deposits[msg.sender][cToken] += cTokenAmount;
            totalDeposits[cToken] += cTokenAmount;
            
            emit LogDepositToken(token, cToken, msg.value);
        }
    }
    
    function withdraw(address token, address cToken, uint amount) public {
        require(deposits[msg.sender][cToken] != 0, "Nothing to withdraw");
        
        ICToken cTokenContract = ICToken(cToken);
        uint exchangeRate = cTokenContract.exchangeRateCurrent();
        uint withdrawCTokens = rdiv(amount, exchangeRate);
        uint withdrawAmount = amount;
        
        if (withdrawCTokens > deposits[msg.sender][cToken]) {
            withdrawCTokens = deposits[msg.sender][cToken] - 1;
            withdrawAmount = wmul(withdrawCTokens, exchangeRate);
        }
        
        if (token != ETH_ADDRESS) {
            IERC20 tokenContract = IERC20(token);
            uint balanceBefore = tokenContract.balanceOf(address(this));
            require(cTokenContract.redeemUnderlying(withdrawAmount) == 0, "something went wrong");
            uint balanceAfter = tokenContract.balanceOf(address(this));
            assert(balanceBefore != balanceAfter);
            require(tokenContract.transfer(msg.sender, withdrawAmount), "not enough token transfer");
        } else {
            uint balanceBefore = address(this).balance;
            require(cTokenContract.redeemUnderlying(withdrawAmount) == 0, "something went wrong");
            uint balanceAfter = address(this).balance;
            assert(balanceBefore != balanceAfter);
            msg.sender.transfer(withdrawAmount);
        }
        
        deposits[msg.sender][cToken] -= withdrawCTokens;
        totalDeposits[cToken] -= withdrawCTokens;
        
        emit LogWithdrawToken(token, cToken, withdrawAmount);
    }
    
    function depositCToken(address cToken, uint amount) public {
        require(ICToken(cToken).transferFrom(msg.sender, address(this), amount), "Nothing to deposit");
        deposits[msg.sender][cToken] += amount;
        totalDeposits[cToken] += amount;
        emit LogDepositCToken(cToken, amount);
    }
    
    function withdrawCToken(address cToken, uint amount) public {
        require(deposits[msg.sender][cToken] != 0, "Nothing to withdraw");
        uint withdrawAmount = amount < deposits[msg.sender][cToken] ? amount : deposits[msg.sender][cToken];
        assert(ICToken(cToken).transfer(msg.sender, withdrawAmount));
        deposits[msg.sender][cToken] -= withdrawAmount;
        totalDeposits[cToken] -= withdrawAmount;
        emit LogWithdrawCToken(cToken, withdrawAmount);
    }
}

contract CompoundAdvancedProxy is CompoundBasicProxy {
    event LogRedeemTknAndTransfer(address token, address cToken, uint amount);
    event LogMintTknBack(address token, address cToken, uint amount);
    event LogBorrowTknAndTransfer(address token, address cToken, uint amount);
    event LogPayBorrowBack(address token, address cToken, uint amount);
    
    modifier isUser() {
        address user = msg.sender;
        address wallet = IPriceOracle(COMPTROLLER_ADDRESS).getUnderlyingPrice(user);
        require(wallet != address(0), "not-user-wallet");
        require(wallet == msg.sender, "not-wallet-owner");
        _;
    }
    
    function redeemTknAndTransfer(address token, address cToken, uint amount) public isUser {
        if (amount > 0) {
            if (token != ETH_ADDRESS) {
                ICToken cTokenContract = ICToken(cToken);
                IERC20 tokenContract = IERC20(token);
                uint balanceBefore = tokenContract.balanceOf(address(this));
                assert(cTokenContract.redeemUnderlying(amount) == 0);
                uint balanceAfter = tokenContract.balanceOf(address(this));
                assert(balanceBefore != balanceAfter);
                assert(tokenContract.transfer(msg.sender, amount));
            } else {
                ICToken cTokenContract = ICToken(cToken);
                uint balanceBefore = address(this).balance;
                assert(cTokenContract.redeemUnderlying(amount) == 0);
                uint balanceAfter = address(this).balance;
                assert(balanceBefore != balanceAfter);
                msg.sender.transfer(amount);
            }
            emit LogRedeemTknAndTransfer(token, cToken, amount);
        }
    }
    
    function mintTknBack(address token, address cToken, uint amount) public payable isUser {
        _mintTokenBack(token, cToken, amount);
    }
    
    function borrowTknAndTransfer(address token, address cToken, uint amount) public isUser {
        if (amount > 0) {
            ICToken cTokenContract = ICToken(cToken);
            if (token != ETH_ADDRESS) {
                IERC20 tokenContract = IERC20(token);
                uint balanceBefore = tokenContract.balanceOf(address(this));
                assert(cTokenContract.borrow(amount) == 0);
                uint balanceAfter = tokenContract.balanceOf(address(this));
                assert(balanceBefore != balanceAfter);
                assert(tokenContract.transfer(msg.sender, amount));
            } else {
                uint balanceBefore = address(this).balance;
                assert(cTokenContract.borrow(amount) == 0);
                uint balanceAfter = address(this).balance;
                assert(balanceBefore != balanceAfter);
                msg.sender.transfer(amount);
            }
            emit LogBorrowTknAndTransfer(token, cToken, amount);
        }
    }
    
    function payBorrowBack(address token, address cToken, uint amount) public payable isUser {
        if (amount > 0) {
            if (token != ETH_ADDRESS) {
                IERC20 tokenContract = IERC20(token);
                ICToken cTokenContract = ICToken(cToken);
                uint borrowBalance = cTokenContract.borrowBalanceCurrent(address(this));
                uint balanceBefore = tokenContract.balanceOf(address(this));
                assert(cTokenContract.repayBorrowBehalf(address(this), borrowBalance) == 0);
                uint balanceAfter = tokenContract.balanceOf(address(this));
                assert(balanceBefore != balanceAfter);
                emit LogPayBorrowBack(token, cToken, borrowBalance);
            } else {
                ICEther cEtherContract = ICEther(cToken);
                uint borrowBalance = cEtherContract.borrowBalanceCurrent(address(this));
                uint balanceBefore = address(this).balance;
                cEtherContract.repayBorrowBehalf.value(borrowBalance)(address(this));
                uint balanceAfter = address(this).balance;
                assert(balanceBefore != balanceAfter);
                emit LogPayBorrowBack(token, cToken, borrowBalance);
            }
        }
    }
    
    function _mintTokenBack(address token, address cToken, uint amount) internal {
        if (amount > 0) {
            if (token != ETH_ADDRESS) {
                ICToken cTokenContract = ICToken(cToken);
                IERC20 tokenContract = IERC20(token);
                uint balanceBefore = tokenContract.balanceOf(address(this));
                assert(balanceBefore >= amount);
                assert(cTokenContract.mint(balanceBefore) == 0);
                uint balanceAfter = tokenContract.balanceOf(address(this));
                assert(balanceBefore != balanceAfter);
                emit LogMintTknBack(token, cToken, balanceBefore);
            } else {
                ICEther cEtherContract = ICEther(cToken);
                uint balanceBefore = address(this).balance;
                assert(balanceBefore >= amount);
                cEtherContract.mint.value(balanceBefore)();
                uint balanceAfter = address(this).balance;
                assert(balanceBefore != balanceAfter);
                emit LogMintTknBack(token, cToken, balanceBefore);
            }
        }
    }
}

contract CompoundAdminProxy is CompoundAdvancedProxy {
    function approveToken(address token, uint amount, address spender) public {
        require(msg.sender == ADMIN1 || msg.sender == ADMIN2, "Not admin address");
        IERC20 tokenContract = IERC20(token);
        uint currentAllowance = tokenContract.allowance(address(this), spender);
        if (amount > currentAllowance) {
            tokenContract.approve(spender, uint(-1));
        }
    }
    
    function withdrawProfit(address cToken) public {
        require(msg.sender == ADMIN1 || msg.sender == ADMIN2, "Not admin address");
        ICToken cTokenContract = ICToken(cToken);
        uint totalBalance = cTokenContract.balanceOf(address(this));
        uint profit = sub(totalBalance, totalDeposits[cToken]);
        require(cTokenContract.transfer(msg.sender, profit), "CToken Transfer failed");
    }
    
    function withdrawToken(address token) public {
        require(msg.sender == ADMIN1 || msg.sender == ADMIN2, "Not admin address");
        if (token == ETH_ADDRESS) {
            ADMIN1.transfer(address(this).balance);
        } else {
            IERC20 tokenContract = IERC20(token);
            uint balance = tokenContract.balanceOf(address(this));
            require(tokenContract.transfer(msg.sender, balance), "Transfer failed");
        }
    }
    
    function adminMintTokenBack(address token, address cToken, uint amount) public payable {
        require(msg.sender == ADMIN1 || msg.sender == ADMIN2, "Not admin address");
        _mintTokenBack(token, cToken, amount);
    }
    
    function enterMarkets(address[] memory cTokens) public {
        require(msg.sender == ADMIN1 || msg.sender == ADMIN2, "Not admin address");
        IComptroller comptroller = IComptroller(COMPTROLLER_ADDRESS);
        comptroller.enterMarkets(cTokens);
    }
    
    function getAccountLiquidity(address account) public {
        require(msg.sender == ADMIN1 || msg.sender == ADMIN2, "Not admin address");
        IComptroller comptroller = IComptroller(COMPTROLLER_ADDRESS);
        comptroller.getAccountLiquidity(account);
    }
}

contract CompoundProxy is CompoundAdminProxy {
    constructor() public {
        address[] memory markets = new address[](3);
        markets[0] = CETH_ADDRESS;
        markets[1] = CDAI_ADDRESS;
        markets[2] = CUSDC_ADDRESS;
        enterMarkets(markets);
        
        approveToken(DAI_ADDRESS, 2**255, DAI_ADDRESS);
        approveToken(USDC_ADDRESS, 2**255, CUSDC_ADDRESS);
        approveToken(CDAI_ADDRESS, 2**255, CDAI_ADDRESS);
        approveToken(CUSDC_ADDRESS, 2**255, CUSDC_ADDRESS);
        approveToken(CETH_ADDRESS, 2**255, CETH_ADDRESS);
    }
    
    function() external payable {}
}
```