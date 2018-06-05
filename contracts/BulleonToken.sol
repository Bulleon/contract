pragma solidity ^0.4.23;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol'; // Standard burnable token implementation from Zeppelin
import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol'; // PausableToken implementation from Zeppelin
import '../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol'; // Claimable implementation from Zeppelin

interface CrowdsaleContract {
  function isActive() public view returns(bool);
}

contract BulleonToken is StandardBurnableToken, PausableToken, Claimable {
  /* Additional events */
  event AddedToWhitelist(address wallet);
  event RemoveWhitelist(address wallet);

  /* Base params */
  string public constant name = "Bulleon"; /* solium-disable-line uppercase */
  string public constant symbol = "BUL"; /* solium-disable-line uppercase */
  uint8 public constant decimals = 18; /* solium-disable-line uppercase */
  uint256 public constant totalSupply_ = 7970000 * (10 ** uint256(decimals));
  uint256 constant exchangersBalance = 0;

  /* Premine and start balance settings */
  address public premineWallet = 0x286BE9799488cA4543399c2ec964e7184077711C;
  uint256 public premineAmount = 178420 * (10 ** uint256(decimals));

  /* Additional params */
  address public CrowdsaleAddress;
  CrowdsaleContract crowdsale;
  mapping(address=>bool) whitelist; // Users that may transfer tokens before ICO ended

  /**
   * @dev Constructor that gives msg.sender all availabel of existing tokens.
   */
  constructor() public {
    balances[msg.sender] = totalSupply_;
    transfer(premineWallet, premineAmount.add(exchangersBalance));

    addToWhitelist(msg.sender);
    addToWhitelist(premineWallet);
    paused = true; // Lock token at start
  }

  /**
   * @dev Sets crowdsale contract address (used for checking ICO status)
   */
  function setCrowdsaleAddress(address _ico) public onlyOwner {
    CrowdsaleAddress = _ico;
    crowdsale = CrowdsaleContract(CrowdsaleAddress);
    addToWhitelist(CrowdsaleAddress);
  }

  /**
   * @dev called by user the to pause, triggers stopped state
   * not actualy used
   */
  function pause() onlyOwner whenNotPaused public {
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
    emit AddedToWhitelist(wallet);
  }

  /**
   * @dev Delete wallet address to transfer whitelist (may transfer tokens before ICO ended)
   */
  function delWhitelist(address wallet) public onlyOwner {
    require(whitelist[wallet]);
    whitelist[wallet] = false;
    emit RemoveWhitelist(wallet);
  }
}
