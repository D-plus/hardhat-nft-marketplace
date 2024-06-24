import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import {
	developmentChains,
	VERIFICATION_BLOCK_CONFIRMATIONS,
} from "../helper-hardhat-config";
import { verify } from "../utils/verify";

const nftMarketPlace: DeployFunction = async (
	hre: HardhatRuntimeEnvironment
) => {
	const { deployments, getNamedAccounts, network, ethers } = hre;
	const { deploy, log } = deployments;
	const { deployer } = await getNamedAccounts();
	const args: any[] = [];
	const waitConfirmations = developmentChains.includes(network.name)
		? 1
		: VERIFICATION_BLOCK_CONFIRMATIONS;

	log("----------------------------------------------------");

	const nftMarketPlaceContract = await deploy("NftMarketplace", {
		from: deployer,
		args,
		log: true,
		waitConfirmations,
	});

	log("----------------------------------------------------");

	if (
		!developmentChains.includes(network.name) &&
		process.env.ETHERSCAN_API_KEY
	) {
		log("Verifying...");
		await verify(nftMarketPlaceContract.address, args);
		log("Successfully verified!");
	}
};

nftMarketPlace.tags = ["all", "nftmarketplace"];
export default nftMarketPlace;
