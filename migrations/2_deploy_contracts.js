const TestToken = artifacts.require("TestToken");
const TimeLock = artifacts.require("ERC20Timelock");

module.exports = async(deployer, network, accounts) => { 
  let deployOne = await deployer.deploy(TestToken);
  TestTokenInstance  = await TestToken.deployed();
  let deployTwo = await deployer.deploy(TimeLock, accounts[0], TestTokenInstance.address);  
  TimeLockInstance = await TimeLock.deployed();
};
