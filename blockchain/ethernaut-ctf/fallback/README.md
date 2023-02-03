# Fallback

![https://ethernaut.openzeppelin.com/imgs/BigLevel1.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel1.svg)

# Objectives

The main objectives of this level are:

1. You have to claim the ownership of the contract
2. You have to drain all the balance in the contract

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {

  mapping(address => uint) public contributions;
  address public owner;

  constructor() {
    owner = msg.sender;
    contributions[msg.sender] = 1000 * (1 ether);
  }

  modifier onlyOwner {
		require(
				msg.sender == owner,
				"caller is not the owner"
		);
		_;
	}

  function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;
    if(contributions[msg.sender] > contributions[owner]) {
      owner = msg.sender;
    }
  }

  function getContribution() public view returns (uint) {
    return contributions[msg.sender];
  }

  function withdraw() public onlyOwner {
    payable(owner).transfer(address(this).balance);
  }

  receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
  }
}
```

# Analysis

Since we need to claim the ownership of this contract, let’s see where we can assign new ownership in this contract -

1. `contribute()`
2. `receive()`

Other than the `constructor()` function, these two are the function that can allow us to claim the ownership of the contract. Another important function is `withdraw()` which we need to drain the contract balance, however it is protected by the `onlyOwner` modifier, thus we can only call it once we have claimed the ownership.

Let’s deep down with the `contribute()` function first.

## contribute()

```solidity
function contribute() public payable {
  require(msg.value < 0.001 ether);
  contributions[msg.sender] += msg.value;
  if(contributions[msg.sender] > contributions[owner]) {
    owner = msg.sender;
  }
}
```

This is a `payable` function that allows anyone to call it and send some Ether in the `msg.value` The value however should be less than `0.001` Ether. Upon successful transaction it increments the sent Ether in the `contributions` mapping for the `msg.sender` account (which is us).

The `if` statement checks if our contribution is greater than the owner’s contribute, in case of `YES` it will transfer the contract ownership to our account (`msg.sender`). Great right? We just need to send more Ether than the current owner. However it seems sort of too much of ETH to spend as the constructor of the contract sets `1000` Ether as the owner’s contribution.

```solidity
constructor() {
  owner = msg.sender;
  contributions[msg.sender] = 1000 * (1 ether);
}
```

## receive()

Since, claiming ownership through `contribute()` is not a doable option, let’s look at the `receive()` -

```solidity
receive() external payable {
  require(msg.value > 0 && contributions[msg.sender] > 0);
  owner = msg.sender;
}
```

This is a fallback function responsible for receiving the Ether. It is triggered when a call is made to the contract with no `calldata` such as the `send`, `transfer`, and `call` function.

Let’s dig deep into how a fallback function works -

### Fallback function

We can directly send the ETH to the contract address and based on the below diagram it will ether call `fallback()` or `receive()` function.

```solidity
Which function is called, fallback() or receive()?
					send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback()
```

It is best practice to implement a simple `fallback` function if you want to your smart contract to generally receive Ether from other contracts and wallets. The `Fallback` function enables a smart contract’s inherent ability to act like a wallet. If someone has your wallet address, that person can send Ethers without your permission. In most cases, one might want to enable this `fallback` feature for ease-of-payment of smart contracts, this way contracts/wallets can send Ether to your contract without having to know your ABI or specific function names.

However, the problem is when key logics are implemented inside the fallback functions. Such as - Changing contract ownership, transferring funds, etc.

## AntiSec

Now that we know about `fallback()` let’s again look at the `receive()` -

```solidity
receive() external payable {
  require(msg.value > 0 && contributions[msg.sender] > 0);
  owner = msg.sender;
}
```

What we have here?

This fallback function seems to follow one of our bad practices, which is change of ownership. It requires two conditions though -

1. Your fallback function call needs to contain some Ether value higher than `0`
2. Your account address needed to have contributed Ether to this contract in the past.

Seems like we can exploit this loophole!

### 1. Contribute some Ether to the contract

First, lets contribute some ether to bypass the second condition (_Your account address needed to have contributed Ether to this contract in the past_)

```jsx
await contract.contribute({ value: toWei('0.001') });
```

### 2. Check the Contribution map

Now we check if the contribution went through by calling the `getContribution()` function.

```jsx
await contract.getContribution();
```

This should return a object with your contribution to this contract address.

### 3. Attack the `receive()` function

If the contribution lists shows our contribution, now we can attack the contract by sending some ether to it directly which will automatically invoke the receive fallback function, and will bypass the first require check, which will set our address to be the new owner.

```jsx
await contract.sendTransaction({ value: toWei('0.001') });
```

### 4. Check new `Owner`

Once the transaction goes through, lets check if we are the new owner.

```jsx
(await contract.owner()) == player;
```

If it returns the value `True`, congratulations, we have successfully bypass the `require` check and hacked the contract.

### 5. Drain the Contract

Now to finish of our attack, and complete the level, we need to drain the contract using the `withdraw()` function.

```jsx
await contract.withdraw();
```

# Security Takeaways

1. In case of fallback function implementation, keep it simple.
2. It is not wise to implement key logics like changing ownership or transferring funds in a fallback function.
3. Fallback functions should be used to check simple conditional requirements and emit payment events to the transaction log.
