pragma solidity ^0.5.0;

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

pragma solidity ^0.5.6;

interface ILinkdropMaster {
    function verifyLinkdropSignerSignature(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature
    ) external view returns (bool);
    
    function verifyReceiverSignature(
        address linkKeyAddress,
        address receiverAddress,
        bytes calldata receiverSignature
    ) external view returns (bool);
    
    function checkClaimParams(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature,
        address receiverAddress,
        bytes calldata receiverSignature,
        uint256 feeAmount
    ) external view returns (bool);
    
    function claim(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature,
        address payable receiverAddress,
        bytes calldata receiverSignature,
        address payable feeReceiverAddress,
        uint256 feeAmount
    ) external returns (bool);
    
    function claimUnlock(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature,
        address payable receiverAddress,
        bytes calldata receiverSignature,
        address payable unlockReceiverAddress
    ) external returns (bool);
}

pragma solidity ^0.5.6;

interface ILinkdropProxy {
    function initialize(
        address factoryAddress,
        address payable linkdropMaster,
        uint256 masterCopy,
        uint256 chainId
    ) external returns (bool);
    
    function isLinkClaimed(address linkKeyAddress) external view returns (bool);
    function isLinkCanceled(address linkKeyAddress) external view returns (bool);
    function isPaused() external view returns (bool);
    function cancelLink(address linkKeyAddress) external returns (bool);
    function withdraw() external returns (bool);
    function pause() external returns (bool);
    function unpause() external returns (bool);
    function addSigningKey(address signingKeyAddress) external payable returns (bool);
    function removeSigningKey(address signingKeyAddress) external returns (bool);
    function destroy() external;
    function masterCopy() external view returns (uint);
    function () external payable;
}

pragma solidity ^0.5.6;

contract LinkdropProxyStorage {
    address public factoryAddress;
    address payable public linkdropMaster;
    uint public masterCopy;
    uint public chainId;
    mapping (address => bool) public signingKeys;
    mapping (address => address) public claimedLinks;
    mapping (address => bool) internal canceledLinks;
    bool public initialized;
    bool internal paused;
    
    event Canceled(address linkKeyAddress);
    event Claimed(address indexed linkKeyAddress, uint256 weiAmount, address indexed tokenAddress, uint256 tokenAmount, address receiverAddress);
    event ClaimedUnlock(address indexed linkKeyAddress, uint256 weiAmount, address indexed tokenAddress, uint256 tokenAmount, address receiverAddress, address indexed unlockReceiverAddress);
    event ClaimedERC721(address indexed linkKeyAddress, uint256 weiAmount, address indexed nftAddress, uint256 tokenId, address receiverAddress);
    event Paused();
    event Unpaused();
    event AddedSigningKey(address signingKeyAddress);
    event RemovedSigningKey(address signingKeyAddress);
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.6;

contract LinkdropProxy is ILinkdropProxy, LinkdropProxyStorage {
    /**
     * @dev Function called only once to set factory, linkdrop master, contract master copy and chain id
     * @param _factoryAddress Owner address
     * @param _linkdropMaster Address corresponding to master key
     * @param _masterCopy Contract master copy
     * @param _chainId Network id
     */
    function initialize(
        address _factoryAddress,
        address payable _linkdropMaster,
        uint _masterCopy,
        uint _chainId
    ) public returns (bool) {
        require(!initialized, "LINKDROP_PROXY_CONTRACT_ALREADY_INITIALIZED");
        factoryAddress = _factoryAddress;
        linkdropMaster = _linkdropMaster;
        signingKeys[linkdropMaster] = true;
        masterCopy = _masterCopy;
        chainId = _chainId;
        initialized = true;
        return true;
    }
    
    modifier onlyLinkdropMaster() {
        require(msg.sender == linkdropMaster, "ONLY_LINKDROP_MASTER");
        _;
    }
    
    modifier onlyLinkdropMasterOrFactory() {
        require (msg.sender == linkdropMaster || msg.sender == factoryAddress, "ONLY_LINKDROP_MASTER_OR_FACTORY");
        _;
    }
    
    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "ONLY_FACTORY");
        _;
    }
    
    modifier whenNotPaused() {
        require(!isPaused(), "LINKDROP_PROXY_CONTRACT_PAUSED");
        _;
    }
    
    /**
     * @dev Indicates whether a link is claimed or not
     * @param linkKeyAddress Address corresponding to link key
     * @return True if claimed
     */
    function isLinkClaimed(address linkKeyAddress) public view returns (bool) {
        return claimedLinks[linkKeyAddress] != address(0);
    }
    
    /**
     * @dev Indicates whether a link is canceled or not
     * @param linkKeyAddress Address corresponding to link key
     * @return True if canceled
     */
    function isLinkCanceled(address linkKeyAddress) public view returns (bool) {
        return canceledLinks[linkKeyAddress];
    }
    
    /**
     * @dev Indicates whether a contract is paused or not
     * @return True if paused
     */
    function isPaused() public view returns (bool) {
        return paused;
    }
    
    /**
     * @dev Function to cancel a link, can only be called by linkdrop master
     * @param linkKeyAddress Address corresponding to link key
     * @return True if success
     */
    function cancelLink(address linkKeyAddress) external onlyLinkdropMaster returns (bool) {
        require(!isLinkClaimed(linkKeyAddress), "LINK_CLAIMED");
        canceledLinks[linkKeyAddress] = true;
        emit Canceled(linkKeyAddress);
        return true;
    }
    
    /**
     * @dev Function to withdraw eth to linkdrop master, can only be called by linkdrop master
     * @return True if success
     */
    function withdraw() external onlyLinkdropMaster returns (bool) {
        linkdropMaster.transfer(address(this).balance);
        return true;
    }
    
    /**
     * @dev Function to pause contract, can only be called by linkdrop master
     * @return True if success
     */
    function pause() external onlyLinkdropMaster whenNotPaused returns (bool) {
        paused = true;
        emit Paused();
        return true;
    }
    
    /**
     * @dev Function to unpause contract, can only be called by linkdrop master
     * @return True if success
     */
    function unpause() external onlyLinkdropMaster returns (bool) {
        require(isPaused(), "LINKDROP_CONTRACT_ALREADY_UNPAUSED");
        paused = false;
        emit Unpaused();
        return true;
    }
    
    /**
     * @dev Function to add new signing key, can only be called by linkdrop master or factory (factory contract)
     * @param signingKeyAddress Address corresponding to signing key
     * @return True if success
     */
    function addSigningKey(address signingKeyAddress) external payable onlyLinkdropMasterOrFactory returns (bool) {
        require(signingKeyAddress != address(0), "INVALID_LINKDROP_SIGNER_ADDRESS");
        signingKeys[signingKeyAddress] = true;
        return true;
    }
    
    /**
     * @dev Function to remove signing key, can only be called by linkdrop master
     * @param signingKeyAddress Address corresponding to signing key
     * @return True if success
     */
    function removeSigningKey(address signingKeyAddress) external onlyLinkdropMaster returns (bool) {
        require(signingKeyAddress != address(0), "INVALID_LINKDROP_SIGNER_ADDRESS");
        signingKeys[signingKeyAddress] = false;
        return true;
    }
    
    /**
     * @dev Function to destroy this contract, can only be called by factory or linkdrop master
     * Withdraws all the remaining ETH to linkdrop master
     */
    function destroy() external onlyLinkdropMasterOrFactory {
        selfdestruct(linkdropMaster);
    }
    
    /**
     * @dev Function for other contracts to be able to fetch the mastercopy address
     * @return Master copy address
     */
    function masterCopy() external view returns (uint) {
        return masterCopy;
    }
    
    /**
     * @dev Fallback function to accept ETH
     */
    function () external payable {}
}

pragma solidity ^0.5.6;

interface IUnlockReceiver {
    function receiveUnlock(address receiverAddress) external payable;
}

pragma solidity ^0.5.6;

interface IFeeManager {
    function getFee(address proxyAddress) external view returns (uint);
}

pragma solidity ^0.5.6;

contract LinkdropMaster is ILinkdropMaster, LinkdropProxy {
    using SafeMath for uint;
    
    /**
     * @dev Function to verify linkdrop signer's signature
     * @param weiAmount Amount of wei to be claimed
     * @param tokenAddress Token address
     * @param tokenAmount Amount of tokens to be claimed (in atomic units)
     * @param expirationTime Unix timestamp of link expiration time
     * @param linkKeyAddress Address corresponding to link key
     * @param linkdropSignerSignature ECDSA signature of linkdrop signer
     * @return True if signed with linkdrop signer's private key
     */
    function verifyLinkdropSignerSignature(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes memory linkdropSignerSignature
    ) public view returns (bool) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    weiAmount,
                    tokenAddress,
                    tokenAmount,
                    expirationTime,
                    masterCopy,
                    chainId,
                    linkKeyAddress,
                    address(this)
                )
            )
        );
        address signer = ECDSA.recover(messageHash, linkdropSignerSignature);
        return signingKeys[signer];
    }
    
    /**
     * @dev Function to verify linkdrop receiver's signature
     * @param linkKeyAddress Address corresponding to link key
     * @param receiverAddress Address of linkdrop receiver
     * @param receiverSignature ECDSA signature of linkdrop receiver
     * @return True if signed with link key
     */
    function verifyReceiverSignature(
        address linkKeyAddress,
        address receiverAddress,
        bytes memory receiverSignature
    ) public view returns (bool) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(receiverAddress)));
        address signer = ECDSA.recover(messageHash, receiverSignature);
        return signer == linkKeyAddress;
    }
    
    /**
     * @dev Function to verify claim params and make sure the link is not claimed or canceled
     * @param weiAmount Amount of wei to be claimed
     * @param tokenAddress Token address
     * @param tokenAmount Amount of tokens to be claimed (in atomic units)
     * @param expirationTime Unix timestamp of link expiration time
     * @param linkKeyAddress Address corresponding to link key
     * @param linkdropSignerSignature ECDSA signature of linkdrop signer
     * @param receiverAddress Address of linkdrop receiver
     * @param receiverSignature ECDSA signature of linkdrop receiver
     * @param feeAmount Amount of fee to send to fee receiver
     * @return True if success
     */
    function checkClaimParams(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes memory linkdropSignerSignature,
        address receiverAddress,
        bytes memory receiverSignature,
        uint256 feeAmount
    ) public view whenNotPaused returns (bool) {
        if (tokenAmount > 0) {
            require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        }
        require(isLinkClaimed(linkKeyAddress) == false, "LINK_CLAIMED");
        require(isLinkCanceled(linkKeyAddress) == false, "LINK_CANCELED");
        require(expirationTime >= now, "LINK_EXPIRED");
        require(address(this).balance >= weiAmount.add(feeAmount), "INSUFFICIENT_ETHERS");
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
                linkKeyAddress,
                linkdropSignerSignature
            ),
            "INVALID_LINKDROP_SIGNER_SIGNATURE"
        );
        require(
            verifyReceiverSignature(linkKeyAddress, receiverAddress, receiverSignature),
            "INVALID_RECEIVER_SIGNATURE"
        );
        return true;
    }
    
    /**
     * @dev Function to claim ETH and/or ERC20 tokens. Can only be called when contract is not paused
     * @param weiAmount Amount of wei to be claimed
     * @param tokenAddress Token address
     * @param tokenAmount Amount of tokens to be claimed (in atomic units)
     * @param expirationTime Unix timestamp of link expiration time
     * @param linkKeyAddress Address corresponding to link key
     * @param linkdropSignerSignature ECDSA signature of linkdrop signer
     * @param receiverAddress Address of linkdrop receiver
     * @param receiverSignature ECDSA signature of linkdrop receiver
     * @param feeReceiverAddress Address to send fees to
     * @param feeAmount Amount of fee to send to fee receiver
     * @return True if success
     */
    function claim(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature,
        address payable receiverAddress,
        bytes calldata receiverSignature,
        address payable feeReceiverAddress,
        uint256 feeAmount
    ) external onlyFactory whenNotPaused returns (bool) {
        require(
            checkClaimParams(
                weiAmount,
                tokenAddress,
                tokenAmount,
                expirationTime,
                linkKeyAddress,
                linkdropSignerSignature,
                receiverAddress,
                receiverSignature,
                feeAmount
            ),
            "INVALID_CLAIM_PARAMS"
        );
        claimedLinks[linkKeyAddress] = receiverAddress;
        require(transferFunds(weiAmount, tokenAddress, tokenAmount, receiverAddress, feeReceiverAddress, feeAmount), "TRANSFER_FAILED");
        emit Claimed(linkKeyAddress, weiAmount, tokenAddress, tokenAmount, receiverAddress);
        return true;
    }
    
    /**
     * @dev Internal function to transfer ethers and/or ERC20 tokens
     * @param weiAmount Amount of wei to be claimed
     * @param tokenAddress Token address
     * @param tokenAmount Amount of tokens to be claimed (in atomic units)
     * @param receiverAddress Address to transfer funds to
     * @param feeReceiverAddress Address to transfer fees to
     * @param feeAmount Amount of fee to send to fee receiver
     * @return True if success
     */
    function transferFunds(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        address payable receiverAddress,
        address payable feeReceiverAddress,
        uint256 feeAmount
    ) internal returns (bool) {
        if (feeAmount > 0) {
            feeReceiverAddress.transfer(feeAmount);
        }
        if (weiAmount > 0) {
            receiverAddress.transfer(weiAmount);
        }
        if (tokenAmount > 0) {
            IERC20(tokenAddress).transferFrom(linkdropMaster, receiverAddress, tokenAmount);
        }
        return true;
    }
    
    function claimUnlock(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature,
        address payable receiverAddress,
        bytes calldata receiverSignature,
        address payable unlockReceiverAddress
    ) external onlyFactory whenNotPaused returns (bool) {
        require(
            checkClaimParams(
                weiAmount,
                tokenAddress,
                tokenAmount,
                expirationTime,
                linkKeyAddress,
                linkdropSignerSignature,
                receiverAddress,
                receiverSignature,
                IFeeManager(factoryAddress).getFee(address(this))
            ),
            "INVALID_CLAIM_PARAMS"
        );
        claimedLinks[linkKeyAddress] = receiverAddress;
        require(
            transferFundsUnlock(weiAmount, tokenAddress, tokenAmount, receiverAddress, unlockReceiverAddress),
            "TRANSFER_FAILED"
        );
        emit ClaimedUnlock(linkKeyAddress, weiAmount, tokenAddress, tokenAmount, receiverAddress, unlockReceiverAddress);
        return true;
    }
    
    function transferFundsUnlock(
        uint256 weiAmount,
        address tokenAddress,
        uint256 tokenAmount,
        address payable receiverAddress,
        address payable unlockReceiverAddress
    ) internal returns (bool) {
        tx.origin.transfer(IFeeManager(factoryAddress).getFee(address(this)));
        if (weiAmount > 0) {
            IUnlockReceiver(unlockReceiverAddress).receiveUnlock.value(weiAmount)(receiverAddress);
        }
        if (tokenAmount > 0) {
            IERC20(tokenAddress).transferFrom(linkdropMaster, receiverAddress, tokenAmount);
        }
        return true;
    }
}

pragma solidity ^0.5.6;

interface ILinkdropMasterERC721 {
    function verifyLinkdropSignerSignature(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature
    ) external view returns (bool);
    
    function verifyReceiverSignature(
        address linkKeyAddress,
        address receiverAddress,
        bytes calldata receiverSignature
    ) external view returns (bool);
    
    function checkClaimParams(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature,
        address receiverAddress,
        bytes calldata receiverSignature,
        uint256 feeAmount
    ) external view returns (bool);
    
    function claim(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature,
        address payable receiverAddress,
        bytes calldata receiverSignature,
        address payable feeReceiverAddress,
        uint256 feeAmount
    ) external returns (bool);
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https:
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https:
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);
    
    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);
    
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.6;

contract LinkdropMasterERC721 is ILinkdropMasterERC721, LinkdropProxy {
    using SafeMath for uint;
    
    /**
     * @dev Function to verify linkdrop signer's signature
     * @param weiAmount Amount of wei to be claimed
     * @param nftAddress NFT address
     * @param tokenId Token id to be claimed
     * @param expirationTime Unix timestamp of link expiration time
     * @param linkKeyAddress Address corresponding to link key
     * @param linkdropSignerSignature ECDSA signature of linkdrop signer
     * @return True if signed with linkdrop signer's private key
     */
    function verifyLinkdropSignerSignature(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes memory linkdropSignerSignature
    ) public view returns (bool) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    weiAmount,
                    nftAddress,
                    tokenId,
                    expirationTime,
                    masterCopy,
                    chainId,
                    linkKeyAddress,
                    address(this)
                )
            )
        );
        address signer = ECDSA.recover(messageHash, linkdropSignerSignature);
        return signingKeys[signer];
    }
    
    /**
     * @dev Function to verify linkdrop receiver's signature
     * @param linkKeyAddress Address corresponding to link key
     * @param receiverAddress Address of linkdrop receiver
     * @param receiverSignature ECDSA signature of linkdrop receiver
     * @return True if signed with link key
     */
    function verifyReceiverSignature(
        address linkKeyAddress,
        address receiverAddress,
        bytes memory receiverSignature
    ) public view returns (bool) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(receiverAddress)));
        address signer = ECDSA.recover(messageHash, receiverSignature);
        return signer == linkKeyAddress;
    }
    
    /**
     * @dev Function to verify claim params and make sure the link is not claimed or canceled
     * @param weiAmount Amount of wei to be claimed
     * @param nftAddress NFT address
     * @param tokenId Token id to be claimed
     * @param expirationTime Unix timestamp of link expiration time
     * @param linkKeyAddress Address corresponding to link key
     * @param linkdropSignerSignature ECDSA signature of linkdrop signer
     * @param receiverAddress Address of linkdrop receiver
     * @param receiverSignature ECDSA signature of linkdrop receiver
     * @param feeAmount Amount of fee to send to fee receiver
     * @return True if success
     */
    function checkClaimParams(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes memory linkdropSignerSignature,
        address receiverAddress,
        bytes memory receiverSignature,
        uint256 feeAmount
    ) public view whenNotPaused returns (bool) {
        require(nftAddress != address(0), "INVALID_NFT_ADDRESS");
        require(isLinkClaimed(linkKeyAddress) == false, "LINK_CLAIMED");
        require(isLinkCanceled(linkKeyAddress) == false, "LINK_CANCELED");
        require(expirationTime >= now, "LINK_EXPIRED");
        require(address(this).balance >= weiAmount.add(feeAmount), "INSUFFICIENT_ETHERS");
        require(IERC721(nftAddress).ownerOf(tokenId) == linkdropMaster, "LINKDROP_MASTER_DOES_NOT_OWN_TOKEN_ID");
        require(IERC721(nftAddress).isApprovedForAll(linkdropMaster, address(this)), "INSUFFICIENT_ALLOWANCE");
        require(
            verifyLinkdropSignerSignature(
                weiAmount,
                nftAddress,
                tokenId,
                expirationTime,
                linkKeyAddress,
                linkdropSignerSignature
            ),
            "INVALID_LINKDROP_SIGNER_SIGNATURE"
        );
        require(
            verifyReceiverSignature(linkKeyAddress, receiverAddress, receiverSignature),
            "INVALID_RECEIVER_SIGNATURE"
        );
        return true;
    }
    
    /**
     * @dev Function to claim ETH and/or ERC721 token. Can only be called when contract is not paused
     * @param weiAmount Amount of wei to be claimed
     * @param nftAddress NFT address
     * @param tokenId Token id to be claimed
     * @param expirationTime Unix timestamp of link expiration time
     * @param linkKeyAddress Address corresponding to link key
     * @param linkdropSignerSignature ECDSA signature of linkdrop signer
     * @param receiverAddress Address of linkdrop receiver
     * @param receiverSignature ECDSA signature of linkdrop receiver
     * @param feeReceiverAddress Address to send fees to
     * @param feeAmount Amount of fee to send to fee receiver
     * @return True if success
     */
    function claim(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        uint256 expirationTime,
        address linkKeyAddress,
        bytes calldata linkdropSignerSignature,
        address payable receiverAddress,
        bytes calldata receiverSignature,
        address payable feeReceiverAddress,
        uint256 feeAmount
    ) external onlyFactory whenNotPaused returns (bool) {
        require(
            checkClaimParams(
                weiAmount,
                nftAddress,
                tokenId,
                expirationTime,
                linkKeyAddress,
                linkdropSignerSignature,
                receiverAddress,
                receiverSignature,
                feeAmount
            ),
            "INVALID_CLAIM_PARAMS"
        );
        claimedLinks[linkKeyAddress] = receiverAddress;
        require(transferFunds(weiAmount, nftAddress, tokenId, receiverAddress, feeReceiverAddress, feeAmount), "TRANSFER_FAILED");
        emit ClaimedERC721(linkKeyAddress, weiAmount, nftAddress, tokenId, receiverAddress);
        return true;
    }
    
    /**
     * @dev Internal function to transfer ethers and/or ERC721 tokens
     * @param weiAmount Amount of wei to be claimed
     * @param nftAddress NFT address
     * @param tokenId Amount of tokens to be claimed (in atomic units)
     * @param receiverAddress Address to transfer funds to
     * @param feeReceiverAddress Address to transfer fees to
     * @param feeAmount Amount of fee to send to fee receiver
     * @return True if success
     */
    function transferFunds(
        uint256 weiAmount,
        address nftAddress,
        uint256 tokenId,
        address payable receiverAddress,
        address payable feeReceiverAddress,
        uint256 feeAmount
    ) internal returns (bool) {
        feeReceiverAddress.transfer(feeAmount);
        if (weiAmount > 0) {
            receiverAddress.transfer(weiAmount);
        }
        IERC721(nftAddress).safeTransferFrom(linkdropMaster, receiverAddress, tokenId);
        return true;
    }
}

pragma solidity ^0.5.6;

contract LinkdropMasterCombined is LinkdropMaster, LinkdropMasterERC721 {}
