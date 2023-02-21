# Elevator

![https://ethernaut.openzeppelin.com/imgs/BigLevel11.svg](https://ethernaut.openzeppelin.com/imgs/BigLevel11.svg)

# Objectives

This elevator won't let you reach the top of your building. Right?

### Things that might help:

- Sometimes solidity is not good at keeping promises.
- This `Elevator` expects to be used from a `Building`.

# Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
  function isLastFloor(uint) external returns (bool);
}

contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}
```

# Analysis

In order to reach to the top of the floor, we have to use the `goTo()` function in the Elevator contract. Let’s analyze it first - 

The `goTo` function takes an unsigned integer value which should be the level of the floor. Once we call the function it is creating an instance of the `Building` interface with our address (`msg.sender`). We will talk about interface in a while. After that it is running a condition where it calls the `isLastFloor()` function of the `Building` interface and passes the `uint _floor` value that we provided to check if it is the last floor of that building.

The `isLastFloor()` from the building interface also takes an unsigned integer value and returns either True or False.

To get into that `if` condition we need the `building.isLastFloor(_floor)` to return false. After which the function will set our input floor value to the `uint public floor` slot and will again call the `building.isLastFloor(floor)` with the newly set `floor` value and store it to `top` value. So in short, if the first `isLastFloor` check returns False, the second check inside the condition should also return false, and we could never reach to the `Top` and hack the contract. To win this challenge we would require the last `isLastFloor()` check to return `True`. Now let’s look into the contract again and get to know how `Interface` works in Solidity.

The `Elevator` contract defines a `Building` interface at the top. An interface in solidity is similar to an abstract contract which lets you interact with other contracts. Just like other Object Oriented based programming languages in Solidity, interface can be used to implement other contracts functions. It also force or help other contract that is implementing the interface to follow a certain standard. This is extremely useful when creating standardized token contract like ERC20 or ERC721.

However, what interface won’t or can’t do is implement business logic. The methods in the interface must be empty, and it is up to the developer to implement business logic using the base standard provided by the interface in their smart contracts.

If one wants to their contract to follow the base standard of an interface, the contract should be written like this - 

```solidity
interface IHelloWorld {
	// some methods
}

contract HelloWorld is IHelloWorld {
	// contract methods
}
```

# AntiSec

Now that we know how interfaces works, if we look into the `Elevator` contract again, we can that the contract is not actually implementing the `Building` interface.

```solidity
contract Elevator {}
```

However it is creating an instance of that interface inside the `goTo` function with our address - 

```solidity
Building building = Building(msg.sender);
```

So in short, if we create a malicious contract which replicates the exact method of the `Building` interface with our own malicious implementation of the business logic, the `Elevator` contract will perform according to our contract’s logic.

All we need to do is call the `goTo()` function from our malicious contract and first return the `isLastFloor()` false and during the second call return true.

So I fired up my all time favorite `remixIDE` and copied the contract there, create a new contract called `Attack` and create a reference to the `Elevator` contact instance. 

The `attack()` will call the `goTo` function of `Elevator` contract and I passed `1` as the unsigned integer value for the floor. 

I have also implemented our version of `isLastFloor()` function which will return True after the first call. I’m using a uint variable to keep the count of the `isLastFloor()` call. Which I’m using to modify the business logic outcome of that function. Each time `isLastFloor()` will be called in our contract the `count` will be incrementing by one, and after the first increment it will always return `True`. 

We just need to call the `attack()` once and we will own the contract. Here’s the full code - 

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
  function isLastFloor(uint) external returns (bool);
}

contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}

contract Attack {
    Elevator elevator = Elevator(0x3dF9535976Cd87d4D70d263C4f574aE4CE1B58A1);
    uint private count;

    function attack() public {
        elevator.goTo(1);
    }

    function isLastFloor(uint) public returns (bool) {
        count++;
        return count > 1;
    }
}
```

# Key Takeaways

You can use the `view` function modifier on an interface in order to prevent state modifications. The `pure` modifier also prevents functions from modifying the state. Make sure you read [Solidity's documentation](http://solidity.readthedocs.io/en/develop/contracts.html#view-functions) and learn its caveats.

An alternative way to solve this level is to build a view function which returns different results depends on input data but don't modify state, e.g. `gasleft()`.
