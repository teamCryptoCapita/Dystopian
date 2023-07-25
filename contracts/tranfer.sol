// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC721 standard interface
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Define your smart contract that inherits from ERC721
contract NFTOwnershipTransfer is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Function to transfer ownership of an NFT to another address
    function transferOwnership(address to, uint256 tokenId) external {
        // Ensure the caller is the current owner of the NFT
        require(msg.sender == ownerOf(tokenId), "You must be the owner of the NFT.");

        // Transfer the NFT to the new owner
        _transfer(msg.sender, to, tokenId);
    }
}
