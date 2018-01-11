var ManagerContract = artifacts.require("./ManagerContract.sol");

module.exports = function(deployer) {
  deployer.deploy(ManagerContract);
};
