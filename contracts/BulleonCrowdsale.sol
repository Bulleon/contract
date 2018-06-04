pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol"; /* Standard SafeMath implementation from Zeppelin */
import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol"; /* Standard Claimable implementation from Zeppelin */
import "./BulleonToken.sol"; /* Bulleon Token Contract */


contract BulleonCrowdsale is Claimable {
    using SafeMath for uint256;
    /* Additionals events */
    event AddedToBlacklist(address wallet);
    event RemovedFromBlacklist(address wallet);

    /* Infomational vars */
    string public name = "Bulleon Crowdsale";
    string public version = "2.0";

    /* ICO params */
    address public withdrawWallet = 0x3c03f65569704346a4c78e1189Cb89F49057EccD;
    uint256 public endDate = 1546300799; // Monday, 31-Dec-18 23:59:59 UTC
    BulleonToken public rewardToken;
    // Tokens rate (BUL / ETH) on stage
    uint256[] public tokensRate = [
      1000, // stage 1
      800, // stage 2
      600, // stage 3
      400, // stage 4
      200, // stage 5
      100, // stage 6
      75, // stage 7
      50, // stage 8
      25, // stage 9
      10 // stage 10
    ];
    // Tokens cap (max sold tokens) on stage
    uint256[] public tokensCap = [
      760000, // stage 1
      760000, // stage 2
      760000, // stage 3
      760000, // stage 4
      760000, // stage 5
      760000, // stage 6
      760000, // stage 7
      760000, // stage 8
      760000, // stage 9
      759000  // stage 10
    ];
    mapping(address=>bool) isBlacklisted;

    /* ICO stats */
    uint256 public totalSold = 327986072304513072322000; // ! Update on publish
    uint256 public soldOnStage = 327986072304513072322000; // ! Update on publish
    uint8 public currentStage = 0;

    /* Bonus params */
    uint256 public bonus = 0;
    uint256 constant BONUS_COEFF = 1000; // Values should be 10x percents, value 1000 = 100%

    /* Fund params */
    uint256 public amountAtFund = 1000000 * 1 ether; // ! Update un publish
    uint256 public fundLifetime = now + 30 days;


   /**
    * @dev Returns crowdsale status (if active returns true).
    */
    function isActive() public view returns (bool) {
      return !(availableTokens() == 0 || now > endDate);
    }

    /* ICO stats methods */

    /**
     * @dev Returns tokens amount cap for current stage.
     */
    function stageCap() public view returns(uint256) {
      return tokensCap[currentStage].mul(1 ether);
    }

    /**
     * @dev Returns tokens amount available to sell at current stage.
     */
    function availableOnStage() public view returns(uint256) {
        return stageCap().sub(soldOnStage);
    }

    /**
     * @dev Returns base rate (BUL/ETH) of current stage.
     */
    function stageBaseRate() public view returns(uint256) {
      return tokensRate[currentStage];
    }

    /**
     * @dev Returns actual (base + bonus %) rate (BUL/ETH) of current stage.
     */
    function stageRate() public view returns(uint256) {
      return stageBaseRate().mul(BONUS_COEFF.add(bonus)).div(BONUS_COEFF);
    }

    constructor(address token) public {
        require(token != 0x0);
        rewardToken = BulleonToken(token);
    }

    function () payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Main token puchase function
     */
    function buyTokens(address beneficiary) public payable {
      bool validPurchase = beneficiary != 0x0 && msg.value != 0 && !isBlacklisted[msg.sender];
      uint256 currentTokensAmount = availableTokens();
      // Check that ICO is Active and purchase tx is valid
      require(isActive() && validPurchase);

      uint256 boughtTokens;
      uint256 refundAmount = 0;

      // Calculate tokens and refund amount at multiple stage
      uint256[2] memory tokensAndRefund = calcMultiStage();
      boughtTokens = tokensAndRefund[0];
      refundAmount = tokensAndRefund[1];

      // Check that bought tokens amount less then current
      require(boughtTokens < currentTokensAmount);

      totalSold = totalSold.add(boughtTokens); // Increase stats variable

      if(soldOnStage >= stageCap()) {
        toNextStage();
      }

      rewardToken.transfer(beneficiary, boughtTokens);

      if (refundAmount > 0)
          refundMoney(refundAmount);

      withdrawFunds(this.balance);
    }

    /**
     * @dev Forcibility withdraw contract ETH balance.
     */
    function forceWithdraw() public onlyOwner {
      withdrawFunds(this.balance);
    }

    /**
     * @dev Calculate tokens amount and refund amount at purchase procedure.
     */
    function calcMultiStage() internal returns(uint256[2]) {
      uint256 stageBoughtTokens;
      uint256 undistributedAmount = msg.value;
      uint256 _boughtTokens = 0;
      uint256 undistributedTokens = availableTokens();

      while(undistributedAmount > 0 && undistributedTokens > 0) {
        bool needNextStage = false;

        stageBoughtTokens = getTokensAmount(undistributedAmount);

        if (stageBoughtTokens > availableOnStage()) {
          stageBoughtTokens = availableOnStage();
          needNextStage = true;
        }

        _boughtTokens = _boughtTokens.add(stageBoughtTokens);
        undistributedTokens = undistributedTokens.sub(stageBoughtTokens);
        undistributedAmount = undistributedAmount.sub(getTokensCost(stageBoughtTokens));
        soldOnStage = soldOnStage.add(stageBoughtTokens);
        if (needNextStage)
          toNextStage();
      }
      return [_boughtTokens,undistributedAmount];
    }

    /**
     * @dev Sets withdraw wallet address. (called by owner)
     */
    function setWithdraw(address _withdrawWallet) public onlyOwner {
        require(_withdrawWallet != 0x0);
        withdrawWallet = _withdrawWallet;
    }

    /**
     * @dev Make partical refund at purchasing procedure
     */
    function refundMoney(uint256 refundAmount) internal {
      msg.sender.transfer(refundAmount);
    }

    /**
     * @dev Give owner ability to burn some tokens amount at ICO contract
     */
    function burnTokens(uint256 amount) public onlyOwner {
      rewardToken.burn(amount);
    }

    /**
     * @dev Returns costs of given tokens amount
     */
    function getTokensCost(uint256 _tokensAmount) public view returns(uint256) {
      return _tokensAmount.div(stageRate());
    }

    function getTokensAmount(uint256 _amountInWei) public view returns(uint256) {
      return _amountInWei.mul(stageRate());
    }

    /**
     * @dev Switch contract to next stage and reset stage stats
     */
    function toNextStage() internal {
        if (
          currentStage < tokensRate.length &&
          currentStage < tokensCap.length
        ) {
          currentStage++;
          soldOnStage = 0;
        }
    }

    function availableTokens() public view returns(uint256) {
        return rewardToken.balanceOf(address(this)).sub(fundAmount());
    }

    function withdrawFunds(uint256 amount) internal {
        withdrawWallet.transfer(amount);
    }

    function kill() public onlyOwner {
      require(!isActive()); // Check that ICO is Ended (!= Active)
      rewardToken.burn(availableTokens()); // Burn tokens
      selfdestruct(owner); // Destruct ICO contract
    }

    function setBonus(uint256 bonusAmount) public onlyOwner {
      require(
        bonusAmount < 100 * BONUS_COEFF &&
        bonusAmount > 0
      );
      bonus = bonusAmount;
    }

    function fundAmount() public view returns(uint256) {
      return (now >= fundLifetime) ? 0 : amountAtFund;
    }

    function unlockReserve() public onlyOwner {
      fundLifetime = 0; // Sets lifetime of fund to 0 = fund amount sets to 0
    }

    function sendTo(address beneficiary, uint256 amount) public onlyOwner {
      // require(amount <= fundAmount()); // It's will be checked by SafeMath sub() require at next line.
      // Check that fund have tokens to transfer
      amountAtFund = fundAmount().sub(amount);
      rewardToken.transfer(beneficiary, amount);
    }

    function addBlacklist(address wallet) public onlyOwner {
      require(!isBlacklisted[wallet]);
      isBlacklisted[wallet] = true;
      emit AddedToBlacklist(wallet);
    }

    function delBlacklist(address wallet) public onlyOwner {
      require(isBlacklisted[wallet]);
      isBlacklisted[wallet] = false;
      emit RemovedFromBlacklist(wallet);
    }
}
