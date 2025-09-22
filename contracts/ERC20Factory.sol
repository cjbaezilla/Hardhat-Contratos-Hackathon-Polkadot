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

contract ERC20Factory {
    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        uint256 initialSupply
    );

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
    
    uint256 public totalTokensCreated;

    function createToken(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) external returns (address tokenAddress) {
        require(bytes(name_).length > 0, "ERC20Factory: Name cannot be empty");
        require(bytes(symbol_).length > 0, "ERC20Factory: Symbol cannot be empty");
        
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
        totalTokensCreated++;
        
        emit TokenCreated(tokenAddress, msg.sender, name_, symbol_, initialSupply_);
        
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
}
