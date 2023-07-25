// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol"; // Import the ERC-721 interface

contract NFTCollection is IERC721 {
    address public owner;
    string public name;
    string public symbol;
    uint256 private nextTokenId;

    struct Token {
        address owner;
        string metadata;
    }

    mapping(uint256 => Token) private _tokens;
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => uint256) private _ownedTokensCount;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        nextTokenId = 1;
    }

    function mint(string calldata metadata) external {
        uint256 tokenId = nextTokenId;
        _mint(msg.sender, tokenId, metadata);
        nextTokenId++;
    }

    function _mint(address to, uint256 tokenId, string memory metadata) internal {
        require(to != address(0), "Invalid address");
        require(_tokens[tokenId].owner == address(0), "Token already exists");

        Token memory newToken = Token({
            owner: to,
            metadata: metadata
        });

        _tokens[tokenId] = newToken;
        _ownedTokensCount[to]++;
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length - 1;

        emit Transfer(address(0), to, tokenId);
    }

    function balanceOf(address owner) external view override returns (uint256 balance) {
        require(owner != address(0), "Invalid address");
        return _ownedTokensCount[owner];
    }

    function ownerOf(uint256 tokenId) external view override returns (address owner) {
        return _tokens[tokenId].owner;
    }

    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view override returns (address operator) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        require(msg.sender != operator, "Approval to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer not authorized");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer not authorized");
        _transfer(from, to, tokenId);
        // Check if the recipient is a smart contract and if it supports ERC721Receiver
        if (_isContract(to)) {
            bytes4 onERC721Received = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
            require(onERC721Received == 0x150b7a02, "Transfer to non ERC721Receiver implementer");
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Transfer of token that is not owned");
        require(to != address(0), "Transfer to the zero address");
        require(to != address(this), "Transfer to the contract itself");

        _clearApproval(tokenId);

        uint256[] storage fromTokenList = _ownedTokens[from];
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // Move the last token to the position of the token to delete
        uint256 lastTokenId = fromTokenList[fromTokenList.length - 1];
        fromTokenList[tokenIndex] = lastTokenId;
        _
