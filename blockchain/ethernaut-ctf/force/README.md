# Force

![https://ethernaut.openzeppelin.com/imgs/BigLevel7.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel7.svg)

# Objectives

Some contracts will simply not take your money `¯\_(ツ)_/¯`

The goal of this level is to make the balance of the contract greater than zero.

Things that might help:

- Fallback methods
- Sometimes the best way to attack a contract is with another contract.
- See the Help page above, section "Beyond the console"

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}
```

# Analysis

This contract does not contain any receive() function and literally empty. So we have to force feed the contract some Ether. What is force feeding and how can we do that in EVM?

## Force-Feeding a Smart Contract

There are currently three ways in which we can forcefully send Ether to a contract aka force-feeding, even when it does to have any implementations to receive funds. They are:

1. `Self-destruct`: Smart contracts can receive Ether from other contracts as a result of a `selfdestruct()` call. All the Ether stored in the calling contract will then be transferred to the address specified when calling the `selfdestruct()` and there’s no way for the receiver to prevent this because this happens on the EVM level.
2. `Coinbase Transactions`: An address can receive Ether as a result of Coinbase transactions or block rewards. The attacked can start proof-of-work mining and set the target address to receive the rewards.
3. `Pre-Calculated Addresses`: It is possible to pre-calculate the contract address before they are generated. If an attacker deposits funds into the address before its deployment, it is possible to forcefully store Ether there.

# AntiSec

We will use the first method `selfdestruct()` to force feed the contract, as it is relatively easier to achieve then the other two.

## What is `selfdestruct()` ?

It is a function which is used to delete a contract from the blockchain and remove it’s code and storage. Whenever it is called, the Ether stored in the contract from which it is being called will be sent to the recipient address mentioned in the arguments, regardless of having receive methods implemented in that address or not. This is how it looks - 

```solidity
selfdestruct(address);
```

So to finish this level, we just need to deploy another contract, fund it with some Ether and use a `selfdestruct()` with the address of the `Force` contract to forcefully send some Ether to it.

Before we start, let’s check on Etherscan how much balance this current `Force` contract holds - 

![Screenshot 2023-02-10 at 1.53.32 PM.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/a19b5d88-742a-4015-be0f-cd50f21ce23b/Screenshot_2023-02-10_at_1.53.32_PM.png)

As we can see, currently it holds `0` Ether. Let’s hack it now.

To send some Ether to it, I will create a new contract using `Remix IDE` and fund the contract with `1` Wei and self destruct it with the recipient address being set to the `Force` contract address. Here’s how it looks - 

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract HackForce {
    constructor(address payable _target) payable {
        selfdestruct(_target);
    }
}
```

This is what the Remix Deploy set up looks like - 

![Screenshot 2023-02-10 at 2.01.28 PM.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/30588f5e-1930-4e42-b8f8-103f003b9942/Screenshot_2023-02-10_at_2.01.28_PM.png)

Once the deploy and selfdestruct transaction goes through, let’s check the new balance of `Force` contract at Etherscan - 

![Screenshot 2023-02-10 at 2.02.40 PM.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/10891877-9f4b-4dbc-8724-4ac73629476e/Screenshot_2023-02-10_at_2.02.40_PM.png)

Congratulations! Let’s submit the instance and proceed to the next challenge.

# Key Takeaways

In solidity, for a contract to be able to receive ether, the fallback function must be marked `payable`.

However, there is no way to stop an attacker from sending ether to a contract by self destroying. Hence, it is important not to count on the invariant `address(this).balance == 0` for any contract logic. Why?

This type of security vulnerabilities arises from the misuse of the `this.balance` statement. Contracts that depend on specific balances on their logic are prone to unexpected behavior as balances can be altered through malicious contracts that use `selfdestruct()`.

Instead, if exact values of deposited are required, it is recommend to create a private variable used to safely track the deposited Ether. This will avoid the contract from being susceptible to force Ether sent via a `selfdestruct()` call.

Additionally, remember that even if you have not implemented a `selfdestruct()` call, it is possible to call it through any `delegatecall()` vulnerabilities.
