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

contract SimpleUserManager {

    struct UserInfo {
        uint256 joinTimestamp;
        string username;
        address userAddress;
        string email;
        string twitterLink;
        string githubLink;
        string telegramLink;
        string avatarLink;
        string coverImageLink;
    }

    mapping(address => UserInfo) private users;
    mapping(address => bool) private isRegistered;
    
    address[] private userAddresses;

    event UserRegistered(address indexed user);
    event UserRemoved(address indexed user);
    event UserInfoUpdated(address indexed user);

    error UserAlreadyExists(address user);
    error UserNotRegistered(address user);
    error UnauthorizedAccess();

    constructor() {}

    function registerUser(
        string memory _username,
        string memory _email,
        string memory _twitterLink,
        string memory _githubLink,
        string memory _telegramLink,
        string memory _avatarLink,
        string memory _coverImageLink
    ) external {
        address user = msg.sender;
        
        if (isRegistered[user]) {
            revert UserAlreadyExists(user);
        }

        users[user] = UserInfo({
            joinTimestamp: block.timestamp,
            username: _username,
            userAddress: user,
            email: _email,
            twitterLink: _twitterLink,
            githubLink: _githubLink,
            telegramLink: _telegramLink,
            avatarLink: _avatarLink,
            coverImageLink: _coverImageLink
        });
        
        isRegistered[user] = true;
        userAddresses.push(user);

        emit UserRegistered(user);
    }

    function updateUserInfo(
        string memory _email,
        string memory _twitterLink,
        string memory _githubLink,
        string memory _telegramLink,
        string memory _avatarLink,
        string memory _coverImageLink
    ) external {
        address user = msg.sender;
        
        if (!isRegistered[user]) {
            revert UserNotRegistered(user);
        }

        users[user].email = _email;
        users[user].twitterLink = _twitterLink;
        users[user].githubLink = _githubLink;
        users[user].telegramLink = _telegramLink;
        users[user].avatarLink = _avatarLink;
        users[user].coverImageLink = _coverImageLink;

        emit UserInfoUpdated(user);
    }

    function removeUser() external {
        address user = msg.sender;
        
        if (!isRegistered[user]) {
            revert UserNotRegistered(user);
        }

        delete users[user];
        isRegistered[user] = false;

        for (uint256 i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == user) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                break;
            }
        }

        emit UserRemoved(user);
    }


    function isRegisteredUser(address user) external view returns (bool) {
        return isRegistered[user];
    }

    function getUserInfo(address user) external view returns (UserInfo memory) {
        if (!isRegistered[user]) {
            revert UserNotRegistered(user);
        }
        return users[user];
    }

    function getAllUsers() external view returns (address[] memory) {
        return userAddresses;
    }

    function getTotalMembers() external view returns (uint256) {
        return userAddresses.length;
    }
}