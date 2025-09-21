/*
 /$$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$$$  /$$$$$$      /$$$$$$$$ /$$$$$$$$ /$$   /$$
| $$__  $$ /$$__  $$| $$_____/|_____ $$  /$$__  $$    | $$_____/|__  $$__/| $$  | $$
| $$  \ $$| $$  \ $$| $$           /$$/ | $$  \ $$    | $$         | $$   | $$  | $$
| $$$$$$$ | $$$$$$$$| $$$$$       /$$/  | $$$$$$$$    | $$$$$      | $$   | $$$$$$$$
| $$__  $$| $$__  $$| $$__/      /$$/   | $$__  $$    | $$__/      | $$   | $$__  $$
| $$  \ $$| $$  | $$| $$        /$$/    | $$  | $$    | $$         | $$   | $$  | $$
| $$$$$$$/| $$  | $$| $$$$$$$$ /$$$$$$$$| $$  | $$ /$$| $$$$$$$$   | $$   | $$  | $$
|_______/ |__/  |__/|________/|________/|__/  |__/|__/|________/   |__/   |__/  |__/

- WEBSITE: https://baeza.me
- TWITTER: https://x.com/cjbazilla
- GITHUB: https://github.com/cjbaezilla
- TELEGRAM: https://t.me/VELVET_T_99
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleNFT is ERC721 {
    uint256 private _nextTokenId = 1;
    uint256 public constant MINT_PRICE = 1 ether;
    
    string private _baseTokenURI;
    address private _deployer;
    address[] public nftHolders;
    
    event TokenMinted(address indexed to, uint256 indexed tokenId, uint256 price);
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseURI;
        _deployer = msg.sender;
    }
    
    function mint() public payable returns (uint256) {
        require(msg.value == MINT_PRICE, "Debe enviar exactamente 1 PES para mintear");
        
        uint256 tokenId = _nextTokenId;
        unchecked {
            ++_nextTokenId;
        }
        
        _safeMint(msg.sender, tokenId);
        nftHolders.push(msg.sender);
        
        payable(_deployer).transfer(msg.value);
        
        emit TokenMinted(msg.sender, tokenId, MINT_PRICE);
        
        return tokenId;
    }
    
    function mintBatch(uint256 quantity) public payable {
        require(quantity > 0, "La cantidad debe ser mayor a 0");
        require(msg.value == MINT_PRICE * quantity, "Debe enviar el precio correcto para la cantidad");
        
        uint256 startTokenId = _nextTokenId;
        unchecked {
            _nextTokenId += quantity;
        }
        
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, startTokenId + i);
            nftHolders.push(msg.sender);
            emit TokenMinted(msg.sender, startTokenId + i, MINT_PRICE);
        }
        
        payable(_deployer).transfer(MINT_PRICE * quantity);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _baseTokenURI;
    }
    
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory newBaseURI) public {
        require(bytes(newBaseURI).length > 0, "La URI base no puede estar vacia");
        _baseTokenURI = newBaseURI;
    }
    
    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }
    
    function nextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }
    
    function exists(uint256 tokenId) public view returns (bool) {
        return tokenId > 0 && tokenId < _nextTokenId;
    }
    
    function getMintPrice() public pure returns (uint256) {
        return MINT_PRICE;
    }
}
