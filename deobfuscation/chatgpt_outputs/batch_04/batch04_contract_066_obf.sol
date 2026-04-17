```solidity
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

interface ILinkdropVerifier {
    function verifyLinkdropSignerSignature(
        uint amount,
        address tokenAddress,
        uint tokenAmount,
        uint expiration,
        address linkKey,
        bytes calldata signature
    ) external view returns (bool);

    function verifyReceiverSignature(
        address linkKey,
        address receiver,
        bytes calldata signature
    ) external view returns (bool);

    function checkClaimParams(
        uint amount,
        address tokenAddress,
        uint tokenAmount,
        uint expiration,
        address linkKey,
        bytes calldata linkdropSignerSignature,
        address receiver,
        bytes calldata receiverSignature,
        uint fee
    ) external view returns (bool);

    function claim(
        uint amount,
        address tokenAddress,
        uint tokenAmount,
        uint expiration,
        address linkKey,
        bytes calldata linkdropSignerSignature,
        address payable receiver,
        bytes calldata receiverSignature,
        address payable feeReceiver,
        uint fee
    ) external returns (bool);
}

pragma solidity ^0.5.6;

interface ILinkdropMastercopy {
    function initialize(
        address owner,
        address payable linkdropMaster,
        uint masterCopyVersion,
        uint chainId
    ) external returns (bool);

    function isClaimedLink(address linkKey) external view returns (bool);
    function isCanceledLink(address linkKey) external view returns (bool);
    function isPaused() external view returns (bool);
    function cancelLink(address linkKey) external returns (bool);
    function withdrawEth() external returns (bool);
    function pause() external returns (bool);
    function unpause() external returns (bool);
    function addSigningKey(address signingKey) external payable returns (bool);
    function removeSigningKey(address signingKey) external returns (bool);
    function destroy() external;
    function getMasterCopyVersion() external view returns (uint);
    function () external payable;
}

pragma solidity ^0.5.6;

contract LinkdropMastercopy is ILinkdropMastercopy {
    address public owner;
    address payable public linkdropMaster;
    uint public masterCopyVersion;
    uint public chainId;
    mapping(address => bool) public signingKeys;
    mapping(address => address) public claimedLinks;
    mapping(address => bool) internal canceledLinks;
    bool public initialized;
    bool internal paused;

    event Canceled(address linkKey);
    event Claimed(address indexed linkKey, uint amount, address indexed tokenAddress, uint tokenAmount, address receiver);
    event ClaimedUnlock(address indexed linkKey, uint amount, address indexed tokenAddress, uint tokenAmount, address receiver, address indexed feeReceiver);
    event ClaimedERC721(address indexed linkKey, uint amount, address indexed nftAddress, uint tokenId, address receiver);
    event Paused();
    event Unpaused();
    event AddedSigningKey(address signingKey);
    event RemovedSigningKey(address signingKey);

    function initialize(
        address _owner,
        address payable _linkdropMaster,
        uint _masterCopyVersion,
        uint _chainId
    ) public returns (bool) {
        require(!initialized, "LINKDROP_PROXY_CONTRACT_ALREADY_INITIALIZED");
        owner = _owner;
        linkdropMaster = _linkdropMaster;
        signingKeys[linkdropMaster] = true;
        masterCopyVersion = _masterCopyVersion;
        chainId = _chainId;
        initialized = true;
        return true;
    }

    modifier onlyLinkdropMaster() {
        require(msg.sender == linkdropMaster, "ONLY_LINKDROP_MASTER");
        _;
    }

    modifier onlyLinkdropMasterOrFactory() {
        require(msg.sender == linkdropMaster || msg.sender == owner, "ONLY_LINKDROP_MASTER_OR_FACTORY");
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
        return claimedLinks[linkKey] != address(0);
    }

    function isCanceledLink(address linkKey) public view returns (bool) {
        return canceledLinks[linkKey];
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    function cancelLink(address linkKey) external onlyLinkdropMaster returns (bool) {
        require(!isClaimedLink(linkKey), "LINK_CLAIMED");
        canceledLinks[linkKey] = true;
        emit Canceled(linkKey);
        return true;
    }

    function withdrawEth() external onlyLinkdropMaster returns (bool) {
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
        signingKeys[signingKey] = true;
        return true;
    }

    function removeSigningKey(address signingKey) external onlyLinkdropMaster returns (bool) {
        require(signingKey != address(0), "INVALID_LINKDROP_SIGNER_ADDRESS");
        signingKeys[signingKey] = false;
        return true;
    }

    function destroy() external onlyLinkdropMasterOrFactory {
        selfdestruct(linkdropMaster);
    }

    function getMasterCopyVersion() external view returns (uint) {
        return masterCopyVersion;
    }

    function () external payable {}
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

contract LinkdropVerifier is ILinkdropVerifier, LinkdropMastercopy {
    using SafeMath for uint;

    function verifyLinkdropSignerSignature(
        uint amount,
        address tokenAddress,
        uint tokenAmount,
        uint expiration,
        address linkKey,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    amount,
                    tokenAddress,
                    tokenAmount,
                    expiration,
                    masterCopyVersion,
                    chainId,
                    linkKey,
                    address(this)
                )
            )
        );
        address signer = ECDSA.recover(hash, signature);
        return signingKeys[signer];
    }

    function verifyReceiverSignature(
        address linkKey,
        address receiver,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(receiver)));
        address signer = ECDSA.recover(hash, signature);
        return signer == linkKey;
    }

    function checkClaimParams(
        uint amount,
        address tokenAddress,
        uint tokenAmount,
        uint expiration,
        address linkKey,
        bytes memory linkdropSignerSignature,
        address receiver,
        bytes memory receiverSignature,
        uint fee
    ) public view whenNotPaused returns (bool) {
        if (tokenAmount > 0) {
            require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        }
        require(!isClaimedLink(linkKey), "LINK_CLAIMED");
        require(!isCanceledLink(linkKey), "LINK_CANCELED");
        require(expiration >= now, "LINK_EXPIRED");
        require(address(this).balance >= amount.add(fee), "INSUFFICIENT_ETHERS");
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
                amount,
                tokenAddress,
                tokenAmount,
                expiration,
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
        uint amount,
        address tokenAddress,
        uint tokenAmount,
        uint expiration,
        address linkKey,
        bytes calldata linkdropSignerSignature,
        address payable receiver,
        bytes calldata receiverSignature,
        address payable feeReceiver,
        uint fee
    ) external onlyFactory whenNotPaused returns (bool) {
        require(
            checkClaimParams(
                amount,
                tokenAddress,
                tokenAmount,
                expiration,
                linkKey,
                linkdropSignerSignature,
                receiver,
                receiverSignature,
                fee
            ),
            "INVALID_CLAIM_PARAMS"
        );
        claimedLinks[linkKey] = receiver;
        require(
            _transferFunds(amount, tokenAddress, tokenAmount, receiver, feeReceiver, fee),
            "TRANSFER_FAILED"
        );
        emit Claimed(linkKey, amount, tokenAddress, tokenAmount, receiver);
        return true;
    }

    function _transferFunds(
        uint amount,
        address tokenAddress,
        uint tokenAmount,
        address payable receiver,
        address payable feeReceiver,
        uint fee
    ) internal returns (bool) {
        if (fee > 0) {
            feeReceiver.transfer(fee);
        }
        if (amount > 0) {
            receiver.transfer(amount);
        }
        if (tokenAmount > 0) {
            IERC20(tokenAddress).transferFrom(linkdropMaster, receiver, tokenAmount);
        }
        return true;
    }
}

pragma solidity ^0.5.6;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.5.6;

contract LinkdropERC721 is ILinkdropVerifier, LinkdropMastercopy {
    using SafeMath for uint;

    function verifyLinkdropSignerSignature(
        uint amount,
        address nftAddress,
        uint tokenId,
        uint expiration,
        address linkKey,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    amount,
                    nftAddress,
                    tokenId,
                    expiration,
                    masterCopyVersion,
                    chainId,
                    linkKey,
                    address(this)
                )
            )
        );
        address signer = ECDSA.recover(hash, signature);
        return signingKeys[signer];
    }

    function verifyReceiverSignature(
        address linkKey,
        address receiver,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(receiver)));
        address signer = ECDSA.recover(hash, signature);
        return signer == linkKey;
    }

    function checkClaimParams(
        uint amount,
        address nftAddress,
        uint tokenId,
        uint expiration,
        address linkKey,
        bytes memory linkdropSignerSignature,
        address receiver,
        bytes memory receiverSignature,
        uint fee
    ) public view whenNotPaused returns (bool) {
        require(nftAddress != address(0), "INVALID_NFT_ADDRESS");
        require(!isClaimedLink(linkKey), "LINK_CLAIMED");
        require(!isCanceledLink(linkKey), "LINK_CANCELED");
        require(expiration >= now, "LINK_EXPIRED");
        require(address(this).balance >= amount.add(fee), "INSUFFICIENT_ETHERS");
        require(
            IERC721(nftAddress).ownerOf(tokenId) == linkdropMaster,
            "LINKDROP_MASTER_DOES_NOT_OWN_TOKEN_ID"
        );
        require(
            IERC721(nftAddress).isApprovedForAll(linkdropMaster, address(this)),
            "INSUFFICIENT_ALLOWANCE"
        );
        require(
            verifyLinkdropSignerSignature(
                amount,
                nftAddress,
                tokenId,
                expiration,
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
        uint amount,
        address nftAddress,
        uint tokenId,
        uint expiration,
        address linkKey,
        bytes calldata linkdropSignerSignature,
        address payable receiver,
        bytes calldata receiverSignature,
        address payable feeReceiver,
        uint fee
    ) external onlyFactory whenNotPaused returns (bool) {
        require(
            checkClaimParams(
                amount,
                nftAddress,
                tokenId,
                expiration,
                linkKey,
                linkdropSignerSignature,
                receiver,
                receiverSignature,
                fee
            ),
            "INVALID_CLAIM_PARAMS"
        );
        claimedLinks[linkKey] = receiver;
        require(
            _transferFunds(amount, nftAddress, tokenId, receiver, feeReceiver, fee),
            "TRANSFER_FAILED"
        );
        emit ClaimedERC721(linkKey, amount, nftAddress, tokenId, receiver);
        return true;
    }

    function _transferFunds(
        uint amount,
        address nftAddress,
        uint tokenId,
        address payable receiver,
        address payable feeReceiver,
        uint fee
    ) internal returns (bool) {
        feeReceiver.transfer(fee);
        if (amount > 0) {
            receiver.transfer(amount);
        }
        IERC721(nftAddress).safeTransferFrom(linkdropMaster, receiver, tokenId);
        return true;
    }
}

pragma solidity ^0.5.6;

contract Linkdrop is LinkdropVerifier, LinkdropERC721 {}
```