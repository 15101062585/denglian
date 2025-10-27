// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplaceV1 is Initializable, OwnableUpgradeable {
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    uint256 public totalListings;
    
    event NFTListed(address indexed nftAddress, uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(address indexed nftAddress, uint256 indexed tokenId, address indexed buyer, uint256 price);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        totalListings = 0;
    }

    function listNFT(address nftAddress, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "Not the owner");
        require(IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");

        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });
        totalListings++;

        emit NFTListed(nftAddress, tokenId, msg.sender, price);
    }

    function buyNFT(address nftAddress, uint256 tokenId) external payable {
        Listing storage listing = listings[nftAddress][tokenId];
        require(listing.active, "NFT not for sale");
        require(msg.value == listing.price, "Incorrect price");

        listing.active = false;
        totalListings--;

        IERC721(nftAddress).transferFrom(listing.seller, msg.sender, tokenId);
        payable(listing.seller).transfer(msg.value);

        emit NFTSold(nftAddress, tokenId, msg.sender, msg.value);
    }
}