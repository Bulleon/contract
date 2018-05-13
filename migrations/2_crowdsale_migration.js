var
  Crowdsale = artifacts.require('./BulleonCrowdsale.sol'),
  Token = artifacts.require('./BulleonToken.sol'),
  CrowdsaleInstance,
  TokenInstance;

module.exports = async function (deployer, network) {
  await deployer.deploy(Crowdsale);

  CrowdsaleInstance = await Crowdsale.deployed();

  await deployer.deploy(Token, CrowdsaleInstance.address);

  await CrowdsaleInstance.attachToken(TokenInstance.address).sendTransaction();
};
