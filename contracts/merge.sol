// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMerger is ERC721 {
    uint256 public tokenIdCounter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        tokenIdCounter = 1; // Start with token ID 1
    }

    // Function to merge two NFTs and mint a new NFT
    function mergeAndMintNFT(address token1Address, uint256 token1Id, address token2Address, uint256 token2Id) external {
        
        require(msg.sender == ERC721(token1Address).ownerOf(token1Id) && msg.sender == ERC721(token2Address).ownerOf(token2Id), "You must own both NFTs.");

        // Get the token URIs of the two NFTs (you may need to implement the metadata retrieval in the ERC721 contract)
        string memory token1URI = ERC721(token1Address).tokenURI(token1Id);
        string memory token2URI = ERC721(token2Address).tokenURI(token2Id);

        // Merge the token URIs to create a new token URI for the merged NFT
        string memory mergedURI = string(abi.encodePacked(token1URI, "-", token2URI));

        // Mint a new NFT with the mergedURI as metadata and assign it to the caller
        _mint(msg.sender, tokenIdCounter);
        _setTokenURI(tokenIdCounter, mergedURI);

        // Increment the tokenIdCounter for the next minted NFT
        tokenIdCounter++;
    }
}
