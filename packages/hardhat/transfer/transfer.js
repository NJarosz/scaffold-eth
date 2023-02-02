const { ethers } = require("hardhat");
var fs = require('fs');

//for console logging
const DEBUG = false

//Bottle.sol contract Address
const CONTRACT_ADR = "0x917624F66D2399A5E017BA984A11843975102026";

//specifies sepolia infura id
const PROVIDER_URL = process.env.PROVIDER;
let provider = ethers.getDefaultProvider(PROVIDER_URL);

//connects to the EOA that owns Bottle.Sol
const MNEMONIC = process.env.MNEMONIC;
const wallet = ethers.Wallet.fromMnemonic(MNEMONIC);
console.log("HD NODE:", wallet);

//instantiates a new signer
const signer = wallet.connect(provider);
if (DEBUG) console.log("WALLET", signer);

//connect with the API
const fsPromises = fs.promises;
const ABI_PATH = '/home/nick/myrepo/scaffold-eth/packages/hardhat/artifacts/contracts/Bottle.sol/Bottle.json';

async function getABI() {
    const data = await fsPromises.readFile(ABI_PATH, 'utf-8');
    const abi = JSON.parse(data)['abi'];
    return abi;
}

//Interact with Smart Contract
async function main() {
    try {
        const abi = await getABI();
        const bottle = new ethers.Contract(CONTRACT_ADR, abi, signer);
        console.log("NEW CONTRACT INSTANCE CREATED");

        let tx = await bottle.transferOwnership("0xeb50dD3Bb9E4F8986eB59A3fFbC9D72a4A3DD1c8");
        await tx.wait();


        console.log("Ownership of Falgene changed to 0xeb50dD3Bb9E4F8986eB59A3fFbC9D72a4A3DD1c8");

    }
    catch (e) {
        console.log("ERROR", e);
    }
}

main();
