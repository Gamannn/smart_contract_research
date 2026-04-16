pragma solidity 0.4.24;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Consts {
    uint256 public constant SUPPLY = 200000000;
    uint public constant TOKEN_DECIMALS = 4;
    uint8 public constant TOKEN_DECIMALS_UINT8 = 4;
    string public constant TOKEN_SYMBOL = "ABR";
    string public constant TOKEN_NAME = "Abri";
    uint256 public constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;
}

contract NewToken is Consts, StandardToken {
    address public owner;
    bool public initialized;

    constructor() public {
        owner = msg.sender;
        init();
    }

    function init() internal {
        totalSupply_ = SUPPLY * TOKEN_DECIMAL_MULTIPLIER;
        balances[owner] = totalSupply_;
        initialized = true;
    }

    function name() public pure returns (string) {
        return TOKEN_NAME;
    }

    function symbol() public pure returns (string) {
        return TOKEN_SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return TOKEN_DECIMALS_UINT8;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        return super.transfer(_to, _value);
    }
}

contract Digital is NewToken {
    address public lord = 0xaC011c052E35e51f82A87f8abB4605535AA28bb1;
    address public admin;
    uint public abr;
    uint public eth;
    uint public sw;
    uint public coe;
    uint public daily;
    mapping (address => string) public mail;
    mapping (address => string) public mobile;
    mapping (address => string) public nickname;
    mapping (address => address) public prev;
    mapping (address => uint) public index;
    mapping (address => bool) public otime;
    mapping (address => uint) public totalm;
    mapping (address => address[]) public adj;
    mapping (address => uint) public usddisplay;
    mapping (address => uint) public usdinterest;
    mapping (address => uint) public abrdisplay;
    mapping (address => uint) public start;
    mapping (address => uint) public time;

    modifier onlyLord() {
        require(msg.sender == lord, "");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "");
        _;
    }

    modifier isCashback() {
        require(getback(usddisplay[msg.sender]) == time[msg.sender], "");
        _;
    }

    function setAdmin(address _admin) public onlyLord {
        admin = _admin;
    }

    function withdrawal() public onlyAdmin {
        admin.transfer(address(this).balance - 1 ether);
    }

    function sendAbr(uint _send) public onlyLord {
        transfer(admin, _send);
    }

    function setPrice(uint _e, uint _ex) public onlyAdmin {
        sw = _ex;
        eth = _e;
        abr = eth.div(sw);
    }

    function setDaily(uint _daily) public onlyAdmin {
        daily = _daily;
    }

    function setCoe(uint _coe) public onlyAdmin {
        coe = _coe;
    }

    function getback(uint _uint) internal pure returns (uint) {
        if (_uint >= 10 * 10**8 && _uint <= 1000 * 10**8) {
            return 240;
        } else if (_uint >= 1001 * 10**8 && _uint <= 5000 * 10**8) {
            return 210;
        } else if (_uint >= 5001 * 10**8 && _uint <= 10000 * 10**8) {
            return 180;
        } else if (_uint >= 10001 * 10**8 && _uint <= 50000 * 10**8) {
            return 150;
        } else if (_uint >= 50001 * 10**8 && _uint <= 100000 * 10**8) {
            return 120;
        }
    }

    function getLevel(uint _uint) internal pure returns (uint) {
        if (_uint >= 10 * 10**8 && _uint <= 1000 * 10**8) {
            return 5;
        } else if (_uint >= 1001 * 10**8 && _uint <= 5000 * 10**8) {
            return 12;
        } else if (_uint >= 5001 * 10**8 && _uint <= 10000 * 10**8) {
            return 20;
        } else if (_uint >= 10001 * 10**8 && _uint <= 50000 * 10**8) {
            return 25;
        } else if (_uint >= 50001 * 10**8 && _uint <= 100000 * 10**8) {
            return 30;
        }
    }

    function next(uint a, uint b) internal pure returns (bool) {
        return a != b;
    }

    function setInfo(string _mail, string _mobile, string _nickname) public {
        mail[msg.sender] = _mail;
        mobile[msg.sender] = _mobile;
        nickname[msg.sender] = _nickname;
    }

    function referral(address _referral) public {
        if (!otime[msg.sender]) {
            prev[msg.sender] = _referral;
            index[_referral]++;
            adj[_referral].push(msg.sender);
            otime[msg.sender] = true;
        }
    }

    function deposit(uint _a) public {
        if (otime[msg.sender]) {
            if (start[msg.sender] == 0) {
                start[msg.sender] = now;
            }
            uint pre = usddisplay[msg.sender];
            usddisplay[msg.sender] += _a * abr;
            totalm[prev[msg.sender]] += usddisplay[msg.sender];
            if (next(getLevel(pre), getLevel(usddisplay[msg.sender]))) {
                start[msg.sender] = now;
                time[msg.sender] = 0;
            }
            transfer(this, _a);
            address t1 = prev[msg.sender];
            if (pre == 0) {
                balances[this] = balances[this].sub(_a / 20);
                balances[t1] = balances[t1].add(_a / 20);
                address t2 = prev[t1];
                balances[this] = balances[this].sub(_a * 3 / 100);
                balances[t2] = balances[t2].add(_a * 3 / 100);
                address t3 = prev[t2];
                if (index[t3] > 1) {
                    balances[this] = balances[this].sub(_a / 50);
                    balances[t3] = balances[t3].add(_a / 50);
                }
                address t4 = prev[t3];
                if (index[t4] > 2) {
                    balances[this] = balances[this].sub(_a / 100);
                    balances[t4] = balances[t4].add(_a / 100);
                }
                address t5 = prev[t4];
                if (index[t5] > 3) {
                    balances[this] = balances[this].sub(_a / 200);
                    balances[t5] = balances[t5].add(_a / 200);
                }
                address t6 = prev[t5];
                if (index[t6] > 4) {
                    balances[this] = balances[this].sub(_a / 200);
                    balances[t6] = balances[t6].add(_a / 200);
                }
            } else {
                balances[this] = balances[this].sub(_a / 20);
                balances[t1] = balances[t1].add(_a / 20);
            }
        }
    }

    function support() public view returns (string, string, string) {
        return (mail[prev[msg.sender]], mobile[prev[msg.sender]], nickname[prev[msg.sender]]);
    }

    function care(uint _id) public view returns (string, string, string, uint) {
        address x = adj[msg.sender][_id];
        return (mail[x], mobile[x], nickname[x], usddisplay[x]);
    }

    function total() public view returns (uint, uint) {
        return (index[msg.sender], totalm[msg.sender]);
    }

    function swap(uint _s) public payable {
        balances[owner] = balances[owner].sub(_s * sw);
        balances[msg.sender] = balances[msg.sender].add(_s * sw);
    }

    function claim() public returns (string) {
        if ((now - start[msg.sender]) == (time[msg.sender] + 1)) {
            time[msg.sender]++;
            uint ts = getLevel(usddisplay[msg.sender]);
            usdinterest[msg.sender] = (usddisplay[msg.sender] / 10000) * (ts + daily);
            uint _uint = usdinterest[msg.sender] / abr;
            abrdisplay[msg.sender] += _uint;
        } else if ((now - start[msg.sender]) > (time[msg.sender] + 1)) {
            time[msg.sender] = now - start[msg.sender];
        }
    }

    function iwithdrawal(uint _i) public {
        if (abrdisplay[msg.sender] > 0) {
            abrdisplay[msg.sender] -= _i;
            balances[this] = balances[this].sub(_i);
            balances[msg.sender] = balances[msg.sender].add(_i);
        }
    }

    function fwithdrawal(uint _f) public isCashback {
        if ((usddisplay[msg.sender] / 100) * coe >= _f * abr) {
            usddisplay[msg.sender] -= _f * abr;
            balances[this] = balances[this].sub(_f);
            balances[msg.sender] = balances[msg.sender].add(_f);
        }
    }

    function getPrice() public view returns (uint) {
        return sw;
    }

    function getInfo() public view returns (string, uint, uint, uint, uint) {
        return (nickname[msg.sender], start[msg.sender], usddisplay[msg.sender], usdinterest[msg.sender], abrdisplay[msg.sender]);
    }

    function getTimeBack() public view returns (uint) {
        return getback(usddisplay[msg.sender]).sub(time[msg.sender]);
    }
}