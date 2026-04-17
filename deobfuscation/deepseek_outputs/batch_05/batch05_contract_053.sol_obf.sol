```solidity
pragma solidity ^0.4.24;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MultiSigWallet {
    address public owner1;
    address public owner2;
    address public owner3;
    address public owner4;
    address public owner5;
    address public contractAddress;
    
    uint public totalOwners;
    uint public votesToReplace;
    uint public votesToSend;
    uint public initReplaceVote;
    uint public initSendToVote;
    uint public depositType;
    uint public theFunction;
    uint public amountToSend;
    uint public isTokensSent;
    
    mapping(address => address) public isOwner;
    mapping(uint => address) public ownerById;
    
    modifier ownersRestricted() {
        require(isOwner[msg.sender] == msg.sender);
        _;
    }
    
    function() payable public {}
    
    function initialize(
        address _owner1,
        address _owner2,
        address _owner3,
        address _owner4,
        address _owner5
    ) public payable {
        require(initReplaceVote == 0);
        initReplaceVote = 1;
        
        totalOwners = 5;
        owner1 = _owner1;
        isOwner[_owner2] = _owner2;
        isOwner[_owner3] = _owner3;
        isOwner[_owner4] = _owner4;
        isOwner[_owner5] = _owner5;
        
        ownerById[1] = _owner1;
        ownerById[2] = _owner2;
        ownerById[3] = _owner3;
        ownerById[4] = _owner4;
        ownerById[5] = _owner5;
        
        contractAddress = address(this);
    }
    
    function initiateReplaceOwner(
        address oldOwner,
        address newOwner
    ) ownersRestricted public {
        require(
            initReplaceVote == 0 &&
            initSendToVote == 0 &&
            oldOwner != msg.sender &&
            votesToReplace == 0
        );
        
        oldOwnerToReplace = oldOwner;
        newOwnerInsteadOfOldOwner = newOwner;
        votesToReplace = 1;
        ownerVotedToReplace[msg.sender] = 1;
    }
    
    function voteToReplaceOwner() ownersRestricted payable public {
        require(
            initReplaceVote == 1 &&
            ownerVotedToReplace[msg.sender] == 0 &&
            initSendToVote == 0
        );
        
        ownerVotedToReplace[msg.sender] = 1;
        votesToReplace = votesToReplace + 1;
        
        if(votesToReplace == 3) {
            delete ownerVotedToReplace[oldOwnerToReplace];
            delete isOwner[oldOwnerToReplace];
            delete ownerVotedToSend[oldOwnerToReplace];
            delete ownerVotedToReplace[newOwnerInsteadOfOldOwner];
            delete ownerVotedToSend[newOwnerInsteadOfOldOwner];
            
            if(ownerById[1] == oldOwnerToReplace) {
                ownerById[1] = newOwnerInsteadOfOldOwner;
            } else if(ownerById[2] == oldOwnerToReplace) {
                ownerById[2] = newOwnerInsteadOfOldOwner;
            } else if(ownerById[3] == oldOwnerToReplace) {
                ownerById[3] = newOwnerInsteadOfOldOwner;
            } else if(ownerById[4] == oldOwnerToReplace) {
                ownerById[4] = newOwnerInsteadOfOldOwner;
            } else if(ownerById[5] == oldOwnerToReplace) {
                ownerById[5] = newOwnerInsteadOfOldOwner;
            }
            
            ownerVotedToReplace[ownerById[1]] = 0;
            ownerVotedToReplace[ownerById[2]] = 0;
            ownerVotedToReplace[ownerById[3]] = 0;
            ownerVotedToReplace[ownerById[4]] = 0;
            ownerVotedToReplace[ownerById[5]] = 0;
            
            votesToReplace = 0;
            initReplaceVote = 0;
            depositType = 0;
        }
    }
    
    function initiateSendTo(
        address sendTo,
        uint functionType,
        uint amount,
        uint param1,
        address param2,
        uint param3
    ) ownersRestricted public payable {
        require(
            totalOwners == 5 &&
            initReplaceVote == 0 &&
            initSendToVote == 0 &&
            address(this).balance >= amount
        );
        
        if(sendWithHex == 1) {
            theFunction = functionType;
            depositType = param1;
        }
        
        sendToAddress = sendTo;
        amountToSend = amount;
        tokensAddress = param2;
        tokensAmount = param3;
        initSendToVote = 1;
        ownerVotedToSend[msg.sender] = 1;
    }
    
    function setCallContractValues(
        uint param1,
        uint param2,
        address param3,
        uint param4,
        uint param5
    ) ownersRestricted public payable {
        paramA = param1;
        paramB = param2;
        paramC = param3;
        paramD = param4;
        paramE = param5;
    }
    
    function voteToSend() ownersRestricted public {
        require(
            votesToReplace == 0 &&
            totalOwners == 5 &&
            initSendToVote == 1 &&
            ownerVotedToSend[msg.sender] == 0
        );
        
        votesToSend = votesToSend + 1;
        ownerVotedToSend[msg.sender] = 1;
        
        if(votesToSend == 3) {
            if(depositType == 1) {
                ERC20(tokensAddress).transfer(sendToAddress, amountToSend);
                
                if(theFunction == 1) {
                    if(!tokensAddress.call(abi.encodeWithSignature("CreateStibco()"))) {
                        revert();
                    }
                } else if(theFunction == 2) {
                    if(!tokensAddress.call(abi.encodeWithSignature(
                        "StibcoFee(uint256,uint256,uint256,address,uint256,uint256,uint256)",
                        paramA, paramB, paramC, paramD, paramE, paramF, paramG
                    ))) {
                        revert();
                    }
                } else if(theFunction == 3) {
                    if(!tokensAddress.call(abi.encodeWithSignature(
                        "StibcoFee(uint256,uint256,uint256,address,uint256,uint256)",
                        paramA, paramB, paramC, paramD, paramE, paramF
                    ))) {
                        revert();
                    }
                } else if(theFunction == 4) {
                    if(!tokensAddress.call(abi.encodeWithSignature("StiboCollectFee()"))) {
                        revert();
                    }
                } else if(theFunction == 5) {
                    revert();
                } else if(theFunction == 6) {
                    revert();
                } else if(theFunction == 7) {
                    revert();
                } else if(theFunction == 8) {
                    revert();
                } else if(theFunction == 9) {
                    if(!tokensAddress.call(abi.encodeWithSignature(
                        "StibcoFee(uint256,address,uint256,uint256,uint256)",
                        paramA, paramD, paramC, paramB, paramE
                    ))) {
                        revert();
                    }
                } else if(theFunction == 10) {
                    revert();
                } else if(theFunction == 11) {
                    revert();
                } else if(theFunction == 12) {
                    revert();
                } else if(theFunction == 13) {
                    if(!tokensAddress.call(abi.encodeWithSignature(
                        "DisputeLenderWins(address,uint256)",
                        paramD, paramA
                    ))) {
                        revert();
                    }
                } else if(theFunction == 14) {
                    if(!tokensAddress.call(abi.encodeWithSignature(
                        "DisputeBorrowerWins(address,uint256)",
                        paramD, paramA
                    ))) {
                        revert();
                    }
                } else if(theFunction == 15) {
                    if(!tokensAddress.call(abi.encodeWithSignature(
                        "Delegate(address)",
                        paramD
                    ))) {
                        revert();
                    }
                } else if(theFunction == 16) {
                    if(!tokensAddress.call(abi.encodeWithSignature(
                        "StibcoFee(uint,uint,uint,address)",
                        paramA, paramB, paramC, paramD
                    ))) {
                        revert();
                    }
                }
                
                if(isTokensSent == 1) {
                    ERC20(tokensAddress).transfer(sendToAddress, amountToSend);
                    isTokensSent = 1;
                }
            } else {
                sendToAddress.transfer(amountToSend);
                isTokensSent = 1;
            }
            
            ownerVotedToSend[ownerById[1]] = 0;
            ownerVotedToSend[ownerById[2]] = 0;
            ownerVotedToSend[ownerById[3]] = 0;
            ownerVotedToSend[ownerById[4]] = 0;
            ownerVotedToSend[ownerById[5]] = 0;
            
            initSendToVote = 0;
            depositType = 0;
        }
    }
    
    function getParams() public view returns (uint, uint, uint, address, uint, uint, uint) {
        return (paramA, paramB, paramC, paramD, paramE, paramF, paramG);
    }
    
    function getState() public view returns (
        address, address, address, address, address, address,
        uint, uint, uint, address, address, address, uint, uint
    ) {
        return (
            contractAddress,
            ownerById[1],
            ownerById[2],
            ownerById[3],
            ownerById[4],
            ownerById[5],
            amountToSend,
            votesToSend,
            votesToReplace,
            tokensAddress,
            oldOwnerToReplace,
            newOwnerInsteadOfOldOwner,
            depositType,
            theFunction
        );
    }
    
    function getTokenInfo() public view returns (address, uint, uint) {
        return (tokensAddress, tokensAmount, isTokensSent);
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getTokenBalance(address tokenAddress) public view returns (uint) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }
    
    function transferTokens(
        address tokenAddress,
        uint amount,
        uint transferType
    ) public payable {
        if(transferType == 1) {
            ERC20(tokenAddress).transferFrom(msg.sender, contractAddress, amount);
        } else {
            require(amount == msg.value);
        }
    }
    
    address public oldOwnerToReplace;
    address public newOwnerInsteadOfOldOwner;
    address public sendToAddress;
    address public tokensAddress;
    
    uint public paramA;
    uint public paramB;
    uint public paramC;
    uint public paramD;
    uint public paramE;
    uint public paramF;
    uint public paramG;
    
    uint public sendWithHex;
    
    mapping(address => uint) public ownerVotedToReplace;
    mapping(address => uint) public ownerVotedToSend;
}
```