// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { ERC20MembersFactory } from "../contracts/ERC20MembersFactory.sol";
import { SimpleUserManager } from "../contracts/SimpleUserManager.sol";
import { SimpleNFT } from "../contracts/SimpleNFT.sol";
import { SimpleERC20 } from "../contracts/SimpleERC20.sol";

/**
 * @title ERC20MembersFactoryTest
 * @dev Pruebas completas para el contrato ERC20MembersFactory
 * @author cjbaezilla
 * @notice Este archivo contiene todas las pruebas unitarias para el factory de tokens ERC20 con requisitos de membresía
 */
contract ERC20MembersFactoryTest is Test {
    ERC20MembersFactory public factory;
    SimpleUserManager public userManager;
    SimpleNFT public nftContract;
    
    // Función para recibir ether
    receive() external payable {}
    
    address public deployer;
    address public user1;
    address public user2;
    address public user3;
    address public nonOwner;
    
    // Parámetros de prueba
    string constant NFT_NAME = "Test NFT";
    string constant NFT_SYMBOL = "TNFT";
    string constant NFT_BASE_URI = "https://api.example.com/metadata/";
    uint256 constant NFT_MINT_PRICE = 1 ether;
    uint256 constant TOKEN_CREATION_FEE = 0.001 ether;
    uint256 constant MIN_NFTS_REQUIRED = 5;
    
    // Eventos esperados
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

    function setUp() public {
        // Configurar cuentas de prueba
        deployer = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        nonOwner = makeAddr("nonOwner");
        
        // Dar ether a los usuarios para que puedan mintear y pagar tarifas
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(nonOwner, 100 ether);
        vm.deal(deployer, 100 ether);
        
        // Desplegar contratos dependientes
        userManager = new SimpleUserManager();
        nftContract = new SimpleNFT(NFT_NAME, NFT_SYMBOL, NFT_BASE_URI);
        
        // Desplegar factory
        factory = new ERC20MembersFactory(address(userManager), address(nftContract));
        
        // Configurar usuarios de prueba
        setupTestUsers();
    }
    
    /**
     * @dev Configura usuarios de prueba con diferentes cantidades de NFTs
     */
    function setupTestUsers() internal {
        // Registrar usuarios
        vm.startPrank(user1);
        userManager.registerUser(
            "user1",
            "user1@test.com",
            "https://twitter.com/user1",
            "https://github.com/user1",
            "https://t.me/user1",
            "https://avatar1.com",
            "https://cover1.com"
        );
        vm.stopPrank();
        
        vm.startPrank(user2);
        userManager.registerUser(
            "user2",
            "user2@test.com",
            "https://twitter.com/user2",
            "https://github.com/user2",
            "https://t.me/user2",
            "https://avatar2.com",
            "https://cover2.com"
        );
        vm.stopPrank();
        
        // user1: 5 NFTs (puede crear tokens)
        vm.startPrank(user1);
        nftContract.mintBatch{value: NFT_MINT_PRICE * 5}(5);
        vm.stopPrank();
        
        // user2: 3 NFTs (no puede crear tokens)
        vm.startPrank(user2);
        nftContract.mintBatch{value: NFT_MINT_PRICE * 3}(3);
        vm.stopPrank();
    }

    // ============ PRUEBAS DEL CONSTRUCTOR ============
    
    function test_Constructor_SetsUserManager() public view {
        assertEq(factory.getUserManagerAddress(), address(userManager));
    }
    
    function test_Constructor_SetsNFTContract() public view {
        assertEq(factory.getNFTContractAddress(), address(nftContract));
    }
    
    function test_Constructor_SetsOwner() public view {
        assertEq(factory.owner(), deployer);
    }
    
    function test_Constructor_InitialValues() public view {
        assertEq(factory.getTokenCreationFee(), TOKEN_CREATION_FEE);
        assertEq(factory.getMinNFTsRequired(), MIN_NFTS_REQUIRED);
        assertEq(factory.getTotalTokensCreated(), 0);
    }
    
    function test_Constructor_RevertsZeroUserManager() public {
        vm.expectRevert("ERC20MembersFactory: UserManager address cannot be zero");
        new ERC20MembersFactory(address(0), address(nftContract));
    }
    
    function test_Constructor_RevertsZeroNFTContract() public {
        vm.expectRevert("ERC20MembersFactory: NFT contract address cannot be zero");
        new ERC20MembersFactory(address(userManager), address(0));
    }

    // ============ PRUEBAS DE CREACIÓN DE TOKENS ============
    
    function test_CreateToken_Success() public {
        string memory tokenName = "Test Token";
        string memory tokenSymbol = "TTK";
        uint256 initialSupply = 1000000;
        
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}(
            tokenName,
            tokenSymbol,
            initialSupply
        );
        
        // Verificar que el token se creó correctamente
        assertTrue(tokenAddress != address(0));
        assertTrue(factory.isTokenFromFactory(tokenAddress));
        assertEq(factory.getTokenCreator(tokenAddress), user1);
        assertEq(factory.getTotalTokensCreated(), 1);
        
        // Verificar información del token
        ERC20MembersFactory.TokenInfo memory tokenInfo = factory.getTokenInfoByAddress(tokenAddress);
        assertEq(tokenInfo.name, tokenName);
        assertEq(tokenInfo.symbol, tokenSymbol);
        assertEq(tokenInfo.creator, user1);
        assertEq(tokenInfo.initialSupply, initialSupply);
        assertTrue(tokenInfo.createdAt > 0);
    }
    
    function test_CreateToken_IncrementsCounters() public {
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Token1", "TK1", 1000000);
        
        assertEq(factory.getTotalTokensCreated(), 1);
        assertEq(factory.getUserTokenCount(user1), 1);
        
        // user2 necesita más NFTs para crear token
        vm.startPrank(user2);
        nftContract.mintBatch{value: NFT_MINT_PRICE * 2}(2); // Ahora tiene 5 NFTs
        vm.stopPrank();
        
        vm.prank(user2);
        factory.createToken{value: TOKEN_CREATION_FEE}("Token2", "TK2", 2000000);
        
        assertEq(factory.getTotalTokensCreated(), 2);
        assertEq(factory.getUserTokenCount(user1), 1);
        assertEq(factory.getUserTokenCount(user2), 1);
    }
    
    function test_CreateToken_TransfersFeeToOwner() public {
        uint256 ownerBalanceBefore = deployer.balance;
        
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Fee Token", "FT", 1000000);
        
        assertEq(deployer.balance, ownerBalanceBefore + TOKEN_CREATION_FEE);
    }
    
    function test_CreateToken_AllowsExtraPayment() public {
        uint256 extraPayment = TOKEN_CREATION_FEE + 0.001 ether;
        
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: extraPayment}(
            "Extra Payment Token",
            "EPT",
            1000000
        );
        
        assertTrue(tokenAddress != address(0));
        assertTrue(factory.isTokenFromFactory(tokenAddress));
    }
    
    function test_CreateToken_RevertsUserNotRegistered() public {
        vm.prank(user3); // user3 no está registrado
        vm.expectRevert("ERC20MembersFactory: User must be registered");
        factory.createToken{value: TOKEN_CREATION_FEE}("Test", "TST", 1000000);
    }
    
    function test_CreateToken_RevertsInsufficientNFTs() public {
        vm.prank(user2); // user2 solo tiene 3 NFTs
        vm.expectRevert("ERC20MembersFactory: User must have at least 5 NFTs");
        factory.createToken{value: TOKEN_CREATION_FEE}("Test", "TST", 1000000);
    }
    
    function test_CreateToken_RevertsInsufficientFee() public {
        uint256 insufficientFee = TOKEN_CREATION_FEE / 2;
        
        vm.prank(user1);
        vm.expectRevert("ERC20MembersFactory: Insufficient fee paid");
        factory.createToken{value: insufficientFee}("Test", "TST", 1000000);
    }
    
    function test_CreateToken_RevertsEmptyName() public {
        vm.prank(user1);
        vm.expectRevert("ERC20MembersFactory: Name cannot be empty");
        factory.createToken{value: TOKEN_CREATION_FEE}("", "TST", 1000000);
    }
    
    function test_CreateToken_RevertsEmptySymbol() public {
        vm.prank(user1);
        vm.expectRevert("ERC20MembersFactory: Symbol cannot be empty");
        factory.createToken{value: TOKEN_CREATION_FEE}("Test Token", "", 1000000);
    }

    // ============ PRUEBAS DE FUNCIONES DE CONSULTA ============
    
    function test_GetUserTokens() public {
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("User1 Token", "U1T", 1000000);
        
        ERC20MembersFactory.TokenInfo[] memory userTokens = factory.getUserTokens(user1);
        assertEq(userTokens.length, 1);
        assertEq(userTokens[0].name, "User1 Token");
        assertEq(userTokens[0].symbol, "U1T");
        assertEq(userTokens[0].creator, user1);
    }
    
    function test_GetUserTokenCount() public view {
        assertEq(factory.getUserTokenCount(user1), 0);
        assertEq(factory.getUserTokenCount(user2), 0);
        assertEq(factory.getUserTokenCount(user3), 0);
    }
    
    function test_GetAllTokens() public {
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Token1", "TK1", 1000000);
        
        // user2 necesita más NFTs
        vm.startPrank(user2);
        nftContract.mintBatch{value: NFT_MINT_PRICE * 2}(2);
        vm.stopPrank();
        
        vm.prank(user2);
        factory.createToken{value: TOKEN_CREATION_FEE}("Token2", "TK2", 2000000);
        
        ERC20MembersFactory.TokenInfo[] memory allTokens = factory.getAllTokens();
        assertEq(allTokens.length, 2);
        assertEq(allTokens[0].name, "Token1");
        assertEq(allTokens[1].name, "Token2");
    }
    
    function test_GetTokenByIndex() public {
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Index Token", "IDX", 1000000);
        
        ERC20MembersFactory.TokenInfo memory token = factory.getTokenByIndex(0);
        assertEq(token.name, "Index Token");
        assertEq(token.symbol, "IDX");
        
        vm.expectRevert("ERC20Factory: Index out of bounds");
        factory.getTokenByIndex(1);
    }
    
    function test_GetUserTokenByIndex() public {
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("User Index Token", "UIDX", 1000000);
        
        ERC20MembersFactory.TokenInfo memory token = factory.getUserTokenByIndex(user1, 0);
        assertEq(token.name, "User Index Token");
        assertEq(token.symbol, "UIDX");
        
        vm.expectRevert("ERC20Factory: Index out of bounds");
        factory.getUserTokenByIndex(user1, 1);
    }
    
    function test_IsTokenFromFactory() public {
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}("Factory Token", "FCT", 1000000);
        
        assertTrue(factory.isTokenFromFactory(tokenAddress));
        assertFalse(factory.isTokenFromFactory(user1));
        assertFalse(factory.isTokenFromFactory(address(0)));
    }
    
    function test_GetTokenCreator() public {
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}("Creator Token", "CRT", 1000000);
        
        assertEq(factory.getTokenCreator(tokenAddress), user1);
        
        vm.expectRevert("ERC20Factory: Token not created by this factory");
        factory.getTokenCreator(user1);
    }
    
    function test_GetTokenInfoByAddress() public {
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}("Info Token", "INF", 1000000);
        
        ERC20MembersFactory.TokenInfo memory tokenInfo = factory.getTokenInfoByAddress(tokenAddress);
        assertEq(tokenInfo.name, "Info Token");
        assertEq(tokenInfo.symbol, "INF");
        assertEq(tokenInfo.creator, user1);
        assertEq(tokenInfo.initialSupply, 1000000);
        
        vm.expectRevert("ERC20MembersFactory: Token address cannot be zero");
        factory.getTokenInfoByAddress(address(0));
        
        vm.expectRevert("ERC20MembersFactory: Token not created by this factory");
        factory.getTokenInfoByAddress(user1);
    }
    
    function test_CheckUserRequirements() public view {
        (bool isRegistered, uint256 nftBalance, bool canCreateToken) = factory.checkUserRequirements(user1);
        assertTrue(isRegistered);
        assertEq(nftBalance, 5);
        assertTrue(canCreateToken);
        
        (isRegistered, nftBalance, canCreateToken) = factory.checkUserRequirements(user2);
        assertTrue(isRegistered);
        assertEq(nftBalance, 3);
        assertFalse(canCreateToken);
        
        (isRegistered, nftBalance, canCreateToken) = factory.checkUserRequirements(user3);
        assertFalse(isRegistered);
        assertEq(nftBalance, 0);
        assertFalse(canCreateToken);
    }

    // ============ PRUEBAS DE FUNCIONES ADMINISTRATIVAS ============
    
    function test_SetTokenCreationFee_Success() public {
        uint256 newFee = 0.002 ether;
        
        vm.expectEmit(true, true, false, false);
        emit FeeUpdated(TOKEN_CREATION_FEE, newFee);
        
        factory.setTokenCreationFee(newFee);
        
        assertEq(factory.getTokenCreationFee(), newFee);
    }
    
    function test_SetTokenCreationFee_RevertsSameValue() public {
        vm.expectRevert("ERC20MembersFactory: Fee is already set to this value");
        factory.setTokenCreationFee(TOKEN_CREATION_FEE);
    }
    
    function test_SetTokenCreationFee_RevertsNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert();
        factory.setTokenCreationFee(0.002 ether);
    }
    
    function test_SetMinNFTsRequired_Success() public {
        uint256 newMinNFTs = 10;
        
        vm.expectEmit(true, true, false, false);
        emit MinNFTsRequiredUpdated(MIN_NFTS_REQUIRED, newMinNFTs);
        
        factory.setMinNFTsRequired(newMinNFTs);
        
        assertEq(factory.getMinNFTsRequired(), newMinNFTs);
    }
    
    function test_SetMinNFTsRequired_RevertsSameValue() public {
        vm.expectRevert("ERC20MembersFactory: Min NFTs is already set to this value");
        factory.setMinNFTsRequired(MIN_NFTS_REQUIRED);
    }
    
    function test_SetMinNFTsRequired_RevertsZero() public {
        vm.expectRevert("ERC20MembersFactory: Min NFTs must be greater than 0");
        factory.setMinNFTsRequired(0);
    }
    
    function test_SetMinNFTsRequired_RevertsNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert();
        factory.setMinNFTsRequired(10);
    }

    // ============ PRUEBAS DE INTEGRACIÓN CON TOKENS CREADOS ============
    
    function test_TokenIntegration_ERC20Functionality() public {
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}("Integration Token", "INT", 1000000);
        
        // Verificar que el token es un ERC20 válido
        SimpleERC20 token = SimpleERC20(tokenAddress);
        assertEq(token.name(), "Integration Token");
        assertEq(token.symbol(), "INT");
        assertEq(token.totalSupply(), 1000000 * 10**18);
        assertEq(token.balanceOf(user1), 1000000 * 10**18);
    }
    
    function test_TokenIntegration_TransferFunctionality() public {
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}("Transfer Token", "TRF", 1000000);
        
        SimpleERC20 token = SimpleERC20(tokenAddress);
        
        // Transferir tokens
        vm.prank(user1);
        token.transfer(user2, 100000 * 10**18);
        
        assertEq(token.balanceOf(user1), 900000 * 10**18);
        assertEq(token.balanceOf(user2), 100000 * 10**18);
    }

    // ============ PRUEBAS DE CASOS LÍMITE ============
    
    function test_LongTokenName() public {
        string memory longName = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}(longName, "LNG", 1000000);
        
        assertTrue(tokenAddress != address(0));
        assertTrue(factory.isTokenFromFactory(tokenAddress));
    }
    
    function test_LongTokenSymbol() public {
        string memory longSymbol = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}("Test Token", longSymbol, 1000000);
        
        assertTrue(tokenAddress != address(0));
        assertTrue(factory.isTokenFromFactory(tokenAddress));
    }
    
    function test_LargeInitialSupply() public {
        uint256 largeSupply = 1000000000000000000000000; // 1000000 ETH worth of tokens
        
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}("Large Supply Token", "LST", largeSupply);
        
        assertTrue(tokenAddress != address(0));
        assertTrue(factory.isTokenFromFactory(tokenAddress));
        
        SimpleERC20 token = SimpleERC20(tokenAddress);
        assertEq(token.totalSupply(), largeSupply * 10**18);
    }
    
    function test_ZeroInitialSupply() public {
        vm.prank(user1);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}("Zero Supply Token", "ZST", 0);
        
        assertTrue(tokenAddress != address(0));
        assertTrue(factory.isTokenFromFactory(tokenAddress));
        
        SimpleERC20 token = SimpleERC20(tokenAddress);
        assertEq(token.totalSupply(), 0);
    }
    
    function test_MultipleTokensFromSameUser() public {
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Token 1", "TK1", 1000000);
        
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Token 2", "TK2", 2000000);
        
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Token 3", "TK3", 3000000);
        
        assertEq(factory.getTotalTokensCreated(), 3);
        assertEq(factory.getUserTokenCount(user1), 3);
        
        ERC20MembersFactory.TokenInfo[] memory userTokens = factory.getUserTokens(user1);
        assertEq(userTokens.length, 3);
        assertEq(userTokens[0].name, "Token 1");
        assertEq(userTokens[1].name, "Token 2");
        assertEq(userTokens[2].name, "Token 3");
    }

    // ============ PRUEBAS DE GAS ============
    
    function test_GasUsage_CreateToken() public {
        uint256 gasStart = gasleft();
        
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Gas Test Token", "GTT", 1000000);
        
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas usado para crear token:", gasUsed);
        assertTrue(gasUsed > 0);
    }
    
    function test_GasUsage_DeployFactory() public {
        uint256 gasStart = gasleft();
        
        new ERC20MembersFactory(address(userManager), address(nftContract));
        
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas usado para desplegar ERC20MembersFactory:", gasUsed);
        assertTrue(gasUsed > 0);
    }

    // ============ PRUEBAS DE ESCENARIOS COMPLEJOS ============
    
    function test_ComplexScenario_MultipleUsersAndConfigChanges() public {
        // Crear token con configuración inicial
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Initial Token", "IT", 1000000);
        
        // Cambiar configuración
        factory.setTokenCreationFee(0.002 ether);
        factory.setMinNFTsRequired(3);
        
        // user2 ahora puede crear token con la nueva configuración
        vm.prank(user2);
        factory.createToken{value: 0.002 ether}("New Config Token", "NCT", 1500000);
        
        // Verificar que ambos tokens fueron creados
        assertEq(factory.getTotalTokensCreated(), 2);
        assertEq(factory.getTokenCreationFee(), 0.002 ether);
        assertEq(factory.getMinNFTsRequired(), 3);
        
        // Verificar que user1 necesita más NFTs ahora
        (bool isRegistered, uint256 nftBalance, bool canCreateToken) = factory.checkUserRequirements(user1);
        assertTrue(isRegistered);
        assertEq(nftBalance, 5);
        assertTrue(canCreateToken); // Aún puede porque tiene 5 NFTs
        
        (isRegistered, nftBalance, canCreateToken) = factory.checkUserRequirements(user2);
        assertTrue(isRegistered);
        assertEq(nftBalance, 3);
        assertTrue(canCreateToken); // Ahora puede porque el mínimo bajó a 3
    }
    
    function test_ComplexScenario_UserLosesNFTs() public {
        // user1 crea token inicialmente
        vm.prank(user1);
        factory.createToken{value: TOKEN_CREATION_FEE}("Before Transfer Token", "BTT", 1000000);
        
        // user1 transfiere todos sus NFTs a user2
        vm.startPrank(user1);
        for (uint256 i = 1; i <= 5; i++) {
            nftContract.transferFrom(user1, user2, i);
        }
        vm.stopPrank();
        
        // user1 ya no puede crear tokens
        (bool isRegistered, uint256 nftBalance, bool canCreateToken) = factory.checkUserRequirements(user1);
        assertTrue(isRegistered);
        assertEq(nftBalance, 0);
        assertFalse(canCreateToken);
        
        // user2 ahora puede crear tokens
        (isRegistered, nftBalance, canCreateToken) = factory.checkUserRequirements(user2);
        assertTrue(isRegistered);
        assertEq(nftBalance, 8); // 3 originales + 5 transferidos
        assertTrue(canCreateToken);
        
        vm.prank(user2);
        factory.createToken{value: TOKEN_CREATION_FEE}("After Transfer Token", "ATT", 2000000);
        
        assertEq(factory.getTotalTokensCreated(), 2);
    }
    
    function test_ComplexScenario_EdgeCaseNFTRequirement() public {
        // Cambiar mínimo a 1 NFT
        factory.setMinNFTsRequired(1);
        
        // Crear usuario con exactamente 1 NFT
        address edgeUser = makeAddr("edgeUser");
        vm.deal(edgeUser, 100 ether);
        
        vm.startPrank(edgeUser);
        userManager.registerUser(
            "edgeUser",
            "edge@test.com",
            "https://twitter.com/edge",
            "https://github.com/edge",
            "https://t.me/edge",
            "https://avatar.com",
            "https://cover.com"
        );
        nftContract.mint{value: NFT_MINT_PRICE}();
        vm.stopPrank();
        
        // Debería poder crear token
        vm.prank(edgeUser);
        address tokenAddress = factory.createToken{value: TOKEN_CREATION_FEE}("Edge Token", "EDG", 1000000);
        
        assertTrue(tokenAddress != address(0));
        assertTrue(factory.isTokenFromFactory(tokenAddress));
        assertEq(factory.getTokenCreator(tokenAddress), edgeUser);
    }
}
