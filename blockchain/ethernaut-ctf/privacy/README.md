# Privacy

![https://ethernaut.openzeppelin.com/imgs/BigLevel12.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel12.svg)

# Objectives

The creator of this contract was careful enough to protect the sensitive areas of its storage.

Unlock this contract to beat the level.

Things that might help:

- Understanding how storage works
- Understanding how parameter parsing works
- Understanding how casting works

Tips:

- Remember that metamask is just a commodity. Use another tool if it is presenting problems. Advanced gameplay could involve using remix, or your own web3 provider.

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {

  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(block.timestamp);
  bytes32[3] private data;

  constructor(bytes32[3] memory _data) {
    data = _data;
  }
  
  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
  }

  /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}
```

# Analysis

This challenge wants us to unlock the contract using the `unlock()` function. Which takes a `bytes16` input as a key and requires it to be the equivalent of the last index of `bytes32[3] private data` array. And finally we have to change the `locked` boolean variables value to `false`. 

So here’s the thing, as we learned from the previous `Vault` challenge, no data in the blockchain is actually private. With right procedure, you can get the private information. So how can we get the private data stored in this contract? Let’s revisit the theory of how Solidity stores data in EVM storage.

Solidity uses slots to store data in the blockchain. One slot can store up to 32 bytes data. A `bool` and `uint256` variable takes about 32 bytes size each. A `bytes32` would take the entire slot to store data. However, an `uint8` would take only 1 bytes size and an `uint16` would take only 8 bytes, and if we declare them in a chronological way (one after one), Solidity is smart enough to pack them together and use only one slot to store them, which is a very effective way to save some gas cost. With that knowledge, the `Privacy` contract’s state variable storage looks like this - 

```solidity
// slot 0 = 32 bytes
bool public locked = true;
// slot 1 = 32 bytes
uint256 public ID = block.timestamp;
// slot 2
// solidity packes uint8, uint8 and uint16 together = 10 bytes
uint8 private flattening = 10;
uint8 private denomination = 255;
uint16 private awkwardness = uint16(block.timestamp);
// slot 3, slot 4, slot 5 = 32 bytes x 3
bytes32[3] private data;
```

# AntiSec

As per the `unlock()` function, we need the private information from the last or third index of the `data` array which is allocated in the `slot 5`. To read that data, I will use `web3.eth.getStorageAt()` method in the Ethernaut’s developer console. Here’s how it looks - 

```jsx
await web3.eth.getStorageAt(contract.address, 5)
>> "0x3401ce5c30da475719d3f00e98391cb12b72afa0bff46c8e0fb48995a4ddb758"
```

The data stored in the `Slot 5` or the last index of `data` array is - 

`"0x3401ce5c30da475719d3f00e98391cb12b72afa0bff46c8e0fb48995a4ddb758"`

Now the `require` method needs the key to be `bytes16` and it should match the last index of `data` array after it has been typecasted to bytes16.

```solidity
require(_key == bytes16(data[2]));
```

Remember the data we got from Slot 5 is bytes32. A bytes32 data has 64 characters in it. To convert it to bytes16, we have to get the first 32 characters from that 64 characters. We can easily achieve that with `slice()` method.

I will save the hex data to a new variable called `data`. 

```jsx
data = "0x3401ce5c30da475719d3f00e98391cb12b72afa0bff46c8e0fb48995a4ddb758"
```

And now we can slice the data from the start to 34th character, as we also want the `0x` characters to be included.

```jsx
data.slice(0, 34);
"0x3401ce5c30da475719d3f00e98391cb1"
```

`"0x3401ce5c30da475719d3f00e98391c"` is our `_key` to unlock the challenge. Now let’s call the `unlock()` function with the acquired password. 

```solidity
await contract.unlock("0x3401ce5c30da475719d3f00e98391cb1")
```

Once the transaction completes successfully, let’s check if the contract is unlocked by checking the `locked` variable, and it should return false - 

```jsx
await contract.locked()
>> false
```

Congratulations on cracking the contract. It’s time to submit the instance.

# Key Takeaways

Nothing in the ethereum blockchain is private. The keyword private is merely an artificial construct of the Solidity language. Web3's `getStorageAt(...)` can be used to read anything from storage. It can be tricky to read what you want though, since several optimization rules and techniques are used to compact the storage as much as possible.

It can't get much more complicated than what was exposed in this level. For more, check out this excellent article by "Darius": [How to read Ethereum contract storage](https://medium.com/aigang-network/how-to-read-ethereum-contract-storage-44252c8af925)
