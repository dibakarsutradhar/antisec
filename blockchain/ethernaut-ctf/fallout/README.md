# FAL1OUT

![https://ethernaut.openzeppelin.com/imgs/BigLevel2.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel2.svg)

# Objectives

Claim ownership of the contract

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import 'openzeppelin-contracts-06/math/SafeMath.sol';

contract Fallout {
  
  using SafeMath for uint256;
  mapping (address => uint) allocations;
  address payable public owner;

  /* constructor */
  function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
  }

  modifier onlyOwner {
    require(
        msg.sender == owner,
        "caller is not the owner"
    );
    _;
  }

  function allocate() public payable {
    allocations[msg.sender] = allocations[msg.sender].add(msg.value);
  }

  function sendAllocation(address payable allocator) public {
    require(allocations[allocator] > 0);
    allocator.transfer(allocations[allocator]);
  }

  function collectAllocations() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function allocatorBalance(address allocator) public view returns (uint) {
    return allocations[allocator];
  }
}
```

# Analysis I

The contract is using `solidity` version `0.6.0` and using `SafeMath` for `uint256`, so no chances of underflow or overflow math. And we need to claim the ownership of this contract, our main focus is where and how the contract is assigning owner.

The only place where owner is being set is in the `constructor`. Wait a minute! We can already see a problem here, which we can exploit. Since constructor is only place where we can claim ownership of the contract, this should be our main focus. However before we delve ourselves into the constructor, it wouldn’t hurt to look at the other functions. The other functions are - 

1. `allocate()`
2. `sendAllocations()`
3. `collectAllocations()`
4. `allocatorBalance()`

## Some History Lessons

This `solidity` version in the contract is important in this case. We will come back to it. But first let’s learn more about constructors in solidity.

### Constructors 101

Constructors are special functions that are executed at the beginning of the deployment of the contract and are only executed once. They can’t be called externally or internally after deployment and is only used to initialize the contract’s state.

### Solidity `0.4.21`

Up to solidity 0.4.21, it was possible to define a contract’s constructors using the same name as that of the contract. Here’s an example - 

```solidity
pragma solidity 0.4.21;

contract HelloWorld {
	// constructor
	function HelloWorld() public {
		// do something
	}
}
```

This method however introduced some security issues, which we will exploiting soon. 

### Solidity `0.4.22` & above

To mitigate the security issue, in newer versions of Solidity, it is not possible to define constructors using the same name as contract’s name. One have to use the keyword `constructor` to define it.

```solidity
pragma solidity 0.4.22;

contract HelloWorld {
	// constructor
	constructor () public {
		// do something
	}
}
```

# Analysis I

Now let’s see what the constructor look like of this contract.

```solidity
/* constructor */
function Fal1out() public payable {
  owner = msg.sender;
  allocations[owner] = msg.value;
}
```

Even though the comment says constructor, it’s not really one. The contract’s name is `Fallout` however it seems the so called constructor function has a typo, and it says `Fal1out` instead. They used `1` instead of an `l` and the function supposed to assign the `owner` of this contract during deployment. However, because of this typo, the contract deployed without assigning any owner, this is because the contract views this `Fal1out` as a normal function instead of a constructor. And the function is `public` , so it can be called by anyone from anywhere.

# AntiSec

Awesome, we now know how to exploit this contract. All we need to do is write another contract and call the `Fal1out` function which was never called. And this should make us the new owner of the `Fallout` contract.

I’ll use `RemixIDE` to call this function, write an interface for the `Fallout` contract and deploy it in the existing contract address and call the `Fal1out` function from there.
Here’s the contract - 

```solidity
pragma solidity ^0.8.0;

interface Fallout {
    function Fal1out() external payable;
    function owner() view external returns (address);
}
```

Once deployed, that’s what the Remix interface looks like - 

![Screenshot 2023-02-05 at 12.08.25 AM.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/79cb0efc-fd88-421b-9fc7-936c24ee116d/Screenshot_2023-02-05_at_12.08.25_AM.png)

Now call the `Fal1out` function.

![Screenshot 2023-02-05 at 12.10.31 AM.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/558bdbca-c1b8-4a98-a8cc-03aed2b16b2d/Screenshot_2023-02-05_at_12.10.31_AM.png)

After successful transaction, now let’s check if we are new owner by calling the `owner` function - 

![Screenshot 2023-02-05 at 12.11.24 AM.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/3751f646-c085-4a87-a633-b86b9cd0a2eb/Screenshot_2023-02-05_at_12.11.24_AM.png)

And voila! The contract is claimed now!

Also a sorter way to claim the contract would be from the `console` of the `Ethernaut` web app. From the console simple run this command below - 

```jsx
await contract.Fal1out()
```

# Key Takeaways

1. Use latest solidity versions and stay up to dated with the security issues and their fixes
2. Double check your function names in order to avoid typos.
