import { ethers } from "hardhat";

const PRICE = ethers.utils.parseEther("0.1");

async function mintAndList() {
	const nftMarketPlace = await ethers.getContract("NftMarketplace");
	const basicNFT = await ethers.getContract("BasicNFT");

	console.log("Minting...");
	const mintTx = await basicNFT.mintNft();
	const mintReceipt = await mintTx.wait(1);
	const tokenId = mintReceipt.events[0].args.tokenId;

	console.log("Approving NFT...");
	const approvalTx = await basicNFT.approve(nftMarketPlace.address, tokenId);
	await approvalTx.wait(1);

	const listTx = await nftMarketPlace.listItem(
		basicNFT.address,
		tokenId,
		PRICE
	);
	await listTx.wait(1);
	console.log("Listed!");
}

mintAndList()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
