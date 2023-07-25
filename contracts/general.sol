// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

contract NFTMerger is IERC721 {
    string public constant name = "NFT Merger";
    string public constant symbol = "NFTM";

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
    bool private _allowAll;

    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        _;
    }

    modifier validToken(uint256 tokenId) {
        require(_tokens[tokenId].owner != address(0), "Invalid token");
        _;
    }

    function balanceOf(address owner) external view override returns (uint256 balance) {
        require(owner != address(0), "Invalid address");
        return _ownedTokensCount[owner];
    }

    function ownerOf(uint256 tokenId) external view override validToken(tokenId) returns (address owner) {
        return _tokens[tokenId].owner;
    }

    function approve(address to, uint256 tokenId) external override onlyOwnerOf(tokenId) {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view override validToken(tokenId) returns (address operator) {
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

    function mergeAndMint(address nft1, uint256 tokenId1, address nft2, uint256 tokenId2, string calldata mergedMetadata) external {
        require(ownerOf(tokenId1) == msg.sender, "You don't own NFT1");
        require(ownerOf(tokenId2) == msg.sender, "You don't own NFT2");

        uint256 newTokenId = uint256(keccak256(abi.encodePacked(tokenId1, tokenId2)));
        _mint(msg.sender, newTokenId, mergedMetadata);
        _transfer(msg.sender, address(this), tokenId1);
        _transfer(msg.sender, address(this), tokenId2);
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

    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "You don't own this NFT");

        _clearApproval(tokenId);

        uint256[] storage tokenList = _ownedTokens[owner];
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // Move the last token to the position of the token to delete
        uint256 lastTokenId = tokenList[tokenList.length - 1];
        tokenList[tokenIndex] = lastTokenId;
        _ownedTokensIndex[lastTokenId] = tokenIndex;

        // Delete the last element (pop)
        tokenList.pop();

        // Decrease the owned token count
        _ownedTokensCount[owner]--;

        // Clear the token owner and token metadata
        delete _tokens[tokenId];
        delete _ownedTokensIndex[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        _ownedTokensIndex[lastTokenId] = tokenIndex;

        // Delete the last element (pop)
        fromTokenList.pop();

        // Update
