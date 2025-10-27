// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./NFTMarketplaceV1.sol";

contract NFTMarketplaceV2 is NFTMarketplaceV1 {
    // V2 新增功能：批量取消上架
    function batchCancelListings(
        address nftAddress, 
        uint256[] calldata tokenIds
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Listing storage listing = listings[nftAddress][tokenIds[i]];
            if (listing.seller == msg.sender && listing.active) {
                listing.active = false;
                totalListings--;
                emit NFTCancelled(nftAddress, tokenIds[i], msg.sender);
            }
        }
    }

    // V2 新增功能：降低上架费用
    function setReducedListingFee(uint256 _fee) external onlyOwner {
        require(_fee <= 0.001 ether, "Fee too high");
        listingFee = _fee;
    }

    // V2 新增功能：获取市场统计信息
    function getMarketStats() external view returns (
        uint256 _totalListings,
        uint256 _totalSales, 
        uint256 _totalVolume,
        uint256 _currentFee
    ) {
        (uint256 tl, uint256 ts, uint256 tv, uint256 lf) = this.getStats();
        return (tl, ts, tv, lf);
    }
}