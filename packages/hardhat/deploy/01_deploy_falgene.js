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

  // console.log("\n 🤹  Sending ownership to frontend address...\n");
  // //Checkpoint 2: change address to your frontend address vvvv
  // const ownerTx = await Falgene.transferOwnership("0xeb50dD3Bb9E4F8986eB59A3fFbC9D72a4A3DD1c8");
  // const ownerTx2 = await Hydrate.transferOwnership("0xeb50dD3Bb9E4F8986eB59A3fFbC9D72a4A3DD1c8");

  // console.log("\n       confirming...\n");
  // const ownershipResult = await ownerTx.wait();
  // const ownershipResult2 = await ownerTx2.wait();
  // if (ownershipResult && ownershipResult2) {
  //   console.log("       ✅ ownership transferred successfully!\n");
  // }
};
module.exports.tags = ["Falgene"];
