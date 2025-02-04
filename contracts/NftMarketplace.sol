// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error PriceMustBeMoreThanZero();
error NotApprovedForMarketPlace();
error AlreadyListed(address nftAddress, uint256 tokenId);
error NotOwner();
error NotListed(address nftAddress, uint256 tokenId);
error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error NoProceeds();
error TransferFailed();

contract NftMarketplace is ReentrancyGuard {
	struct Listing {
		uint256 price;
		address seller;
	}

	event ItemListed(
		address indexed seller,
		address indexed nftAddress,
		uint256 tokenId,
		uint256 price
	);

	event ItemBought(
		address indexed buyer,
		address indexed nftAddress,
		uint256 indexed tokenId,
		uint256 price
	);

	event ItemCanceled(
		address indexed owner,
		address indexed nftAddress,
		uint256 indexed tokenId
	);

	// NFT Contract address -> NFT TokenID -> Listing
	mapping(address => mapping(uint256 => Listing)) private s_listings;

	// Seller address -> amount earned
	mapping(address => uint256) private s_proceeds;

	constructor() {}

	////////////////////
	// Modifiers     //
	////////////////////

	modifier notListed(
		address nftAddress,
		uint256 tokenId,
		address owner
	) {
		Listing memory listing = s_listings[nftAddress][tokenId];

		if (listing.price > 0) {
			revert AlreadyListed(nftAddress, tokenId);
		}
		_;
	}

	modifier isOwner(
		address nftAddress,
		uint256 tokenId,
		address spender
	) {
		IERC721 nft = IERC721(nftAddress);
		address nftOwner = nft.ownerOf(tokenId);

		if (spender != nftOwner) {
			revert NotOwner();
		}
		_;
	}

	modifier isListed(address nftAddress, uint256 tokenId) {
		Listing memory listing = s_listings[nftAddress][tokenId];
		if (listing.price <= 0) {
			revert NotListed(nftAddress, tokenId);
		}
		_;
	}

	////////////////////
	// Main functions //
	////////////////////

	/*
	 * @notice Method for listing NFT
	 * @param nftAddress Address of NFT contract
	 * @param tokenId Token ID of NFT
	 * @param price sale price for each item
	 */
	function listItem(
		address nftAddress,
		uint256 tokenId,
		uint256 price
	)
		external
		isOwner(nftAddress, tokenId, msg.sender)
		notListed(nftAddress, tokenId, msg.sender)
	{
		if (price <= 0) {
			revert PriceMustBeMoreThanZero();
		}

		// Make sure if market place is approved to work with a NFT
		IERC721 nft = IERC721(nftAddress);
		if (nft.getApproved(tokenId) != address(this)) {
			// if it is not approved
			revert NotApprovedForMarketPlace();
		}

		s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
		emit ItemListed(msg.sender, nftAddress, tokenId, price);
	}

	// nonReentrant (is called "Mutex") comes from ReentrancyGuard
	function buyItem(
		address nftAddress,
		uint256 tokenId
	) external payable nonReentrant isListed(nftAddress, tokenId) {
		Listing memory listedItem = s_listings[nftAddress][tokenId];

		if (msg.value < listedItem.price) {
			revert PriceNotMet(nftAddress, tokenId, listedItem.price);
		}

		// store money for nft in the s_proceeds structure, to have user withdraw the money on demand
		s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;

		delete (s_listings[nftAddress][tokenId]);

		// transfer ownership of a NFT
		IERC721(nftAddress).safeTransferFrom(
			listedItem.seller,
			msg.sender,
			tokenId
		);

		emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
	}

	function cancelListing(
		address nftAddress,
		uint256 tokenId
	)
		external
		isOwner(nftAddress, tokenId, msg.sender)
		isListed(nftAddress, tokenId)
	{
		delete (s_listings[nftAddress][tokenId]);

		emit ItemCanceled(msg.sender, nftAddress, tokenId);
	}

	function updateListing(
		address nftAddress,
		uint256 tokenId,
		uint256 newPrice
	)
		external
		isOwner(nftAddress, tokenId, msg.sender)
		isListed(nftAddress, tokenId)
	{
		s_listings[nftAddress][tokenId].price = newPrice;

		emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
	}

	function withdrawProceeds() external {
		uint256 proceeds = s_proceeds[msg.sender];
		if (proceeds <= 0) {
			revert NoProceeds();
		}

		s_proceeds[msg.sender] = 0;

		(bool success, ) = payable(msg.sender).call{value: proceeds}("");

		if (!success) {
			revert TransferFailed();
		}
	}

	////////////////////
	// Getter functions //
	////////////////////

	function getListing(
		address nftAddress,
		uint256 tokenId
	) external view returns (Listing memory) {
		return s_listings[nftAddress][tokenId];
	}

	function getProceeds(address seller) external view returns (uint256) {
		return s_proceeds[seller];
	}
}
