```solidity
pragma solidity ^0.4.24;

contract TokenContract {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public decimals;
    address public owner;
    mapping(address => uint256) public balanceOf;

    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdraw(address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier validAddress(address addr) {
        require(addr != address(0x00));
        _;
    }

    function TokenContract() public {
        owner = msg.sender;
        name = "TokenContract";
        symbol = "TKN";
        decimals = 18;
        totalSupply = 10000 * (10 ** decimals);
        balanceOf[owner] = totalSupply;
    }

    function setName(string _name) public onlyOwner returns (string) {
        name = _name;
        return name;
    }

    function setPrice(uint256 _price) public onlyOwner returns (uint256) {
        return _price;
    }

    function setDecimals(uint256 _decimals) public onlyOwner returns (uint256) {
        decimals = _decimals;
        return decimals;
    }

    function balanceOfAddress(address _address) public view returns (uint256) {
        return balanceOf[_address];
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function internalTransfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        internalTransfer(msg.sender, _to, _value);
    }

    function () public payable {
        uint256 tokens = (msg.value * decimals) / 10 ** decimals;
        if (msg.sender == owner) {
            totalSupply += tokens;
            balanceOf[owner] += tokens;
        } else {
            require(balanceOf[owner] >= tokens);
            internalTransfer(owner, msg.sender, tokens);
        }
    }

    function mint(uint256 _value) public onlyOwner returns (bool) {
        totalSupply += _value;
        balanceOf[owner] += _value;
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function withdrawAll() public onlyOwner {
        msg.sender.transfer(address(this).balance);
        emit Withdraw(msg.sender, address(this).balance);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        msg.sender.transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function withdrawTo(address _to, uint256 _amount) external onlyOwner validAddress(_to) {
        _to.transfer(_amount);
        uint256 fee = _amount / 100;
        msg.sender.transfer(fee);
    }
}
```