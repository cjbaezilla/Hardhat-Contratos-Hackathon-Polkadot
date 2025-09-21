// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { SimpleNFT } from "../contracts/SimpleNFT.sol";

contract SimpleNFTTest is Test {
    SimpleNFT public nft;
    address public deployer;
    address public user1;
    address public user2;
    
    string constant NAME = "Test NFT";
    string constant SYMBOL = "TNFT";
    string constant BASE_URI = "https://api.example.com/metadata/";
    
    event TokenMinted(address indexed to, uint256 indexed tokenId, uint256 price);
    
    receive() external payable {}
    
    function setUp() public {
        deployer = address(this);
        
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        nft = new SimpleNFT(NAME, SYMBOL, BASE_URI);
        
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(deployer, 10 ether);
    }
    
    function test_Constructor() public view {
        assertEq(nft.name(), NAME);
        assertEq(nft.symbol(), SYMBOL);
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.nextTokenId(), 1);
        assertEq(nft.MINT_PRICE(), 1 ether);
    }
    
    function test_MintInsufficientPayment() public {
        uint256 mintPrice = nft.MINT_PRICE();
        
        vm.prank(user1);
        vm.expectRevert("Debe enviar exactamente 1 PES para mintear");
        nft.mint{value: mintPrice - 1}();
    }
    
    function test_MintExcessivePayment() public {
        uint256 mintPrice = nft.MINT_PRICE();
        
        vm.prank(user1);
        vm.expectRevert("Debe enviar exactamente 1 PES para mintear");
        nft.mint{value: mintPrice + 1}();
    }
    
    function test_MintWithoutPayment() public {
        vm.prank(user1);
        vm.expectRevert("Debe enviar exactamente 1 PES para mintear");
        nft.mint();
    }
    
    function test_MintBatchZeroQuantity() public {
        vm.prank(user1);
        vm.expectRevert("La cantidad debe ser mayor a 0");
        nft.mintBatch{value: 0}(0);
    }
    
    function test_MintBatchInsufficientPayment() public {
        uint256 quantity = 3;
        uint256 totalCost = nft.MINT_PRICE() * quantity;
        
        vm.prank(user1);
        vm.expectRevert("Debe enviar el precio correcto para la cantidad");
        nft.mintBatch{value: totalCost - 1}(quantity);
    }
    
    function test_MintBatchExcessivePayment() public {
        uint256 quantity = 2;
        uint256 totalCost = nft.MINT_PRICE() * quantity;
        
        vm.prank(user1);
        vm.expectRevert("Debe enviar el precio correcto para la cantidad");
        nft.mintBatch{value: totalCost + 1}(quantity);
    }
    
    function test_SetEmptyBaseURI() public {
        vm.expectRevert("La URI base no puede estar vacia");
        nft.setBaseURI("");
    }
    
    function test_SetBaseURI() public {
        string memory newURI = "https://new-api.example.com/metadata/";
        
        nft.setBaseURI(newURI);
        
        assertEq(nft.getBaseURI(), newURI);
    }
    
    function test_GetBaseURI() public view {
        assertEq(nft.getBaseURI(), BASE_URI);
    }
    
    function test_TokenURIReturnsBaseURI() public {
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        assertEq(nft.tokenURI(1), BASE_URI);
    }
    
    function test_AllTokensSameURI() public {
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        vm.prank(user2);
        nft.mint{value: 1 ether}();
        
        vm.prank(user1);
        nft.mintBatch{value: 2 ether}(2);
        
        assertEq(nft.tokenURI(1), BASE_URI);
        assertEq(nft.tokenURI(2), BASE_URI);
        assertEq(nft.tokenURI(3), BASE_URI);
        assertEq(nft.tokenURI(4), BASE_URI);
    }
    
    function test_TokenURIAfterBaseURIChange() public {
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        string memory newURI = "https://new-api.example.com/metadata/";
        nft.setBaseURI(newURI);
        
        assertEq(nft.tokenURI(1), newURI);
        
        vm.prank(user2);
        nft.mint{value: 1 ether}();
        
        assertEq(nft.tokenURI(2), newURI);
    }
    
    function test_TotalSupplyInitial() public view {
        assertEq(nft.totalSupply(), 0);
    }
    
    function test_NextTokenIdInitial() public view {
        assertEq(nft.nextTokenId(), 1);
    }
    
    function test_ExistsNonExistentToken() public view {
        assertEq(nft.exists(1), false);
        assertEq(nft.exists(999), false);
    }
    
    function test_MintPriceConstant() public view {
        assertEq(nft.MINT_PRICE(), 1 ether);
    }
    
    function test_ContractDeployment() public view {
        assertEq(nft.name(), NAME);
        assertEq(nft.symbol(), SYMBOL);
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.nextTokenId(), 1);
        assertEq(nft.MINT_PRICE(), 1 ether);
    }
    
    function testFuzz_MintBatchValidation(uint256 quantity) public {
        vm.assume(quantity == 0);
        
        vm.prank(user1);
        vm.expectRevert("La cantidad debe ser mayor a 0");
        nft.mintBatch{value: 0}(quantity);
    }
    
    function test_NFTHoldersArrayInitial() public {
        vm.expectRevert();
        nft.nftHolders(0);
    }
    
    function test_NFTHoldersArrayAfterMint() public {
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        assertEq(nft.nftHolders(0), user1);
        vm.expectRevert();
        nft.nftHolders(1);
    }
    
    function test_NFTHoldersArrayAfterMultipleMints() public {
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        vm.prank(user2);
        nft.mint{value: 1 ether}();
        
        assertEq(nft.nftHolders(0), user1);
        assertEq(nft.nftHolders(1), user2);
    }
    
    function test_NFTHoldersArrayAfterMintBatch() public {
        uint256 quantity = 3;
        vm.prank(user1);
        nft.mintBatch{value: 3 ether}(quantity);
        
        assertEq(nft.nftHolders(0), user1);
        assertEq(nft.nftHolders(1), user1);
        assertEq(nft.nftHolders(2), user1);
        vm.expectRevert();
        nft.nftHolders(3);
    }
    
    function test_NFTHoldersArrayMixedMints() public {
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        vm.prank(user2);
        nft.mintBatch{value: 2 ether}(2);
        
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        assertEq(nft.nftHolders(0), user1);
        assertEq(nft.nftHolders(1), user2);
        assertEq(nft.nftHolders(2), user2);
        assertEq(nft.nftHolders(3), user1);
    }
    
    function test_GetMintPrice() public view {
        assertEq(nft.getMintPrice(), 1 ether);
    }
    
    function test_GetMintPriceVsConstant() public view {
        assertEq(nft.getMintPrice(), nft.MINT_PRICE());
    }
    
    function test_MintBatchSingleToken() public {
        vm.prank(user1);
        nft.mintBatch{value: 1 ether}(1);
        
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.nextTokenId(), 2);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.nftHolders(0), user1);
    }
    
    function test_MintBatchLargeQuantity() public {
        uint256 quantity = 100;
        uint256 totalCost = 1 ether * quantity;
        
        vm.deal(user1, totalCost + 1 ether);
        
        vm.prank(user1);
        nft.mintBatch{value: totalCost}(quantity);
        
        assertEq(nft.totalSupply(), quantity);
        assertEq(nft.nextTokenId(), quantity + 1);
        
        for (uint256 i = 1; i <= quantity; i++) {
            assertEq(nft.ownerOf(i), user1);
            assertEq(nft.exists(i), true);
        }
    }
    
    function test_ExistsWithZeroTokenId() public view {
        assertEq(nft.exists(0), false);
    }
    
    function test_ExistsWithMaxTokenId() public view {
        assertEq(nft.exists(type(uint256).max), false);
    }
    
    function test_TokenURIWithZeroTokenId() public {
        vm.expectRevert();
        nft.tokenURI(0);
    }
    
    function test_TokenURIWithMaxTokenId() public {
        vm.expectRevert();
        nft.tokenURI(type(uint256).max);
    }
    
    function test_SetBaseURIWithLongString() public {
        string memory longURI = "https://very-long-domain-name-that-exceeds-normal-limits.example.com/api/v1/metadata/tokens/with/very/long/path/";
        
        nft.setBaseURI(longURI);
        assertEq(nft.getBaseURI(), longURI);
    }
    
    function test_SetBaseURIWithSpecialCharacters() public {
        string memory specialURI = "https://api.example.com/metadata/?token=%20&special=chars#fragment";
        
        nft.setBaseURI(specialURI);
        assertEq(nft.getBaseURI(), specialURI);
        
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        assertEq(nft.tokenURI(1), specialURI);
    }
    
    function test_CompleteIntegrationFlow() public {
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        vm.prank(user2);
        nft.mintBatch{value: 3 ether}(3);
        
        string memory newURI = "https://new-api.example.com/metadata/";
        nft.setBaseURI(newURI);
        
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        assertEq(nft.totalSupply(), 5);
        assertEq(nft.nextTokenId(), 6);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user2);
        assertEq(nft.ownerOf(3), user2);
        assertEq(nft.ownerOf(4), user2);
        assertEq(nft.ownerOf(5), user1);
        
        assertEq(nft.tokenURI(1), newURI);
        assertEq(nft.tokenURI(2), newURI);
        assertEq(nft.tokenURI(5), newURI);
        
        assertEq(nft.nftHolders(0), user1);
        assertEq(nft.nftHolders(1), user2);
        assertEq(nft.nftHolders(2), user2);
        assertEq(nft.nftHolders(3), user2);
        assertEq(nft.nftHolders(4), user1);
    }
    
    function test_GasUsageMintIndividual() public {
        uint256 gasStart = gasleft();
        
        vm.prank(user1);
        nft.mint{value: 1 ether}();
        
        uint256 gasUsed = gasStart - gasleft();
        emit log_named_uint("Gas usado para mint individual", gasUsed);
        
        assertTrue(gasUsed > 0);
    }
    
    function test_GasUsageMintBatch() public {
        uint256 quantity = 5;
        uint256 totalCost = 1 ether * quantity;
        
        uint256 gasStart = gasleft();
        
        vm.prank(user1);
        nft.mintBatch{value: totalCost}(quantity);
        
        uint256 gasUsed = gasStart - gasleft();
        emit log_named_uint("Gas usado para mint batch (5 tokens)", gasUsed);
        
        assertTrue(gasUsed > 0);
    }
    
    function testFuzz_MintBatchQuantity(uint256 quantity) public {
        vm.assume(quantity > 0 && quantity <= 1000); // Límites razonables
        uint256 totalCost = 1 ether * quantity;
        
        vm.deal(user1, totalCost + 1 ether);
        
        vm.prank(user1);
        nft.mintBatch{value: totalCost}(quantity);
        
        assertEq(nft.totalSupply(), quantity);
        assertEq(nft.nextTokenId(), quantity + 1);
    }
    
    function testFuzz_ExistsFunction(uint256 tokenId) public {
        vm.assume(tokenId > 0 && tokenId <= 50);
        
        vm.deal(user1, 100 ether);
        
        vm.prank(user1);
        nft.mintBatch{value: 50 ether}(50);
        
        assertTrue(nft.exists(tokenId));
    }
    
    function test_TokenMintedEventParameters() public {
        vm.expectEmit(true, true, false, true);
        emit TokenMinted(user1, 1, 1 ether);
        
        vm.prank(user1);
        nft.mint{value: 1 ether}();
    }
    
    function test_TokenMintedEventsInBatch() public {
        uint256 quantity = 3;
        
        for (uint256 i = 1; i <= quantity; i++) {
            vm.expectEmit(true, true, false, true);
            emit TokenMinted(user1, i, 1 ether);
        }
        
        vm.prank(user1);
        nft.mintBatch{value: 3 ether}(quantity);
    }
    
}