```solidity
pragma solidity ^0.5.6;

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

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ILinkdropERC20 {
    function verifyLinkdropSignerSignature(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKey,
        bytes memory linkdropSignerSignature
    ) external view returns (bool);
    
    function verifyReceiverSignature(
        address linkKey,
        address receiver,
        bytes memory receiverSignature
    ) external view returns (bool);
    
    function verifyClaimParams(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKey,
        bytes memory linkdropSignerSignature,
        address receiver,
        bytes memory receiverSignature,
        uint256 fee
    ) external view returns (bool);
    
    function claim(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKey,
        bytes calldata linkdropSignerSignature,
        address payable receiver,
        bytes calldata receiverSignature,
        address payable feeReceiver,
        uint256 fee
    ) external returns (bool);
    
    function claimUnlock(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKey,
        bytes calldata linkdropSignerSignature,
        address payable receiver,
        bytes calldata receiverSignature,
        address payable unlockReceiver
    ) external returns (bool);
}

interface ILinkdropERC721 {
    function verifyLinkdropSignerSignatureERC721(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKey,
        bytes memory linkdropSignerSignature
    ) external view returns (bool);
    
    function verifyReceiverSignatureERC721(
        address linkKey,
        address receiver,
        bytes memory receiverSignature
    ) external view returns (bool);
    
    function verifyClaimParamsERC721(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKey,
        bytes memory linkdropSignerSignature,
        address receiver,
        bytes memory receiverSignature,
        uint256 fee
    ) external view returns (bool);
    
    function claimERC721(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKey,
        bytes calldata linkdropSignerSignature,
        address payable receiver,
        bytes calldata receiverSignature,
        address payable feeReceiver,
        uint256 fee
    ) external returns (bool);
}

interface ILinkdropCommon {
    function initialize(
        address owner,
        address payable linkdropMaster,
        uint256 campaignId,
        uint256 chainId
    ) external returns (bool);
    
    function isClaimedLink(address linkKey) external view returns (bool);
    function isCanceledLink(address linkKey) external view returns (bool);
    function isPaused() external view returns (bool);
    function cancel(address linkKey) external returns (bool);
    function withdraw() external returns (bool);
    function pause() external returns (bool);
    function unpause() external returns (bool);
    function addSigningKey(address signingKey) external payable returns (bool);
    function removeSigningKey(address signingKey) external returns (bool);
    function destroy() external;
    function getCampaignId() external view returns (uint256);
    function () external payable;
}

interface IFeeCalculator {
    function calculateFee(address contractAddress) external view returns (uint256);
}

interface IUnlock {
    function unlock(address receiver) external payable;
}

library ECDSA {
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) {
            return (address(0));
        }
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        
        if (v != 27 && v != 28) {
            return address(0);
        }
        
        return ecrecover(hash, v, r, s);
    }
    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract LinkdropBase {
    address public owner;
    address payable public linkdropMaster;
    uint256 public campaignId;
    uint256 public chainId;
    
    mapping(address => bool) public isSigningKey;
    mapping(address => address) public claimedTo;
    mapping(address => bool) internal canceledLinks;
    
    bool public initialized;
    bool internal paused;
    
    event Canceled(address linkKey);
    event Claimed(
        address indexed linkKey,
        uint256 weiAmount,
        address indexed tokenAddress,
        uint256 tokenAmount,
        address receiver
    );
    event ClaimedUnlock(
        address indexed linkKey,
        uint256 weiAmount,
        address indexed tokenAddress,
        uint256 tokenAmount,
        address receiver,
        address indexed unlockReceiver
    );
    event ClaimedERC721(
        address indexed linkKey,
        uint256 weiAmount,
        address indexed nftAddress,
        uint256 tokenId,
        address receiver
    );
    event Paused();
    event Unpaused();
    event AddedSigningKey(address signingKey);
    event RemovedSigningKey(address signingKey);
}

contract LinkdropCommon is ILinkdropCommon, LinkdropBase {
    using SafeMath for uint256;
    
    function initialize(
        address _owner,
        address payable _linkdropMaster,
        uint256 _campaignId,
        uint256 _chainId
    ) public returns (bool) {
        require(!initialized, "LINKDROP_PROXY_CONTRACT_ALREADY_INITIALIZED");
        
        owner = _owner;
        linkdropMaster = _linkdropMaster;
        isSigningKey[_linkdropMaster] = true;
        campaignId = _campaignId;
        chainId = _chainId;
        
        initialized = true;
        return true;
    }
    
    modifier onlyLinkdropMaster() {
        require(msg.sender == linkdropMaster, "ONLY_LINKDROP_MASTER");
        _;
    }
    
    modifier onlyLinkdropMasterOrFactory() {
        require(
            msg.sender == linkdropMaster || msg.sender == owner,
            "ONLY_LINKDROP_MASTER_OR_FACTORY"
        );
        _;
    }
    
    modifier onlyFactory() {
        require(msg.sender == owner, "ONLY_FACTORY");
        _;
    }
    
    modifier whenNotPaused() {
        require(!isPaused(), "LINKDROP_PROXY_CONTRACT_PAUSED");
        _;
    }
    
    function isClaimedLink(address linkKey) public view returns (bool) {
        return claimedTo[linkKey] != address(0);
    }
    
    function isCanceledLink(address linkKey) public view returns (bool) {
        return canceledLinks[linkKey];
    }
    
    function isPaused() public view returns (bool) {
        return paused;
    }
    
    function cancel(address linkKey) external onlyLinkdropMaster returns (bool) {
        require(!isClaimedLink(linkKey), "LINK_CLAIMED");
        canceledLinks[linkKey] = true;
        emit Canceled(linkKey);
        return true;
    }
    
    function withdraw() external onlyLinkdropMaster returns (bool) {
        linkdropMaster.transfer(address(this).balance);
        return true;
    }
    
    function pause() external onlyLinkdropMaster whenNotPaused returns (bool) {
        paused = true;
        emit Paused();
        return true;
    }
    
    function unpause() external onlyLinkdropMaster returns (bool) {
        require(isPaused(), "LINKDROP_CONTRACT_ALREADY_UNPAUSED");
        paused = false;
        emit Unpaused();
        return true;
    }
    
    function addSigningKey(address signingKey) external payable onlyLinkdropMasterOrFactory returns (bool) {
        require(signingKey != address(0), "INVALID_LINKDROP_SIGNER_ADDRESS");
        isSigningKey[signingKey] = true;
        emit AddedSigningKey(signingKey);
        return true;
    }
    
    function removeSigningKey(address signingKey) external onlyLinkdropMaster returns (bool) {
        require(signingKey != address(0), "INVALID_LINKDROP_SIGNER_ADDRESS");
        isSigningKey[signingKey] = false;
        emit RemovedSigningKey(signingKey);
        return true;
    }
    
    function destroy() external onlyLinkdropMasterOrFactory {
        selfdestruct(linkdropMaster);
    }
    
    function getCampaignId() external view returns (uint256) {
        return campaignId;
    }
    
    function () external payable {}
}

contract LinkdropERC20 is ILinkdropERC20, LinkdropCommon {
    using SafeMath for uint256;
    
    function verifyLinkdropSignerSignature(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKey,
        bytes memory linkdropSignerSignature
    ) public view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    weiAmount,
                    tokenAddress,
                    tokenAmount,
                    expirationTime,
                    campaignId,
                    chainId,
                    linkKey,
                    address(this)
                )
            )
        );
        
        address signer = ECDSA.recover(hash, linkdropSignerSignature);
        return isSigningKey[signer];
    }
    
    function verifyReceiverSignature(
        address linkKey,
        address receiver,
        bytes memory receiverSignature
    ) public view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(receiver)));
        address signer = ECDSA.recover(hash, receiverSignature);
        return signer == linkKey;
    }
    
    function verifyClaimParams(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKey,
        bytes memory linkdropSignerSignature,
        address receiver,
        bytes memory receiverSignature,
        uint256 fee
    ) public view whenNotPaused returns (bool) {
        if (tokenAmount > 0) {
            require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        }
        
        require(!isClaimedLink(linkKey), "LINK_CLAIMED");
        require(!isCanceledLink(linkKey), "LINK_CANCELED");
        require(expirationTime >= now, "LINK_EXPIRED");
        require(address(this).balance >= weiAmount.add(fee), "INSUFFICIENT_ETHERS");
        
        if (tokenAddress != address(0)) {
            require(
                IERC20(tokenAddress).balanceOf(linkdropMaster) >= tokenAmount,
                "INSUFFICIENT_TOKENS"
            );
            require(
                IERC20(tokenAddress).allowance(linkdropMaster, address(this)) >= tokenAmount,
                "INSUFFICIENT_ALLOWANCE"
            );
        }
        
        require(
            verifyLinkdropSignerSignature(
                weiAmount,
                tokenAddress,
                tokenAmount,
                expirationTime,
                linkKey,
                linkdropSignerSignature
            ),
            "INVALID_LINKDROP_SIGNER_SIGNATURE"
        );
        
        require(
            verifyReceiverSignature(linkKey, receiver, receiverSignature),
            "INVALID_RECEIVER_SIGNATURE"
        );
        
        return true;
    }
    
    function claim(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKey,
        bytes calldata linkdropSignerSignature,
        address payable receiver,
        bytes calldata receiverSignature,
        address payable feeReceiver,
        uint256 fee
    ) external onlyFactory whenNotPaused returns (bool) {
        require(
            verifyClaimParams(
                weiAmount,
                tokenAddress,
                tokenAmount,
                expirationTime,
                linkKey,
                linkdropSignerSignature,
                receiver,
                receiverSignature,
                fee
            ),
            "INVALID_CLAIM_PARAMS"
        );
        
        claimedTo[linkKey] = receiver;
        
        require(
            _transfer(weiAmount, tokenAddress, tokenAmount, receiver, feeReceiver, fee),
            "TRANSFER_FAILED"
        );
        
        emit Claimed(linkKey, weiAmount, tokenAddress, tokenAmount, receiver);
        return true;
    }
    
    function _transfer(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        address payable receiver,
        address payable feeReceiver,
        uint256 fee
    ) internal returns (bool) {
        if (fee > 0) {
            feeReceiver.transfer(fee);
        }
        
        if (weiAmount > 0) {
            receiver.transfer(weiAmount);
        }
        
        if (tokenAmount > 0) {
            IERC20(tokenAddress).transferFrom(linkdropMaster, receiver, tokenAmount);
        }
        
        return true;
    }
    
    function claimUnlock(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKey,
        bytes calldata linkdropSignerSignature,
        address payable receiver,
        bytes calldata receiverSignature,
        address payable unlockReceiver
    ) external onlyFactory whenNotPaused returns (bool) {
        uint256 fee = IFeeCalculator(owner).calculateFee(address(this));
        
        require(
            verifyClaimParams(
                weiAmount,
                tokenAddress,
                tokenAmount,
                expirationTime,
                linkKey,
                linkdropSignerSignature,
                receiver,
                receiverSignature,
                fee
            ),
            "INVALID_CLAIM_PARAMS"
        );
        
        claimedTo[linkKey] = receiver;
        
        require(
            _transferUnlock(weiAmount, tokenAddress, tokenAmount, receiver, unlockReceiver),
            "TRANSFER_FAILED"
        );
        
        emit ClaimedUnlock(linkKey, weiAmount, tokenAddress, tokenAmount, receiver, unlockReceiver);
        return true;
    }
    
    function _transferUnlock(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        address payable receiver,
        address payable unlockReceiver
    ) internal returns (bool) {
        uint256 fee = IFeeCalculator(owner).calculateFee(address(this));
        tx.origin.transfer(fee);
        
        if (weiAmount > 0) {
            IUnlock(unlockReceiver).unlock.value(weiAmount)(receiver);
        }
        
        if (tokenAmount > 0) {
            IERC20(tokenAddress).transferFrom(linkdropMaster, receiver, tokenAmount);
        }
        
        return true;
    }
}

contract LinkdropERC721 is ILinkdropERC721, LinkdropCommon {
    using SafeMath for uint256;
    
    function verifyLinkdropSignerSignatureERC721(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKey,
        bytes memory linkdropSignerSignature
    ) public view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            ke