```solidity
pragma solidity ^0.5.13;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ChargesFee is Ownable {
    using SafeERC20 for IERC20;

    event SetFeeManager(address addr);
    event SetFeeCollector(address addr);
    event SetEthFee(uint256 ethFee);
    event SetGaltFee(uint256 galtFee);
    event WithdrawEth(address indexed to, uint256 amount);
    event WithdrawErc20(address indexed to, address indexed tokenAddress, uint256 amount);
    event WithdrawErc721(address indexed to, address indexed tokenAddress, uint256 tokenId);

    uint256 public ethFee;
    uint256 public galtFee;
    address public feeManager;
    address public feeCollector;

    modifier onlyFeeManager() {
        require(msg.sender == feeManager, "ChargesFee: caller is not the feeManager");
        _;
    }

    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector, "ChargesFee: caller is not the feeCollector");
        _;
    }

    constructor(uint256 _ethFee, uint256 _galtFee) public {
        ethFee = _ethFee;
        galtFee = _galtFee;
    }

    function _galtToken() internal view returns (IERC20);

    function setFeeManager(address _addr) external onlyOwner {
        feeManager = _addr;
        emit SetFeeManager(_addr);
    }

    function setFeeCollector(address _addr) external onlyOwner {
        feeCollector = _addr;
        emit SetFeeCollector(_addr);
    }

    function setEthFee(uint256 _ethFee) external onlyFeeManager {
        ethFee = _ethFee;
        emit SetEthFee(_ethFee);
    }

    function setGaltFee(uint256 _galtFee) external onlyFeeManager {
        galtFee = _galtFee;
        emit SetGaltFee(_galtFee);
    }

    function withdrawErc20(address _tokenAddress, address _to) external onlyFeeCollector {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(_to, balance);
        emit WithdrawErc20(_to, _tokenAddress, balance);
    }

    function withdrawErc721(address _tokenAddress, address _to, uint256 _tokenId) external onlyFeeCollector {
        IERC721(_tokenAddress).transferFrom(address(this), _to, _tokenId);
        emit WithdrawErc721(_to, _tokenAddress, _tokenId);
    }

    function withdrawEth(address payable _to) external onlyFeeCollector {
        uint256 balance = address(this).balance;
        _to.transfer(balance);
        emit WithdrawEth(_to, balance);
    }

    function _acceptPayment() internal {
        if (msg.value == 0) {
            _galtToken().transferFrom(msg.sender, address(this), galtFee);
        } else {
            require(msg.value == ethFee, "Fee and msg.value not equal");
        }
    }
}

interface IACL {
    function setRole(bytes32 _role, address _candidate, bool _allow) external;
    function hasRole(address _candidate, bytes32 _role) external view returns (bool);
}

interface IPPGlobalRegistry {
    function setContract(bytes32 _key, address _value) external;
    function getContract(bytes32 _key) external view returns (address);
    function getACL() external view returns (IACL);
    function getGaltTokenAddress() external view returns (address);
    function getPPTokenRegistryAddress() external view returns (address);
    function getPPLockerRegistryAddress() external view returns (address);
    function getPPMarketAddress() external view returns (address);
}

interface IPPTokenController {
    event Mint(address indexed to, uint256 indexed tokenId);
    event SetGeoDataManager(address indexed geoDataManager);
    event SetFeeManager(address indexed feeManager);
    event SetFeeCollector(address indexed feeCollector);
    event NewProposal(uint256 indexed proposalId, uint256 indexed tokenId, address indexed creator);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalExecutionFailed(uint256 indexed proposalId);
    event ProposalApproval(uint256 indexed proposalId, uint256 indexed tokenId);
    event ProposalRejection(uint256 indexed proposalId, uint256 indexed tokenId);
    event ProposalCancellation(uint256 indexed proposalId, uint256 indexed tokenId);
    event SetMinter(address indexed minter);
    event SetBurner(address indexed burner);
    event SetBurnTimeout(uint256 indexed tokenId, uint256 timeout);
    event InitiateTokenBurn(uint256 indexed tokenId, uint256 timeoutAt);
    event BurnTokenByTimeout(uint256 indexed tokenId);
    event CancelTokenBurn(uint256 indexed tokenId);
    event SetFee(bytes32 indexed key, uint256 value);
    event WithdrawEth(address indexed to, uint256 amount);
    event WithdrawErc20(address indexed to, address indexed tokenAddress, uint256 amount);

    enum PropertyInitialSetupStage { PENDING, DETAILS, DONE }

    function fees(bytes32) external view returns (uint256);
    function setBurner(address _burner) external;
    function setGeoDataManager(address _geoDataManager) external;
    function setFeeManager(address _feeManager) external;
    function setFeeCollector(address _feeCollector) external;
    function setBurnTimeoutDuration(uint256 _tokenId, uint256 _duration) external;
    function setFee(bytes32 _key, uint256 _value) external;
    function withdrawErc20(address _tokenAddress, address _to) external;
    function withdrawEth(address payable _to) external;
    function initiateTokenBurn(uint256 _tokenId) external;
    function cancelTokenBurn(uint256 _tokenId) external;
    function burnTokenByTimeout(uint256 _tokenId) external;
    function propose(bytes calldata _data, string calldata _dataLink) external payable;
    function approve(uint256 _proposalId) external;
    function execute(uint256 _proposalId) external;
    function fetchTokenId(bytes calldata _data) external pure returns (uint256 tokenId);
    
    function() external payable;
}

interface IPPTokenRegistry {
    event AddToken(address indexed token, address indexed owner, address indexed factory);
    event SetFactory(address factory);
    event SetLockerRegistry(address lockerRegistry);

    function tokenList(uint256 _index) external view returns (address);
    function isValid(address _tokenContract) external view returns (bool);
    function requireValidToken(address _token) external view;
    function addToken(address _privatePropertyToken) external;
    function getAllTokens() external view returns (address[] memory);
}

interface IPPRA {
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function reputationMinted(address _tokenContract, uint256 _tokenId) external view returns (bool);
    function ping() external pure returns (bytes32);
}

interface IPPToken {
    event SetBaseURI(string baseURI);
    event SetContractDataLink(string indexed dataLink);
    event SetLegalAgreementIpfsHash(bytes32 legalAgreementIpfsHash);
    event SetController(address indexed controller);
    event SetDetails(address indexed geoDataManager, uint256 indexed privatePropertyId);
    event SetContour(address indexed geoDataManager, uint256 indexed privatePropertyId);
    event SetHumanAddress(uint256 indexed tokenId, string humanAddress);
    event SetDataLink(uint256 indexed tokenId, string dataLink);
    event SetLedgerIdentifier(uint256 indexed tokenId, bytes32 ledgerIdentifier);
    event SetVertexRootHash(uint256 indexed tokenId, bytes32 vertexRootHash);
    event SetVertexStorageLink(uint256 indexed tokenId, string vertexStorageLink);
    event SetArea(uint256 indexed tokenId, uint256 area, AreaSource areaSource);
    event SetExtraData(bytes32 indexed key, bytes32 value);
    event SetPropertyExtraData(uint256 indexed propertyId, bytes32 indexed key, bytes32 value);
    event Mint(address indexed to, uint256 indexed privatePropertyId);
    event Burn(address indexed from, uint256 indexed privatePropertyId);

    enum AreaSource { USER_INPUT, CONTRACT }
    enum TokenType { NULL, LAND_PLOT, BUILDING, ROOM, PACKAGE }

    struct Property {
        uint256 setupStage;
        TokenType tokenType;
        uint256[] contour;
        int256 highestPoint;
        AreaSource areaSource;
        uint256 area;
        bytes32 ledgerIdentifier;
        string humanAddress;
        string dataLink;
        bytes32 vertexRootHash;
        string vertexStorageLink;
    }

    function setContractDataLink(string calldata _dataLink) external;
    function setLegalAgreementIpfsHash(bytes32 _legalAgreementIpfsHash) external;
    function setController(address payable _controller) external;
    function setDetails(
        uint256 _tokenId,
        TokenType _tokenType,
        AreaSource _areaSource,
        uint256 _area,
        bytes32 _ledgerIdentifier,
        string calldata _humanAddress,
        string calldata _dataLink
    ) external;
    function setContour(
        uint256 _tokenId,
        uint256[] calldata _contour,
        int256 _highestPoint
    ) external;
    function setArea(uint256 _tokenId, uint256 _area, AreaSource _areaSource) external;
    function setLedgerIdentifier(uint256 _tokenId, bytes32 _ledgerIdentifier) external;
    function setDataLink(uint256 _tokenId, string calldata _dataLink) external;
    function setVertexRootHash(uint256 _tokenId, bytes32 _vertexRootHash) external;
    function setVertexStorageLink(uint256 _tokenId, string calldata _vertexStorageLink) external;
    function incrementSetupStage(uint256 _tokenId) external;
    function mint(address _to) external returns (uint256);
    function burn(uint256 _tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function controller() external view returns (address payable);
    function tokensOfOwner(address _owner) external view returns (uint256[] memory);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function exists(uint256 _tokenId) external view returns (bool);
    function getType(uint256 _tokenId) external view returns (TokenType);
    function getContour(uint256 _tokenId) external view returns (uint256[] memory);
    function getContourLength(uint256 _tokenId) external view returns (uint256);
    function getHighestPoint(uint256 _tokenId) external view returns (int256);
    function getHumanAddress(uint256 _tokenId) external view returns (string memory);
    function getArea(uint256 _tokenId) external view returns (uint256);
    function getAreaSource(uint256 _tokenId) external view returns (AreaSource);
    function getLedgerIdentifier(uint256 _tokenId) external view returns (bytes32);
    function getDataLink(uint256 _tokenId) external view returns (string memory);
    function getVertexRootHash(uint256 _tokenId) external view returns (bytes32);
    function getVertexStorageLink(uint256 _tokenId) external view returns (string memory);
   