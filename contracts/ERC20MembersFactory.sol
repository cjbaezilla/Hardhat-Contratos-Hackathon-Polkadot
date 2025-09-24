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

import "./SimpleERC20.sol";
import "./SimpleUserManager.sol";
import "./SimpleNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20MembersFactory is Ownable {
    SimpleUserManager public immutable userManager;
    SimpleNFT public immutable nftContract;
    
    uint256 public MIN_NFTS_REQUIRED = 5;
    
    uint256 public tokenCreationFee = 0.001 ether;
    
    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        uint256 initialSupply,
        uint256 feePaid
    );
    
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event MinNFTsRequiredUpdated(uint256 oldMinNFTs, uint256 newMinNFTs);

    struct TokenInfo {
        address tokenAddress;
        address creator;
        string name;
        string symbol;
        uint256 initialSupply;
        uint256 createdAt;
    }

    mapping(address => TokenInfo[]) public userTokens;
    
    mapping(address => bool) public isTokenCreated;
    
    TokenInfo[] public allTokens;

    constructor(address _userManager, address _nftContract) Ownable(msg.sender) {
        require(_userManager != address(0), "ERC20MembersFactory: UserManager address cannot be zero");
        require(_nftContract != address(0), "ERC20MembersFactory: NFT contract address cannot be zero");
        
        userManager = SimpleUserManager(_userManager);
        nftContract = SimpleNFT(_nftContract);
    }

    function createToken(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) external payable returns (address tokenAddress) {
        require(bytes(name_).length > 0, "ERC20MembersFactory: Name cannot be empty");
        require(bytes(symbol_).length > 0, "ERC20MembersFactory: Symbol cannot be empty");
        
        require(userManager.isRegisteredUser(msg.sender), "ERC20MembersFactory: User must be registered");
        
        uint256 userNFTBalance = nftContract.balanceOf(msg.sender);
        require(userNFTBalance >= MIN_NFTS_REQUIRED, "ERC20MembersFactory: User must have at least 5 NFTs");
        
        require(msg.value >= tokenCreationFee, "ERC20MembersFactory: Insufficient fee paid");
        
        if (msg.value > 0) {
            (bool success, ) = payable(owner()).call{value: msg.value}("");
            require(success, "ERC20MembersFactory: Failed to transfer fee to owner");
        }
        
        SimpleERC20 newToken = new SimpleERC20(name_, symbol_, initialSupply_, msg.sender);
        tokenAddress = address(newToken);
        
        require(tokenAddress != address(0), "ERC20Factory: Token creation failed");
        require(!isTokenCreated[tokenAddress], "ERC20Factory: Token already exists");
        
        TokenInfo memory tokenInfo = TokenInfo({
            tokenAddress: tokenAddress,
            creator: msg.sender,
            name: name_,
            symbol: symbol_,
            initialSupply: initialSupply_,
            createdAt: block.timestamp
        });
        
        userTokens[msg.sender].push(tokenInfo);
        allTokens.push(tokenInfo);
        isTokenCreated[tokenAddress] = true;
        
        emit TokenCreated(tokenAddress, msg.sender, name_, symbol_, initialSupply_, msg.value);
        
        return tokenAddress;
    }

    function getUserTokens(address user) external view returns (TokenInfo[] memory) {
        return userTokens[user];
    }

    function getUserTokenCount(address user) external view returns (uint256) {
        return userTokens[user].length;
    }

    function getAllTokens() external view returns (TokenInfo[] memory) {
        return allTokens;
    }

    function getTotalTokensCreated() external view returns (uint256) {
        return allTokens.length;
    }

    function getTokenByIndex(uint256 index) external view returns (TokenInfo memory) {
        require(index < allTokens.length, "ERC20Factory: Index out of bounds");
        return allTokens[index];
    }

    function getUserTokenByIndex(address user, uint256 index) external view returns (TokenInfo memory) {
        require(index < userTokens[user].length, "ERC20Factory: Index out of bounds");
        return userTokens[user][index];
    }

    function isTokenFromFactory(address tokenAddress) external view returns (bool) {
        return isTokenCreated[tokenAddress];
    }

    function getTokenCreator(address tokenAddress) external view returns (address) {
        require(isTokenCreated[tokenAddress], "ERC20Factory: Token not created by this factory");
        
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (allTokens[i].tokenAddress == tokenAddress) {
                return allTokens[i].creator;
            }
        }
        
        return address(0);
    }

    function getUserManagerAddress() external view returns (address) {
        return address(userManager);
    }

    function getNFTContractAddress() external view returns (address) {
        return address(nftContract);
    }

    function checkUserRequirements(address user) external view returns (
        bool isRegistered,
        uint256 nftBalance,
        bool canCreateToken
    ) {
        isRegistered = userManager.isRegisteredUser(user);
        nftBalance = nftContract.balanceOf(user);
        canCreateToken = isRegistered && nftBalance >= MIN_NFTS_REQUIRED;
    }

    function getMinNFTsRequired() external view returns (uint256) {
        return MIN_NFTS_REQUIRED;
    }
    
    function setTokenCreationFee(uint256 newFee) external onlyOwner {
        require(newFee != tokenCreationFee, "ERC20MembersFactory: Fee is already set to this value");
        
        uint256 oldFee = tokenCreationFee;
        tokenCreationFee = newFee;
        
        emit FeeUpdated(oldFee, newFee);
    }
    
    function setMinNFTsRequired(uint256 newMinNFTs) external onlyOwner {
        require(newMinNFTs != MIN_NFTS_REQUIRED, "ERC20MembersFactory: Min NFTs is already set to this value");
        require(newMinNFTs > 0, "ERC20MembersFactory: Min NFTs must be greater than 0");
        
        uint256 oldMinNFTs = MIN_NFTS_REQUIRED;
        MIN_NFTS_REQUIRED = newMinNFTs;
        
        emit MinNFTsRequiredUpdated(oldMinNFTs, newMinNFTs);
    }
    
    function getTokenCreationFee() external view returns (uint256) {
        return tokenCreationFee;
    }

    function getTokenInfoByAddress(address tokenAddress) external view returns (TokenInfo memory tokenInfo) {
        require(tokenAddress != address(0), "ERC20MembersFactory: Token address cannot be zero");
        require(isTokenCreated[tokenAddress], "ERC20MembersFactory: Token not created by this factory");
        
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (allTokens[i].tokenAddress == tokenAddress) {
                return allTokens[i];
            }
        }
        
        revert("ERC20MembersFactory: Token not found");
    }
    
}
