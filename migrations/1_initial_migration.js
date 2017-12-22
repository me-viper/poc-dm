var Migrations = artifacts.require("./Migrations.sol");
var ManagerContract = artifacts.require("./ManagerContract.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(ManagerContract);
};
