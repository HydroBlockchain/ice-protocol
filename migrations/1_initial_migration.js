// Added line
//var artifacts = require('truffle-artifactor');
const Migrations = artifacts.require("Migrations");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
