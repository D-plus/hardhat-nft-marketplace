const { moveBlocks } = require("../utils/move-blocks");

const BLOCKS = 5;
const SLEEP = 1000;

async function mine() {
	await moveBlocks(BLOCKS, SLEEP);
}

mine()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
