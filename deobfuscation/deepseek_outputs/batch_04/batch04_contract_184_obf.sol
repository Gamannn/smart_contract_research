pragma solidity ^0.4.24;

contract Lottery {
    uint public house_edge;
    uint public jackpot;
    uint256 public entry_number;
    address public owner;
    bool public game_alive;
    uint256 public total_wins_count;
    uint256 public total_wins_wei;
    uint256 public last_win_wei;
    address public last_winner;
    uint256 public balance_jackpot;
    uint256 public balance_house;

    constructor() public {
        owner = msg.sender;
        game_alive = false;
        house_edge = 0;
        jackpot = 0;
        entry_number = 0;
        total_wins_count = 0;
        total_wins_wei = 0;
        last_win_wei = 0;
        last_winner = address(0);
        balance_jackpot = 0;
        balance_house = 0;
    }

    function play() public payable {
        require(game_alive == true);
        require(isContract(msg.sender) != true);
        require(msg.value >= 0.001 ether && msg.value <= 0.1 ether);
        
        balance_jackpot = balance_jackpot + (msg.value * 98 / 100);
        balance_house = balance_house + (msg.value * 2 / 100);
        
        entry_number = entry_number + 1;
        
        if(entry_number % 999 == 0) {
            uint win_amount = balance_jackpot * 80 / 100;
            balance_jackpot = balance_jackpot - win_amount;
            last_winner = msg.sender;
            last_win_wei = win_amount;
            total_wins_count = total_wins_count + 1;
            total_wins_wei = total_wins_wei + win_amount;
            msg.sender.transfer(win_amount);
            return;
        } else {
            uint random_hash = uint(keccak256(abi.encodePacked((entry_number + block.number), block.number)));
            if(random_hash % 3 == 0) {
                uint win_amount = balance_jackpot * 50 / 100;
                if(address(this).balance - house_edge < win_amount) {
                    win_amount = (address(this).balance - house_edge) * 99 / 100;
                }
                balance_jackpot = balance_jackpot - win_amount;
                last_winner = msg.sender;
                last_win_wei = win_amount;
                total_wins_count = total_wins_count + 1;
                total_wins_wei = total_wins_wei + win_amount;
                msg.sender.transfer(win_amount);
            }
            return;
        }
    }

    function isContract(address addr) private returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getBalance() constant public returns (uint256) {
        return address(this).balance;
    }

    function getEntryNumber() constant public returns (uint256) {
        return entry_number;
    }

    function getLastWinWei() constant public returns (uint256) {
        return last_win_wei;
    }

    function getLastWinner() constant public returns (address) {
        return last_winner;
    }

    function getTotalWinsWei() constant public returns (uint256) {
        return total_wins_wei;
    }

    function getTotalWinsCount() constant public returns (uint256) {
        return total_wins_count;
    }

    function getHouseEdge() constant public returns (uint256) {
        return house_edge;
    }

    function stopGame() public onlyOwner {
        game_alive = false;
    }

    function startGame() public onlyOwner {
        game_alive = true;
        return;
    }

    function transferHouseEdge(uint amount) public onlyOwner payable {
        require(amount <= house_edge);
        require((address(this).balance - amount) > 0);
        owner.transfer(amount);
        house_edge = house_edge - amount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}