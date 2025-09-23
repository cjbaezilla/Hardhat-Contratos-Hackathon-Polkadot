// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/SimpleUserManager.sol";

/**
 * @title SimpleUserManagerTest
 * @dev Pruebas completas para el contrato SimpleUserManager
 * @author cjbaezilla
 * @notice Este archivo contiene todas las pruebas unitarias para el contrato SimpleUserManager
 */
contract SimpleUserManagerTest is Test {
    SimpleUserManager public userManager;
    
    address public user1;
    address public user2;
    address public user3;
    address public user4;
    address public nonRegisteredUser;
    
    // Datos de prueba para usuarios
    string constant USER1_USERNAME = "testuser1";
    string constant USER1_EMAIL = "test1@example.com";
    string constant USER1_TWITTER = "https://twitter.com/testuser1";
    string constant USER1_GITHUB = "https://github.com/testuser1";
    string constant USER1_TELEGRAM = "https://t.me/testuser1";
    string constant USER1_AVATAR = "https://example.com/avatar1.jpg";
    string constant USER1_COVER = "https://example.com/cover1.jpg";
    
    string constant USER2_USERNAME = "testuser2";
    string constant USER2_EMAIL = "test2@example.com";
    string constant USER2_TWITTER = "https://twitter.com/testuser2";
    string constant USER2_GITHUB = "https://github.com/testuser2";
    string constant USER2_TELEGRAM = "https://t.me/testuser2";
    string constant USER2_AVATAR = "https://example.com/avatar2.jpg";
    string constant USER2_COVER = "https://example.com/cover2.jpg";
    
    string constant USER3_USERNAME = "testuser3";
    string constant USER3_EMAIL = "test3@example.com";
    string constant USER3_TWITTER = "https://twitter.com/testuser3";
    string constant USER3_GITHUB = "https://github.com/testuser3";
    string constant USER3_TELEGRAM = "https://t.me/testuser3";
    string constant USER3_AVATAR = "https://example.com/avatar3.jpg";
    string constant USER3_COVER = "https://example.com/cover3.jpg";
    
    // Eventos esperados
    event UserRegistered(address indexed user);
    event UserRemoved(address indexed user);
    event UserInfoUpdated(address indexed user);

    function setUp() public {
        // Configurar cuentas de prueba
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");
        nonRegisteredUser = makeAddr("nonRegisteredUser");
        
        // Desplegar contrato SimpleUserManager
        userManager = new SimpleUserManager();
        
        // Resetear el estado del blockchain para las pruebas
        resetBlockchainState();
    }
    
    /**
     * @dev Función helper para resetear el estado del blockchain
     */
    function resetBlockchainState() internal {
        vm.roll(1000000);
        vm.warp(1000000000);
    }
    
    /**
     * @dev Función helper para registrar usuario en las pruebas
     */
    function registerTestUser(address user, string memory username, string memory email) internal {
        vm.prank(user);
        userManager.registerUser(
            username,
            email,
            "https://twitter.com/test",
            "https://github.com/test",
            "https://t.me/test",
            "https://example.com/avatar.jpg",
            "https://example.com/cover.jpg"
        );
    }

    // ============ PRUEBAS DEL CONSTRUCTOR ============
    
    function test_Constructor_DeploysSuccessfully() public view {
        assertTrue(address(userManager) != address(0));
    }
    
    function test_Constructor_InitialState() public view {
        assertEq(userManager.getTotalMembers(), 0);
        
        address[] memory allUsers = userManager.getAllUsers();
        assertEq(allUsers.length, 0);
        
        assertFalse(userManager.isRegisteredUser(user1));
        assertFalse(userManager.isRegisteredUser(user2));
        assertFalse(userManager.isRegisteredUser(user3));
        assertFalse(userManager.isRegisteredUser(user4));
    }

    // ============ PRUEBAS DE REGISTRO DE USUARIOS ============
    
    function test_RegisterUser_Success() public {
        vm.expectEmit(true, false, false, false);
        emit UserRegistered(user1);
        
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        assertTrue(userManager.isRegisteredUser(user1));
        assertEq(userManager.getTotalMembers(), 1);
        
        address[] memory allUsers = userManager.getAllUsers();
        assertEq(allUsers.length, 1);
        assertEq(allUsers[0], user1);
    }
    
    function test_RegisterUser_StoresCorrectInformation() public {
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        SimpleUserManager.UserInfo memory userInfo = userManager.getUserInfo(user1);
        assertEq(userInfo.username, USER1_USERNAME);
        assertEq(userInfo.userAddress, user1);
        assertEq(userInfo.email, USER1_EMAIL);
        assertEq(userInfo.twitterLink, USER1_TWITTER);
        assertEq(userInfo.githubLink, USER1_GITHUB);
        assertEq(userInfo.telegramLink, USER1_TELEGRAM);
        assertEq(userInfo.avatarLink, USER1_AVATAR);
        assertEq(userInfo.coverImageLink, USER1_COVER);
        assertTrue(userInfo.joinTimestamp > 0);
    }
    
    function test_RegisterUser_SetsCorrectTimestamp() public {
        uint256 beforeRegister = block.timestamp;
        
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        uint256 afterRegister = block.timestamp;
        SimpleUserManager.UserInfo memory userInfo = userManager.getUserInfo(user1);
        
        assertTrue(userInfo.joinTimestamp >= beforeRegister);
        assertTrue(userInfo.joinTimestamp <= afterRegister);
    }
    
    function test_RegisterUser_MultipleUsers() public {
        // Registrar user1
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        // Registrar user2
        vm.prank(user2);
        userManager.registerUser(
            USER2_USERNAME,
            USER2_EMAIL,
            USER2_TWITTER,
            USER2_GITHUB,
            USER2_TELEGRAM,
            USER2_AVATAR,
            USER2_COVER
        );
        
        assertTrue(userManager.isRegisteredUser(user1));
        assertTrue(userManager.isRegisteredUser(user2));
        assertEq(userManager.getTotalMembers(), 2);
        
        address[] memory allUsers = userManager.getAllUsers();
        assertEq(allUsers.length, 2);
        assertTrue(allUsers[0] == user1 || allUsers[1] == user1);
        assertTrue(allUsers[0] == user2 || allUsers[1] == user2);
    }
    
    function test_RegisterUser_RevertsAlreadyRegistered() public {
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(SimpleUserManager.UserAlreadyExists.selector, user1));
        userManager.registerUser(
            "anotherusername",
            "another@example.com",
            "https://twitter.com/another",
            "https://github.com/another",
            "https://t.me/another",
            "https://example.com/avatar2.jpg",
            "https://example.com/cover2.jpg"
        );
    }
    
    function test_RegisterUser_AllowsEmptyStrings() public {
        vm.prank(user1);
        userManager.registerUser(
            "", // username vacío
            "", // email vacío
            "", // twitter vacío
            "", // github vacío
            "", // telegram vacío
            "", // avatar vacío
            ""  // cover vacío
        );
        
        assertTrue(userManager.isRegisteredUser(user1));
        
        SimpleUserManager.UserInfo memory userInfo = userManager.getUserInfo(user1);
        assertEq(userInfo.username, "");
        assertEq(userInfo.email, "");
        assertEq(userInfo.twitterLink, "");
        assertEq(userInfo.githubLink, "");
        assertEq(userInfo.telegramLink, "");
        assertEq(userInfo.avatarLink, "");
        assertEq(userInfo.coverImageLink, "");
    }

    // ============ PRUEBAS DE ACTUALIZACIÓN DE INFORMACIÓN ============
    
    function test_UpdateUserInfo_Success() public {
        // Registrar usuario primero
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        string memory newEmail = "newemail@example.com";
        string memory newTwitter = "https://twitter.com/newuser";
        string memory newGithub = "https://github.com/newuser";
        string memory newTelegram = "https://t.me/newuser";
        string memory newAvatar = "https://example.com/newavatar.jpg";
        string memory newCover = "https://example.com/newcover.jpg";
        
        vm.expectEmit(true, false, false, false);
        emit UserInfoUpdated(user1);
        
        vm.prank(user1);
        userManager.updateUserInfo(
            newEmail,
            newTwitter,
            newGithub,
            newTelegram,
            newAvatar,
            newCover
        );
        
        SimpleUserManager.UserInfo memory userInfo = userManager.getUserInfo(user1);
        assertEq(userInfo.email, newEmail);
        assertEq(userInfo.twitterLink, newTwitter);
        assertEq(userInfo.githubLink, newGithub);
        assertEq(userInfo.telegramLink, newTelegram);
        assertEq(userInfo.avatarLink, newAvatar);
        assertEq(userInfo.coverImageLink, newCover);
    }
    
    function test_UpdateUserInfo_PreservesUsernameAndTimestamp() public {
        // Registrar usuario primero
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        SimpleUserManager.UserInfo memory originalInfo = userManager.getUserInfo(user1);
        string memory originalUsername = originalInfo.username;
        uint256 originalTimestamp = originalInfo.joinTimestamp;
        
        vm.prank(user1);
        userManager.updateUserInfo(
            "newemail@example.com",
            "https://twitter.com/newuser",
            "https://github.com/newuser",
            "https://t.me/newuser",
            "https://example.com/newavatar.jpg",
            "https://example.com/newcover.jpg"
        );
        
        SimpleUserManager.UserInfo memory updatedInfo = userManager.getUserInfo(user1);
        assertEq(updatedInfo.username, originalUsername);
        assertEq(updatedInfo.joinTimestamp, originalTimestamp);
    }
    
    function test_UpdateUserInfo_RevertsNotRegistered() public {
        vm.prank(nonRegisteredUser);
        vm.expectRevert(abi.encodeWithSelector(SimpleUserManager.UserNotRegistered.selector, nonRegisteredUser));
        userManager.updateUserInfo(
            "newemail@example.com",
            "https://twitter.com/newuser",
            "https://github.com/newuser",
            "https://t.me/newuser",
            "https://example.com/newavatar.jpg",
            "https://example.com/newcover.jpg"
        );
    }
    
    function test_UpdateUserInfo_PartialUpdate() public {
        // Registrar usuario primero
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        string memory newEmail = "newemail@example.com";
        string memory newAvatar = "https://example.com/newavatar.jpg";
        
        vm.prank(user1);
        userManager.updateUserInfo(
            newEmail,
            USER1_TWITTER, // mantener original
            USER1_GITHUB,  // mantener original
            USER1_TELEGRAM, // mantener original
            newAvatar,
            USER1_COVER // mantener original
        );
        
        SimpleUserManager.UserInfo memory userInfo = userManager.getUserInfo(user1);
        assertEq(userInfo.email, newEmail);
        assertEq(userInfo.avatarLink, newAvatar);
        assertEq(userInfo.twitterLink, USER1_TWITTER);
        assertEq(userInfo.githubLink, USER1_GITHUB);
    }

    // ============ PRUEBAS DE ELIMINACIÓN DE USUARIOS ============
    
    function test_RemoveUser_Success() public {
        // Registrar múltiples usuarios
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        registerTestUser(user2, USER2_USERNAME, USER2_EMAIL);
        registerTestUser(user3, USER3_USERNAME, USER3_EMAIL);
        
        assertEq(userManager.getTotalMembers(), 3);
        assertTrue(userManager.isRegisteredUser(user1));
        
        vm.expectEmit(true, false, false, false);
        emit UserRemoved(user1);
        
        vm.prank(user1);
        userManager.removeUser();
        
        assertFalse(userManager.isRegisteredUser(user1));
        assertEq(userManager.getTotalMembers(), 2);
        
        address[] memory allUsers = userManager.getAllUsers();
        assertEq(allUsers.length, 2);
        assertTrue(allUsers[0] == user2 || allUsers[1] == user2);
        assertTrue(allUsers[0] == user3 || allUsers[1] == user3);
    }
    
    function test_RemoveUser_RemovesFromArrayCorrectly() public {
        // Registrar múltiples usuarios
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        registerTestUser(user2, USER2_USERNAME, USER2_EMAIL);
        registerTestUser(user3, USER3_USERNAME, USER3_EMAIL);
        
        address[] memory allUsersBefore = userManager.getAllUsers();
        assertEq(allUsersBefore.length, 3);
        
        vm.prank(user2); // Eliminar user2 (del medio)
        userManager.removeUser();
        
        address[] memory allUsersAfter = userManager.getAllUsers();
        assertEq(allUsersAfter.length, 2);
        assertTrue(allUsersAfter[0] == user1 || allUsersAfter[1] == user1);
        assertTrue(allUsersAfter[0] == user3 || allUsersAfter[1] == user3);
    }
    
    function test_RemoveUser_RevertsNotRegistered() public {
        vm.prank(nonRegisteredUser);
        vm.expectRevert(abi.encodeWithSelector(SimpleUserManager.UserNotRegistered.selector, nonRegisteredUser));
        userManager.removeUser();
    }
    
    function test_RemoveUser_AllowsReRegistration() public {
        // Registrar user1
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        assertTrue(userManager.isRegisteredUser(user1));
        
        // Eliminar user1
        vm.prank(user1);
        userManager.removeUser();
        assertFalse(userManager.isRegisteredUser(user1));
        
        // Registrar user1 nuevamente
        vm.prank(user1);
        userManager.registerUser(
            "newusername",
            "newemail@example.com",
            "https://twitter.com/newuser",
            "https://github.com/newuser",
            "https://t.me/newuser",
            "https://example.com/newavatar.jpg",
            "https://example.com/newcover.jpg"
        );
        
        assertTrue(userManager.isRegisteredUser(user1));
        assertEq(userManager.getTotalMembers(), 1);
    }

    // ============ PRUEBAS DE FUNCIONES DE CONSULTA ============
    
    function test_IsRegisteredUser_ReturnsCorrectStatus() public {
        assertFalse(userManager.isRegisteredUser(user1));
        assertFalse(userManager.isRegisteredUser(user2));
        
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        registerTestUser(user2, USER2_USERNAME, USER2_EMAIL);
        
        assertTrue(userManager.isRegisteredUser(user1));
        assertTrue(userManager.isRegisteredUser(user2));
        assertFalse(userManager.isRegisteredUser(user3));
    }
    
    function test_GetUserInfo_ReturnsCompleteInformation() public {
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        SimpleUserManager.UserInfo memory userInfo = userManager.getUserInfo(user1);
        
        assertEq(userInfo.username, USER1_USERNAME);
        assertEq(userInfo.userAddress, user1);
        assertEq(userInfo.email, USER1_EMAIL);
        assertEq(userInfo.twitterLink, USER1_TWITTER);
        assertEq(userInfo.githubLink, USER1_GITHUB);
        assertEq(userInfo.telegramLink, USER1_TELEGRAM);
        assertEq(userInfo.avatarLink, USER1_AVATAR);
        assertEq(userInfo.coverImageLink, USER1_COVER);
        assertTrue(userInfo.joinTimestamp > 0);
    }
    
    function test_GetAllUsers_ReturnsAllRegisteredUsers() public {
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        registerTestUser(user2, USER2_USERNAME, USER2_EMAIL);
        
        address[] memory allUsers = userManager.getAllUsers();
        
        assertEq(allUsers.length, 2);
        assertTrue(allUsers[0] == user1 || allUsers[1] == user1);
        assertTrue(allUsers[0] == user2 || allUsers[1] == user2);
    }
    
    function test_GetTotalMembers_ReturnsCorrectCount() public {
        assertEq(userManager.getTotalMembers(), 0);
        
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        assertEq(userManager.getTotalMembers(), 1);
        
        registerTestUser(user2, USER2_USERNAME, USER2_EMAIL);
        assertEq(userManager.getTotalMembers(), 2);
        
        registerTestUser(user3, USER3_USERNAME, USER3_EMAIL);
        assertEq(userManager.getTotalMembers(), 3);
    }
    
    function test_GetUserInfo_RevertsNotRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(SimpleUserManager.UserNotRegistered.selector, user1));
        userManager.getUserInfo(user1);
    }

    // ============ PRUEBAS DE CASOS LÍMITE Y VALIDACIONES ============
    
    function test_LongStrings() public {
        string memory longString = new string(1000);
        for (uint256 i = 0; i < 1000; i++) {
            // Simular string largo
        }
        
        vm.prank(user1);
        userManager.registerUser(
            longString,
            longString,
            longString,
            longString,
            longString,
            longString,
            longString
        );
        
        assertTrue(userManager.isRegisteredUser(user1));
        
        SimpleUserManager.UserInfo memory userInfo = userManager.getUserInfo(user1);
        assertEq(userInfo.username, longString);
        assertEq(userInfo.email, longString);
    }
    
    function test_SpecialCharacters() public {
        string memory specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?`~";
        
        vm.prank(user1);
        userManager.registerUser(
            specialChars,
            specialChars,
            specialChars,
            specialChars,
            specialChars,
            specialChars,
            specialChars
        );
        
        assertTrue(userManager.isRegisteredUser(user1));
        
        SimpleUserManager.UserInfo memory userInfo = userManager.getUserInfo(user1);
        assertEq(userInfo.username, specialChars);
    }
    
    function test_ConsistencyAfterMultipleOperations() public {
        // Registrar usuarios
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        registerTestUser(user2, USER2_USERNAME, USER2_EMAIL);
        
        // Actualizar información
        vm.prank(user1);
        userManager.updateUserInfo(
            "updated@example.com",
            "https://twitter.com/updated",
            "https://github.com/updated",
            "https://t.me/updated",
            "https://example.com/updatedavatar.jpg",
            "https://example.com/updatedcover.jpg"
        );
        
        // Eliminar un usuario
        vm.prank(user2);
        userManager.removeUser();
        
        // Verificar consistencia
        assertEq(userManager.getTotalMembers(), 1);
        assertTrue(userManager.isRegisteredUser(user1));
        assertFalse(userManager.isRegisteredUser(user2));
        
        address[] memory allUsers = userManager.getAllUsers();
        assertEq(allUsers.length, 1);
        assertEq(allUsers[0], user1);
        
        SimpleUserManager.UserInfo memory userInfo = userManager.getUserInfo(user1);
        assertEq(userInfo.email, "updated@example.com");
    }

    // ============ PRUEBAS DE GAS ============
    
    function test_GasUsage_RegisterUser() public {
        uint256 gasStart = gasleft();
        
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
        
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas usado para registrar usuario:", gasUsed);
        assertTrue(gasUsed > 0);
    }
    
    function test_GasUsage_UpdateUser() public {
        // Registrar usuario primero
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        
        uint256 gasStart = gasleft();
        
        vm.prank(user1);
        userManager.updateUserInfo(
            "newemail@example.com",
            "https://twitter.com/newuser",
            "https://github.com/newuser",
            "https://t.me/newuser",
            "https://example.com/newavatar.jpg",
            "https://example.com/newcover.jpg"
        );
        
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas usado para actualizar usuario:", gasUsed);
        assertTrue(gasUsed > 0);
    }
    
    function test_GasUsage_RemoveUser() public {
        // Registrar usuario primero
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        
        uint256 gasStart = gasleft();
        
        vm.prank(user1);
        userManager.removeUser();
        
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas usado para eliminar usuario:", gasUsed);
        assertTrue(gasUsed > 0);
    }

    // ============ PRUEBAS DE EVENTOS ============
    
    function test_Events_UserRegistered() public {
        vm.expectEmit(true, false, false, false);
        emit UserRegistered(user1);
        
        vm.prank(user1);
        userManager.registerUser(
            USER1_USERNAME,
            USER1_EMAIL,
            USER1_TWITTER,
            USER1_GITHUB,
            USER1_TELEGRAM,
            USER1_AVATAR,
            USER1_COVER
        );
    }
    
    function test_Events_UserInfoUpdated() public {
        // Registrar usuario primero
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        
        vm.expectEmit(true, false, false, false);
        emit UserInfoUpdated(user1);
        
        vm.prank(user1);
        userManager.updateUserInfo(
            "newemail@example.com",
            "https://twitter.com/newuser",
            "https://github.com/newuser",
            "https://t.me/newuser",
            "https://example.com/newavatar.jpg",
            "https://example.com/newcover.jpg"
        );
    }
    
    function test_Events_UserRemoved() public {
        // Registrar usuario primero
        registerTestUser(user1, USER1_USERNAME, USER1_EMAIL);
        
        vm.expectEmit(true, false, false, false);
        emit UserRemoved(user1);
        
        vm.prank(user1);
        userManager.removeUser();
    }
}
