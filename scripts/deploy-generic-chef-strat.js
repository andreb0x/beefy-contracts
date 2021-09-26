import hardhat, { web3 } from "hardhat";

import { addressBook } from "blockchain-addressbook";
import { setCorrectCallFee } from "../utils/setCorrectCallFee";
import { predictAddresses } from "../utils/predictAddresses";

const registerSubsidy = require("../utils/registerSubsidy");

const { USDC: { address: USDC}, WMATIC: {address: WMATIC }, polyWISE: { address: polyWISE} } = addressBook.polygon.tokens;
const { polywise, quickswap, beefyfinance } = addressBook.polygon.platforms;

const ethers = hardhat.ethers;

const want = web3.utils.toChecksumAddress("0x2F9209Ef6fA6C002bf6fC99124336e24F88B62D0");

const vaultParams = {
  mooName: "Moo Polywise Quick USDC-WISE",
  mooSymbol: "mooPolywiseQuickUSDC-WISE",
  delay: 21600,
}

const strategyParams = {
  want: want,
  poolId: 1,
  chef: polywise.masterchef,
  unirouter: quickswap.router,
  strategist: "0x010dA5FF62B6e45f89FA7B2d8CEd5a8b5754eC1b", // some address
  keeper: beefyfinance.keeper,
  beefyFeeRecipient: beefyfinance.beefyFeeRecipient,
  outputToNativeRoute: [ polyWISE, WMATIC ],
  outputToLp0Route: [ polyWISE, USDC ],
  outputToLp1Route: [ polyWISE ],
  pendingRewardsFunctionName: "pendingWise" // used for rewardsAvailable(), use correct function name from masterchef
};

const contractNames = {
  vault: "BeefyVaultV6",
  strategy: "StrategyCommonChefLP"
}

async function main() {
  if (Object.values(vaultParams).some((v) => v === undefined) || Object.values(strategyParams).some((v) => v === undefined) || Object.values(contractNames).some((v) => v === undefined)) {
    console.error("one of config values undefined");
    return;
  }

  await hardhat.run("compile");

  const Vault = await ethers.getContractFactory(contractNames.vault);
  const Strategy = await ethers.getContractFactory(contractNames.strategy);

  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying:", vaultParams.mooName);

  const predictedAddresses = await predictAddresses({ creator: deployer.address });

  const vault = await Vault.deploy(predictedAddresses.strategy, vaultParams.mooName, vaultParams.mooSymbol, vaultParams.delay);
  await vault.deployed();

  const strategy = await Strategy.deploy(
    strategyParams.want,
    strategyParams.poolId,
    strategyParams.chef,
    vault.address,
    strategyParams.unirouter,
    strategyParams.keeper,
    strategyParams.strategist,
    strategyParams.beefyFeeRecipient,
    strategyParams.outputToNativeRoute,
    strategyParams.outputToLp0Route,
    strategyParams.outputToLp1Route
  );
  await strategy.deployed();

  // post deploy
  await strategy.setPendingRewardsFunctionName(strategyParams.pendingRewardsFunctionName);
  await setCorrectCallFee(hardhat.network.name, strategy);

  console.log("Vault deployed to:", vault.address);
  console.log("Strategy deployed to:", strategy.address);
  console.log("Want:", strategyParams.want);

  if (hardhat.network.name === "bsc") {
    await registerSubsidy(vault.address, deployer);
    await registerSubsidy(strategy.address, deployer);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });