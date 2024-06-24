import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import {
	developmentChains,
	VERIFICATION_BLOCK_CONFIRMATIONS,
} from "../helper-hardhat-config";
import { verify } from "../utils/verify";

const basicNft: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
	const { deployments, getNamedAccounts, network, ethers } = hre;
	const { deploy, log } = deployments;
	const { deployer } = await getNamedAccounts();
	const args: any[] = [];
	const waitConfirmations = developmentChains.includes(network.name)
		? 1
		: VERIFICATION_BLOCK_CONFIRMATIONS;

	log("----------------------------------------------------");

	const basicNftContract = await deploy("BasicNFT", {
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
		await verify(basicNftContract.address, args);
		log("Successfully verified!");
	}
};

basicNft.tags = ["all", "basicNft"];
export default basicNft;
