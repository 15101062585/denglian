// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarketplaceV1.sol";
import "../src/NFTMarketplaceV2.sol";
import "../src/upgrades/UpgradeableProxy.sol";

contract NFTMarketplaceTest is Test {
    MyNFT public nft;
    NFTMarketplaceV1 public marketV1;
    NFTMarketplaceV2 public marketV2;
    UpgradeableProxy public proxy;
    
    address public admin = makeAddr("admin");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    
    uint256 public constant PRICE = 1 ether;

    function setUp() public {
        // 设置管理员
        vm.deal(admin, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        
        vm.startPrank(admin);

        // 部署 NFT 合约
        nft = new MyNFT("Test NFT", "TNFT");
        

        //部署 V1 实现合约
        marketV1 = new NFTMarketplaceV1();

        //部署代理合约 - 使用正确的初始化数据
        bytes memory initData = abi.encodeWithSelector(NFTMarketplaceV1.initialize().selector, admin);
        proxy = new UpgradeableProxy(address(marketV1), admin, initData);
        
        // 获取代理合约实例
        marketV1 = NFTMarketplaceV1(address(proxy));

        // 铸造 NFT
        nft.mint(user1);
        nft.mint(user1);

        vm.stopPrank();

        // 用户授权市场合约
        vm.prank(user1);
        nft.setApprovalForAll(address(marketV1), true);
       
    }

    function test_Initialization() public view {
        assertEq(marketV1.getTotalListings(), 0);
        assertEq(marketV1.getTotalSales(), 0);
        assertEq(marketV1.getTotalVolume(), 0);
        assertEq(marketV1.getListingFee(), 0);
        
        assertEq(marketV1.owner(), admin);
    }

    function test_ListAndBuyNFT() public {
        // 用户1上架 NFT
        vm.prank(user1);
        marketV1.listNFT(address(nft), 1, PRICE);

        // 验证上架状态
        (address seller, uint256 price, bool active) = marketV1.listings(address(nft), 1);
        assertEq(seller, user1);
        assertEq(price, PRICE);
        assertTrue(active);
        assertEq(marketV1.getTotalListings(), 1);

        // 用户2购买 NFT
        vm.prank(user2);
        marketV1.buyNFT{value: PRICE}(address(nft), 1);

        // 验证购买后的状态
        assertEq(nft.ownerOf(1), user2);
        (seller, price, active) = marketV1.listings(address(nft), 1);
        assertFalse(active);
        assertEq(marketV1.getTotalListings(), 0);
        assertEq(marketV1.getTotalSales(), 1);
        assertEq(marketV1.getTotalVolume(), PRICE);
    }

    function test_UpgradeToV2() public {
        // 先创建一些状态
        vm.prank(user1);
        marketV1.listNFT(address(nft), 1, PRICE);

        uint256 totalListingsBefore = marketV1.getTotalListings();
        
        // 部署 V2
        vm.prank(admin);
        marketV2 = new NFTMarketplaceV2();

        // 升级代理合约
        vm.prank(admin);
        proxy.upgradeTo(address(marketV2));

        // 获取升级后的合约实例
        marketV2 = NFTMarketplaceV2(address(proxy));

        // 验证状态保持
        assertEq(marketV2.getTotalListings(), totalListingsBefore);
        
        (address seller, uint256 price, bool active) = marketV2.listings(address(nft), 1);
        assertEq(seller, user1);
        assertEq(price, PRICE);
        assertTrue(active);
    }

    function test_CancelListing() public {
        vm.prank(user1);
        marketV1.listNFT(address(nft), 1, PRICE);

        assertEq(marketV1.getTotalListings(), 1);

        vm.prank(user1);
        marketV1.cancelListing(address(nft), 1);

        assertEq(marketV1.getTotalListings(), 0);
        
        (, , bool active) = marketV1.listings(address(nft), 1);
        assertFalse(active);
    }

    function test_Revert_WhenNotOwnerLists() public {
        vm.prank(user2);
        vm.expectRevert("Not the owner");
        marketV1.listNFT(address(nft), 1, PRICE);
    }

    function test_Revert_WhenNotApproved() public {
        // 用户2没有授权市场合约
        vm.prank(user2);
        vm.expectRevert("Marketplace not approved");
        marketV1.listNFT(address(nft), 3, PRICE); // tokenId 3 属于 admin
    }
}