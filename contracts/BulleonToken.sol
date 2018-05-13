pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol"; /* Standard burnable token implementation from Zeppelin */
//import "LockableToken.sol"; /* Standard burnable token implementation from Zeppelin */
//import "BulleonCrowdsale.sol";


contract BulleonToken is StandardBurnableToken {
  string public constant name = "Bulleon"; /* solium-disable-line uppercase */
  string public constant symbol = "BUL"; /* solium-disable-line uppercase */
  uint8 public constant decimals = 18; /* solium-disable-line uppercase */

  address public premineWallet = 0xA75E62874Cb25D53e563A269DF4b52d5A28e7A8e;
  uint256 public premineAmount = 178420 * (10 ** uint256(decimals));
  uint256 public constant totalSupply_ = 7970000 * (10 ** uint256(decimals));

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
  */
  constructor(address _ico) public {
    balances[msg.sender] = totalSupply_ - premineAmount;
    balances[premineWallet] = premineAmount;
    emit Transfer(0x0, msg.sender, totalSupply_ - premineAmount);
    emit Transfer(0x0, premineWallet, premineAmount);
  }
}
