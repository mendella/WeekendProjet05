// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { LotteryToken } from "./Token.sol";

contract Lottery is Ownable {
        LotteryToken public paymentToken;
        uint256 public purchaseRatio;
        uint256 public betPrice;
        uint256 public betFee;
        uint256 public closingTimestamp;

        uint256 public ownerPool;
        uint256 public prizePool;

        mapping (address => uint256) prize;
      
        bool public betsOpen;
        
        address[] _slots;

    constructor(string memory name, string memory symbol, uint256 _purchaseRatio, uint256 _betPrice, 
                    uint256 _betFee) {
            paymentToken = new LotteryToken(name, symbol);
            purchaseRatio = _purchaseRatio;
            betFee = _betFee;
            betPrice = _betPrice;          
        } 
    
    modifier whenBetsClosed() {
        require(!betsOpen, "Lottery is open");
        _;
    }

    modifier whenBetsOpen() {
        require(
            betsOpen && block.timestamp < closingTimestamp,
            "Lottery is closed"
        );
        _;
    }

    function openBets(uint256 _closingTimestamp) public onlyOwner whenBetsClosed {
        require(
            closingTimestamp > block.timestamp,
            "Closing time must be in the future"
        );
        closingTimestamp = _closingTimestamp;
        betsOpen = true;
    }

    // function openBets(uint256 _closingTimestamp) external onlyOwner {
    //     require(!betsOpen, "The bets are already open!");
    //     require(closingTimestamp > block.timestamp, "The closing time must be in the future");
    //     betsOpen = true;
    //     closingTimestamp = _closingTimestamp;

    // }

    function purchaseToken() public payable {
        paymentToken.mint(msg.sender, msg.value * purchaseRatio);

    }   

    function bet() public whenBetsOpen {
        prizePool += betPrice;
        ownerPool += betFee;
        _slots.push(msg.sender);
        paymentToken.transferFrom(msg.sender, address(this), betPrice + betFee);
        //todo include msg.send to be in the game
    }

    function betMany(uint256 times) public {
        require(times > 0);    
        while (times > 0) {
            times--;
            bet();
        }
    }

    function closeLottery() public {
        require(closingTimestamp <= block.timestamp, "Too soon to close");
        require(betsOpen, "Bets are closed");
        if(_slots.length > 0){
            uint256 winnerIndex = getRandomNumber() % _slots.length;
            address winner = _slots[winnerIndex];
            prize[winner] += prizePool;
            prizePool = 0;
            delete(_slots);
        }
        betsOpen = false;
    }
    
    function getRandomNumber() public view returns (uint256 randomNumber) {
        randomNumber = block.difficulty;
    }

    function prizeWithdraw(uint256 amount) public {
        require(amount <= prize[msg.sender], "Not enough prize");
        prize[msg.sender] -= amount;
        paymentToken.transfer(msg.sender, amount);
    }

    /// @notice Withdraw `amount` from the owner pool
    function ownerWithdraw(uint256 amount) public onlyOwner {
        require(amount <= ownerPool, "Not enough fees collected");
        ownerPool -= amount;
        paymentToken.transfer(msg.sender, amount);
    }

    /// @notice Burn `amount` tokens and give the equivalent ETH back to user
    function returnTokens(uint256 amount) public {
        paymentToken.burnFrom(msg.sender, amount);
        payable(msg.sender).transfer(amount / purchaseRatio);
    }
}

//prize withdraw
//owner withdraw
//return tokens
