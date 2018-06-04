pragma solidity ^0.4.23;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol'; // Standard burnable token implementation from Zeppelin
import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol'; // PausableToken implementation from Zeppelin
import '../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol'; // Claimable implementation from Zeppelin

interface CrowdsaleContract {
  function isActive() public view returns(bool);
}

contract BulleonToken is StandardBurnableToken, PausableToken, Claimable {
  string public constant name = "Bulleon"; /* solium-disable-line uppercase */
  string public constant symbol = "BUL"; /* solium-disable-line uppercase */
  uint8 public constant decimals = 18; /* solium-disable-line uppercase */
  address public CrowdsaleAddress;
  CrowdsaleContract crowdsale;
  address public premineWallet = 0xA75E62874Cb25D53e563A269DF4b52d5A28e7A8e;
  uint256 public premineAmount = 178420 * (10 ** uint256(decimals));
  uint256 public constant totalSupply_ = 7970000 * (10 ** uint256(decimals));
  mapping(address=>bool) whitelist; // Users that may transfer tokens before ICO ended

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    balances[msg.sender] = totalSupply_ - premineAmount;
    balances[premineWallet] = premineAmount;
    owner = msg.sender;
    emit Transfer(0x0, msg.sender, totalSupply_ - premineAmount);
    emit Transfer(0x0, premineWallet, premineAmount);
    addToWhitelist(msg.sender);
    addToWhitelist(0xA75E62874Cb25D53e563A269DF4b52d5A28e7A8e);
    addToWhitelist(0x3c03f65569704346a4c78e1189Cb89F49057EccD);
    paused = true; // Lock token at start
  }

  function setCrowdsaleAddress(address _ico) public onlyOwner {
    CrowdsaleAddress = _ico;
    crowdsale = CrowdsaleContract(CrowdsaleAddress);
    addToWhitelist(_ico);
  }

  /**
   * @dev called by user the to pause, triggers stopped state
   * not actualy used
  */
  function pause() public {
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused or when sender is whitelisted.
   */
  modifier whenNotPaused() {
    require(!paused || whitelist[msg.sender]);
    _;
  }

  /**
   * @dev called by the user to unpause at ICO end or by owner, returns token to unlocked state
   */
  function unpause() whenPaused public {
    require(!crowdsale.isActive() || msg.sender == owner); // Checks that ICO is ended
    paused = false;
    emit Unpause();
  }

  /**
   * @dev Add wallet address to transfer whitelist (may transfer tokens before ICO ended)
   */
  function addToWhitelist(address wallet) public onlyOwner {
    require(!whitelist[wallet]);
    whitelist[wallet] = true;
  }

  /**
   * @dev Delete wallet address to transfer whitelist (may transfer tokens before ICO ended)
   */
  function delWhitelist(address wallet) public onlyOwner {
    require(whitelist[wallet]);
    whitelist[wallet] = false;
  }
}
