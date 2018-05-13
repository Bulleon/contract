pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/erc20/PausableToken.sol";
import "./BulleonCrowdsale.sol";


contract LockableToken is PausableToken {
  address public icoAddress;
  BulleonCrowdsale crowdsale;
  bool public paused = true;


  constructor(address _ico) {
    crowdsale = BulleonCrowdsale(_ico);
    require(_ico != 0x0 && crowdsale.isActive());
  }

   /**
    * @dev called by user the to pause, triggers stopped state
    */
  function pause() public {
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() whenPaused public {
    require(!crowdsale.isActive()); // Checks that ICO is ended
    paused = false;
    emit Unpause();
  }
}
