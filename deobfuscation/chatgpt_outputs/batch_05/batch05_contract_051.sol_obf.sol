```solidity
pragma solidity ^0.5.7;

interface IAddressProvider {
    function getAddress(address) external view returns (address);
}

interface IWalletProvider {
    function getWallet() external view returns (address);
}

interface IToken {
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

interface ICToken {
    function mint(uint) external returns (uint);
    function redeem(uint) external returns (uint);
    function borrow(uint) external returns (uint);
    function repayBorrow(uint) external returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function borrowBalanceCurrent(address) external returns (uint);
    function borrowBalanceStored(address) external view returns (uint);
}

interface ICompound {
    function exchangeRateCurrent() external returns (uint);
    function mint() external payable;
    function repayBorrow() external payable;
    function transfer(address, uint) external returns (bool);
    function borrowBalanceCurrent(address) external returns (uint);
}

interface IPriceOracle {
    function getUnderlyingPrice(address) external view returns (uint);
    function getPrice(address) external view returns (uint);
    function getAssetsIn(address) external view returns (address[] memory);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
}

contract SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        require((c = a + b) >= a, "math-not-safe");
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        require(b == 0 || (c = a * b) / b == a, "math-not-safe");
    }

    uint constant DECIMALS = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function rayMul(uint a, uint b) internal pure returns (uint c) {
        c = add(mul(a, b), RAY / 2) / RAY;
    }

    function rayDiv(uint a, uint b) internal pure returns (uint c) {
        c = add(mul(a, RAY), b / 2) / b;
    }

    function wadMul(uint a, uint b) internal pure returns (uint c) {
        c = add(mul(a, b), DECIMALS / 2) / DECIMALS;
    }

    function wadDiv(uint a, uint b) internal pure returns (uint c) {
        c = add(mul(a, DECIMALS), b / 2) / b;
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
    }
}

contract CompoundManager is SafeMath {
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant DAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant CDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant CUSDC_ADDRESS = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address public constant COMPTROLLER_ADDRESS = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    mapping(address => mapping(address => uint)) public deposits;
    mapping(address => uint) public totalDeposits;

    event LogDepositToken(address indexed user, address indexed token, uint amount);
    event LogWithdrawToken(address indexed user, address indexed token, uint amount);
    event LogDepositCToken(address indexed cToken, uint amount);
    event LogWithdrawCToken(address indexed cToken, uint amount);

    function depositToken(address token, address cToken, uint amount) public payable {
        if (token != ETH_ADDRESS) {
            IToken tokenContract = IToken(token);
            require(tokenContract.transferFrom(msg.sender, address(this), amount), "Not enough tokens transferred");
            ICToken cTokenContract = ICToken(cToken);
            uint initialBalance = cTokenContract.balanceOf(address(this));
            assert(cTokenContract.mint(amount) == 0);
            uint finalBalance = cTokenContract.balanceOf(address(this));
            assert(initialBalance != finalBalance);
            uint exchangeRate = cTokenContract.exchangeRateCurrent();
            uint cAmount = wadDiv(amount, exchangeRate);
            cAmount = sub(cAmount, exchangeRate) <= amount ? cAmount : cAmount - 1;
            deposits[msg.sender][cToken] += cAmount;
            totalDeposits[cToken] += cAmount;
            emit LogDepositToken(token, cToken, amount);
        } else {
            ICompound cTokenContract = ICompound(cToken);
            uint initialBalance = address(this).balance;
            cTokenContract.mint.value(msg.value)();
            uint finalBalance = address(this).balance;
            assert(initialBalance != finalBalance);
            uint exchangeRate = cTokenContract.exchangeRateCurrent();
            uint cAmount = wadDiv(msg.value, exchangeRate);
            cAmount = sub(cAmount, exchangeRate) <= msg.value ? cAmount : cAmount - 1;
            deposits[msg.sender][cToken] += cAmount;
            totalDeposits[cToken] += cAmount;
            emit LogDepositToken(token, cToken, msg.value);
        }
    }

    function withdrawToken(address token, address cToken, uint amount) public {
        require(deposits[msg.sender][cToken] != 0, "Nothing to withdraw");
        ICToken cTokenContract = ICToken(cToken);
        uint exchangeRate = cTokenContract.exchangeRateCurrent();
        uint withdrawAmount = wadDiv(amount, exchangeRate);
        uint cAmount = amount;
        if (cAmount > deposits[msg.sender][cToken]) {
            cAmount = deposits[msg.sender][cToken] - 1;
            cAmount = sub(cAmount, exchangeRate);
        }
        if (token != ETH_ADDRESS) {
            IToken tokenContract = IToken(token);
            uint initialBalance = tokenContract.balanceOf(address(this));
            require(cTokenContract.redeem(cAmount) == 0, "something went wrong");
            uint finalBalance = tokenContract.balanceOf(address(this));
            assert(initialBalance != finalBalance);
            require(tokenContract.transfer(msg.sender, cAmount), "not enough tokens transferred");
        } else {
            uint initialBalance = address(this).balance;
            require(cTokenContract.redeem(cAmount) == 0, "something went wrong");
            uint finalBalance = address(this).balance;
            assert(initialBalance != finalBalance);
            msg.sender.transfer(cAmount);
        }
        deposits[msg.sender][cToken] -= cAmount;
        totalDeposits[cToken] -= cAmount;
        emit LogWithdrawToken(token, cToken, cAmount);
    }

    function depositCToken(address cToken, uint amount) public {
        require(ICToken(cToken).transferFrom(msg.sender, address(this), amount), "Nothing to deposit");
        deposits[msg.sender][cToken] += amount;
        totalDeposits[cToken] += amount;
        emit LogDepositCToken(cToken, amount);
    }

    function withdrawCToken(address cToken, uint amount) public {
        require(deposits[msg.sender][cToken] != 0, "Nothing to withdraw");
        uint cAmount = amount < deposits[msg.sender][cToken] ? amount : deposits[msg.sender][cToken];
        assert(ICToken(cToken).transfer(msg.sender, cAmount));
        deposits[msg.sender][cToken] -= cAmount;
        totalDeposits[cToken] -= cAmount;
        emit LogWithdrawCToken(cToken, cAmount);
    }
}

contract CompoundActions is CompoundManager {
    event LogRedeemTokenAndTransfer(address indexed user, address indexed cToken, uint amount);
    event LogMintTokenBack(address indexed user, address indexed cToken, uint amount);
    event LogBorrowTokenAndTransfer(address indexed user, address indexed cToken, uint amount);
    event LogPayBorrowBack(address indexed user, address indexed cToken, uint amount);

    modifier onlyUserWallet() {
        address wallet = IWalletProvider(msg.sender).getWallet();
        address userWallet = IAddressProvider(USDC_ADDRESS).getAddress(wallet);
        require(userWallet != address(0), "not-user-wallet");
        require(userWallet == msg.sender, "not-wallet");
        _;
    }

    function redeemTokenAndTransfer(address token, address cToken, uint amount) public onlyUserWallet {
        if (amount > 0) {
            if (token != ETH_ADDRESS) {
                ICToken cTokenContract = ICToken(cToken);
                IToken tokenContract = IToken(token);
                uint initialBalance = tokenContract.balanceOf(address(this));
                assert(cTokenContract.redeem(amount) == 0);
                uint finalBalance = tokenContract.balanceOf(address(this));
                assert(initialBalance != finalBalance);
                assert(tokenContract.transfer(msg.sender, amount));
            } else {
                ICToken cTokenContract = ICToken(cToken);
                uint initialBalance = address(this).balance;
                assert(cTokenContract.redeem(amount) == 0);
                uint finalBalance = address(this).balance;
                assert(initialBalance != finalBalance);
                msg.sender.transfer(amount);
            }
            emit LogRedeemTokenAndTransfer(token, cToken, amount);
        }
    }

    function mintTokenBack(address token, address cToken, uint amount) public payable onlyUserWallet {
        mintToken(token, cToken, amount);
    }

    function borrowTokenAndTransfer(address token, address cToken, uint amount) public onlyUserWallet {
        if (amount > 0) {
            ICToken cTokenContract = ICToken(cToken);
            if (token != ETH_ADDRESS) {
                IToken tokenContract = IToken(token);
                uint initialBalance = tokenContract.balanceOf(address(this));
                assert(cTokenContract.borrow(amount) == 0);
                uint finalBalance = tokenContract.balanceOf(address(this));
                assert(initialBalance != finalBalance);
                assert(tokenContract.transfer(msg.sender, amount));
            } else {
                uint initialBalance = address(this).balance;
                assert(cTokenContract.borrow(amount) == 0);
                uint finalBalance = address(this).balance;
                assert(initialBalance != finalBalance);
                msg.sender.transfer(amount);
            }
            emit LogBorrowTokenAndTransfer(token, cToken, amount);
        }
    }

    function payBorrowBack(address token, address cToken, uint amount) public payable onlyUserWallet {
        if (amount > 0) {
            if (token != ETH_ADDRESS) {
                IToken tokenContract = IToken(token);
                ICToken cTokenContract = ICToken(cToken);
                uint initialBalance = tokenContract.balanceOf(address(this));
                assert(cTokenContract.repayBorrow(amount) == 0);
                uint finalBalance = tokenContract.balanceOf(address(this));
                assert(initialBalance != finalBalance);
                emit LogPayBorrowBack(token, cToken, amount);
            } else {
                ICompound cTokenContract = ICompound(cToken);
                uint initialBalance = address(this).balance;
                cTokenContract.repayBorrow.value(amount)();
                uint finalBalance = address(this).balance;
                assert(initialBalance != finalBalance);
                emit LogPayBorrowBack(token, cToken, amount);
            }
        }
    }

    function mintToken(address token, address cToken, uint amount) internal {
        if (amount > 0) {
            if (token != ETH_ADDRESS) {
                ICToken cTokenContract = ICToken(cToken);
                IToken tokenContract = IToken(token);
                uint initialBalance = tokenContract.balanceOf(address(this));
                assert(initialBalance >= amount);
                assert(cTokenContract.mint(amount) == 0);
                uint finalBalance = tokenContract.balanceOf(address(this));
                assert(initialBalance != finalBalance);
                emit LogMintTokenBack(token, cToken, amount);
            } else {
                ICompound cTokenContract = ICompound(cToken);
                uint initialBalance = address(this).balance;
                assert(initialBalance >= amount);
                cTokenContract.mint.value(amount)();
                uint finalBalance = address(this).balance;
                assert(initialBalance != finalBalance);
                emit LogMintTokenBack(token, cToken, amount);
            }
        }
    }
}

contract CompoundAdmin is CompoundActions {
    function setTokenAllowance(address token, uint amount, address spender) public {
        require(msg.sender == 0xA7b5a337272fca920b4162122e5d7be7a04406e7 || msg.sender == 0x0f0EBD0d7672362D11e0b6d219abA30b0588954E, "Not admin address");
        IToken tokenContract = IToken(token);
        uint currentAllowance = tokenContract.allowance(address(this), spender);
        if (amount > currentAllowance) {
            tokenContract.approve(spender, uint(-1));
        }
    }

    function withdrawCToken(address cToken) public {
        require(msg.sender == 0xA7b5a337272fca920b4162122e5d7be7a04406e7 || msg.sender == 0x0f0EBD0d7672362D11e0b6d219abA30b0588954E, "Not admin address");
        ICToken cTokenContract = ICToken(cToken);
        uint balance = cTokenContract.balanceOf(address(this));
        uint withdrawAmount = sub(balance, totalDeposits[cToken]);
        require(cTokenContract.transfer(msg.sender, withdrawAmount), "CToken Transfer failed");
    }

    function withdrawToken(address token) public {
        require(msg.sender == 0xA7b5a337272fca920b4162122e5d7be7a04406e7 || msg.sender == 0x0f0EBD0d7672362D11e0b6d219abA30b0588954E, "Not admin address");
        assert(deposits[token][msg.sender] == false);
        if (token == ETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            IToken tokenContract = IToken(token);
            uint balance = tokenContract.balanceOf(address(this));
            require(tokenContract.transfer(msg.sender, balance), "Transfer failed");
        }
    }

    function mintTokenBackAdmin(address token, address cToken, uint amount) public payable {
        require(msg.sender == 0xA7b5a337272fca920b4162122e5d7be7a04406e7 || msg.sender == 0x0f0EBD0d7672362D11e0b6d219abA30b0588954E, "Not admin address");
        mintToken(token, cToken, amount);
    }

    function setAssetsIn(address[] memory assets) public {
        require(msg.sender == 0xA7b5a337272fca920b4162122e5d7be7a04406e7 || msg.sender == 0x0f0EBD0d7672362D11e0b6d219abA30b0588954E, "Not admin address");
        IPriceOracle priceOracle = IPriceOracle(COMPTROLLER_ADDRESS);
        priceOracle.getAssetsIn(assets);
    }

    function setPriceOracle(address oracle) public {
        require(msg.sender == 0xA7b5a337272fca920b4162122e5d7be7a04406e7 || msg.sender == 0x0f0EBD0d7672362D11e0b6d219abA30b0588954E, "Not admin address");
        IPriceOracle priceOracle = IPriceOracle(COMPTROLLER_ADDRESS);
        priceOracle.getPrice(oracle);
    }
}

contract CompoundDeployer is CompoundAdmin {
    constructor() public {
        address[] memory assets = new address[](3);
        assets[0] = CETH_ADDRESS;
        assets[1] = CDAI_ADDRESS;
        assets[2] = CUSDC_ADDRESS;
        setAssetsIn(assets);
        setTokenAllowance(DAI_ADDRESS, 2**255, CDAI_ADDRESS);
        setTokenAllowance(USDC_ADDRESS, 2**255, CUSDC_ADDRESS);
        setTokenAllowance(CETH_ADDRESS, 2**255, CETH_ADDRESS);
        setTokenAllowance(CDAI_ADDRESS, 2**255, CDAI_ADDRESS);
        setTokenAllowance(CUSDC_ADDRESS, 2**255, CUSDC_ADDRESS);
    }

    function() external payable {}
}
```