// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol"; // Import the ERC-721 interface

contract NFTMarketplace {
    address public owner;
    uint256 public listingFee; // Fee to list an NFT for sale
    uint256 public nextListingId;

    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Listing) public listings;

    event NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);
    event NFTSold(uint256 indexed listingId, address indexed buyer, address indexed seller, address nftContract, uint256 tokenId, uint256 price);

    constructor(uint256 _listingFee) {
        owner = msg.sender;
        listingFee = _listingFee;
        nextListingId = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function setListingFee(uint256 _listingFee) external onlyOwner {
        listingFee = _listingFee;
    }

    function listNFTForSale(address nftContract, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than zero.");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "You don't own this NFT.");

        // Transfer the NFT to the marketplace contract temporarily
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // Create a new listing
        listings[nextListingId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            active: true
        });

        emit NFTListed(nextListingId, msg.sender, nftContract, tokenId, price);
        nextListingId++;
    }

    function buyNFT(uint256 listingId) external payable {
        Listing memory listing = listings[listingId];
        require(listing.active, "Listing is not active.");
        require(msg.value >= listing.price, "Insufficient payment.");

        // Transfer the NFT to the buyer
        IERC721(listing.nftContract).transferFrom(address(this), msg.sender, listing.tokenId);

        // Transfer the payment to the seller
        listing.seller.transfer(listing.price);

        // Deactivate the listing
        listings[listingId].active = false;

        emit NFTSold(listingId, msg.sender, listing.seller, listing.nftContract, listing.tokenId, listing.price);
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(owner).transfer(balance);
    }
}
