// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("Bottle", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
  });

  // Getting a previously deployed contract
  const Falgene = await ethers.getContract("Bottle", deployer);

  const Hydrate = await ethers.getContract("Hydrate", deployer);

  await Hydrate.setMinter(Falgene.address);
  console.log(`Falgene (${Falgene.address}) set as a Hydrate minter`);

  await Falgene.setHydrate(Hydrate.address);

  console.log(`Hydrate set to ${Hydrate.address} in Falgene`);
};
module.exports.tags = ["Falgene"];
