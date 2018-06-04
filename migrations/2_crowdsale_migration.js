var
  Crowdsale = artifacts.require('./BulleonCrowdsale.sol'),
  Token = artifacts.require('./BulleonToken.sol'),
  Multitransfer = artifacts.require('./Multitransfer.sol'),
  CrowdsaleInstance,
  TokenInstance;

module.exports = async function (deployer, network) {
  await deployer.deploy(Token);
  TokenInstance = await Token.deployed();

  await deployer.deploy(Crowdsale, TokenInstance.address);
  CrowdsaleInstance = await Crowdsale.deployed();

  await TokenInstance.setCrowdsaleAddress(CrowdsaleInstance.address);
  await deployer.deploy(Multitransfer, TokenInstance.address, web3.eth.coinbase);
};
