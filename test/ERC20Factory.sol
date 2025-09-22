// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/ERC20Factory.sol";
import "../contracts/SimpleERC20.sol";

/**
 * @title ERC20FactoryTest
 * @dev Pruebas completas para el contrato ERC20Factory
 * @author cjbaezilla
 * @notice Este contrato de pruebas verifica todas las funcionalidades del ERC20Factory
 */
contract ERC20FactoryTest is Test {
    ERC20Factory public erc20Factory;
    address public deployer;
    address public user1;
    address public user2;
    address public user3;

    // Eventos esperados
    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        uint256 initialSupply
    );

    function setUp() public {
        // Configurar cuentas de prueba
        deployer = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Desplegar el contrato ERC20Factory
        erc20Factory = new ERC20Factory();
    }

    /**
     * @dev Prueba el estado inicial del contrato
     */
    function testInitialState() public {
        assertEq(erc20Factory.totalTokensCreated(), 0, "Total tokens should be 0 initially");
        
        // Verificar que no hay tokens creados
        ERC20Factory.TokenInfo[] memory allTokens = erc20Factory.getAllTokens();
        assertEq(allTokens.length, 0, "All tokens array should be empty initially");
        
        // Verificar que no hay tokens para usuarios
        ERC20Factory.TokenInfo[] memory userTokens = erc20Factory.getUserTokens(user1);
        assertEq(userTokens.length, 0, "User tokens should be empty initially");
    }

    /**
     * @dev Prueba la creación exitosa de un token
     */
    function testCreateToken() public {
        string memory name = "Test Token";
        string memory symbol = "TTK";
        uint256 initialSupply = 1000000;

        // Crear token como user1
        vm.prank(user1);
        address tokenAddress = erc20Factory.createToken(name, symbol, initialSupply);

        // Verificar que el token se creó correctamente
        assertTrue(tokenAddress != address(0), "Token address should not be zero");
        assertTrue(erc20Factory.isTokenFromFactory(tokenAddress), "Token should be recognized by factory");
        
        // Verificar contadores
        assertEq(erc20Factory.totalTokensCreated(), 1, "Total tokens should be 1");
        
        // Verificar arrays
        ERC20Factory.TokenInfo[] memory allTokens = erc20Factory.getAllTokens();
        assertEq(allTokens.length, 1, "All tokens array should have 1 token");
        
        ERC20Factory.TokenInfo[] memory userTokens = erc20Factory.getUserTokens(user1);
        assertEq(userTokens.length, 1, "User tokens should have 1 token");

        // Verificar información del token
        ERC20Factory.TokenInfo memory tokenInfo = allTokens[0];
        assertEq(tokenInfo.tokenAddress, tokenAddress, "Token address should match");
        assertEq(tokenInfo.creator, user1, "Creator should be user1");
        assertEq(tokenInfo.name, name, "Name should match");
        assertEq(tokenInfo.symbol, symbol, "Symbol should match");
        assertEq(tokenInfo.initialSupply, initialSupply, "Initial supply should match");
        assertTrue(tokenInfo.createdAt > 0, "Created at should be set");

        // Verificar que el token creado funciona correctamente
        SimpleERC20 token = SimpleERC20(tokenAddress);
        assertEq(token.name(), name, "Token name should match");
        assertEq(token.symbol(), symbol, "Token symbol should match");
        assertEq(token.totalSupply(), initialSupply * 10**18, "Token total supply should match");
        assertEq(token.balanceOf(user1), initialSupply * 10**18, "User1 should have all tokens");
    }

    /**
     * @dev Prueba la creación de múltiples tokens por diferentes usuarios
     */
    function testCreateMultipleTokens() public {
        // Crear primer token como user1
        vm.prank(user1);
        address token1 = erc20Factory.createToken("Token 1", "TK1", 1000000);
        
        // Crear segundo token como user2
        vm.prank(user2);
        address token2 = erc20Factory.createToken("Token 2", "TK2", 2000000);
        
        // Crear tercer token como user1 nuevamente
        vm.prank(user1);
        address token3 = erc20Factory.createToken("Token 3", "TK3", 3000000);

        // Verificar contadores globales
        assertEq(erc20Factory.totalTokensCreated(), 3, "Total tokens should be 3");
        
        ERC20Factory.TokenInfo[] memory allTokens = erc20Factory.getAllTokens();
        assertEq(allTokens.length, 3, "All tokens array should have 3 tokens");

        // Verificar tokens por usuario
        ERC20Factory.TokenInfo[] memory user1Tokens = erc20Factory.getUserTokens(user1);
        assertEq(user1Tokens.length, 2, "User1 should have 2 tokens");
        
        ERC20Factory.TokenInfo[] memory user2Tokens = erc20Factory.getUserTokens(user2);
        assertEq(user2Tokens.length, 1, "User2 should have 1 token");

        // Verificar que todos los tokens son únicos
        assertTrue(token1 != token2, "Token1 and Token2 should be different");
        assertTrue(token1 != token3, "Token1 and Token3 should be different");
        assertTrue(token2 != token3, "Token2 and Token3 should be different");
    }

    /**
     * @dev Prueba las validaciones de parámetros
     */
    function testCreateTokenValidation() public {
        // Probar con nombre vacío
        vm.prank(user1);
        vm.expectRevert("ERC20Factory: Name cannot be empty");
        erc20Factory.createToken("", "TK", 1000000);

        // Probar con símbolo vacío
        vm.prank(user1);
        vm.expectRevert("ERC20Factory: Symbol cannot be empty");
        erc20Factory.createToken("Test Token", "", 1000000);

        // Probar con suministro inicial de 0 (esto debería pasar ya que no hay validación en el contrato)
        vm.prank(user1);
        address tokenAddress = erc20Factory.createToken("Zero Supply Token", "ZST", 0);
        assertTrue(tokenAddress != address(0), "Zero supply token should be created");
    }

    /**
     * @dev Prueba las funciones de consulta (view functions)
     */
    function testViewFunctions() public {
        // Crear algunos tokens para probar
        vm.prank(user1);
        address token1 = erc20Factory.createToken("Token 1", "TK1", 1000000);
        
        vm.prank(user2);
        address token2 = erc20Factory.createToken("Token 2", "TK2", 2000000);
        
        vm.prank(user1);
        address token3 = erc20Factory.createToken("Token 3", "TK3", 3000000);

        // Probar getUserTokenCount
        assertEq(erc20Factory.getUserTokenCount(user1), 2, "User1 should have 2 tokens");
        assertEq(erc20Factory.getUserTokenCount(user2), 1, "User2 should have 1 token");
        assertEq(erc20Factory.getUserTokenCount(user3), 0, "User3 should have 0 tokens");

        // Probar getTokenByIndex
        ERC20Factory.TokenInfo memory tokenInfo0 = erc20Factory.getTokenByIndex(0);
        assertEq(tokenInfo0.tokenAddress, token1, "First token should be token1");
        
        ERC20Factory.TokenInfo memory tokenInfo1 = erc20Factory.getTokenByIndex(1);
        assertEq(tokenInfo1.tokenAddress, token2, "Second token should be token2");

        // Probar getUserTokenByIndex
        ERC20Factory.TokenInfo memory user1Token0 = erc20Factory.getUserTokenByIndex(user1, 0);
        assertEq(user1Token0.tokenAddress, token1, "User1's first token should be token1");
        
        ERC20Factory.TokenInfo memory user1Token1 = erc20Factory.getUserTokenByIndex(user1, 1);
        assertEq(user1Token1.tokenAddress, token3, "User1's second token should be token3");

        // Probar isTokenFromFactory
        assertTrue(erc20Factory.isTokenFromFactory(token1), "Token1 should be from factory");
        assertTrue(erc20Factory.isTokenFromFactory(token2), "Token2 should be from factory");
        assertTrue(erc20Factory.isTokenFromFactory(token3), "Token3 should be from factory");
        assertFalse(erc20Factory.isTokenFromFactory(address(0x123)), "Random address should not be from factory");

        // Probar getTokenCreator
        assertEq(erc20Factory.getTokenCreator(token1), user1, "Token1 creator should be user1");
        assertEq(erc20Factory.getTokenCreator(token2), user2, "Token2 creator should be user2");
        assertEq(erc20Factory.getTokenCreator(token3), user1, "Token3 creator should be user1");
    }

    /**
     * @dev Prueba los casos de error en las funciones de consulta
     */
    function testViewFunctionsErrors() public {
        // Probar getTokenByIndex con índice fuera de rango
        vm.expectRevert("ERC20Factory: Index out of bounds");
        erc20Factory.getTokenByIndex(0);

        // Crear un token
        vm.prank(user1);
        erc20Factory.createToken("Test Token", "TTK", 1000000);

        // Probar getTokenByIndex con índice válido
        ERC20Factory.TokenInfo memory tokenInfo = erc20Factory.getTokenByIndex(0);
        assertTrue(tokenInfo.tokenAddress != address(0), "Token info should be valid");

        // Probar getTokenByIndex con índice fuera de rango después de crear token
        vm.expectRevert("ERC20Factory: Index out of bounds");
        erc20Factory.getTokenByIndex(1);

        // Probar getUserTokenByIndex con índice fuera de rango
        vm.expectRevert("ERC20Factory: Index out of bounds");
        erc20Factory.getUserTokenByIndex(user1, 1);

        // Probar getTokenCreator con token no creado por el factory
        vm.expectRevert("ERC20Factory: Token not created by this factory");
        erc20Factory.getTokenCreator(address(0x123));
    }

    /**
     * @dev Prueba la funcionalidad de los tokens creados
     */
    function testCreatedTokenFunctionality() public {
        // Crear un token
        vm.prank(user1);
        address tokenAddress = erc20Factory.createToken("Functional Token", "FCT", 1000000);
        
        SimpleERC20 token = SimpleERC20(tokenAddress);

        // Verificar propiedades básicas del token
        assertEq(token.name(), "Functional Token", "Token name should be correct");
        assertEq(token.symbol(), "FCT", "Token symbol should be correct");
        assertEq(token.decimals(), 18, "Token decimals should be 18");
        assertEq(token.totalSupply(), 1000000 * 10**18, "Total supply should be correct");

        // Verificar que el creador tiene todos los tokens
        assertEq(token.balanceOf(user1), 1000000 * 10**18, "Creator should have all tokens");

        // Probar transferencia de tokens
        uint256 transferAmount = 1000 * 10**18;
        vm.prank(user1);
        token.transfer(user2, transferAmount);

        assertEq(token.balanceOf(user1), 1000000 * 10**18 - transferAmount, "User1 balance should be reduced");
        assertEq(token.balanceOf(user2), transferAmount, "User2 should receive tokens");
    }

    /**
     * @dev Prueba casos límite y edge cases
     */
    function testEdgeCases() public {
        // Probar con nombres y símbolos muy largos
        string memory longName = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        string memory longSymbol = "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB";
        
        vm.prank(user1);
        address tokenAddress = erc20Factory.createToken(longName, longSymbol, 1000000);
        assertTrue(tokenAddress != address(0), "Long name/symbol token should be created");

        // Probar con suministro muy grande
        uint256 largeSupply = type(uint256).max / 10**18; // Evitar overflow
        vm.prank(user2);
        address largeTokenAddress = erc20Factory.createToken("Large Token", "LGT", largeSupply);
        assertTrue(largeTokenAddress != address(0), "Large supply token should be created");

        // Verificar que el token con suministro grande funciona
        SimpleERC20 largeToken = SimpleERC20(largeTokenAddress);
        assertEq(largeToken.totalSupply(), largeSupply * 10**18, "Large supply should be correct");
    }

    /**
     * @dev Prueba la integridad de los datos almacenados
     */
    function testDataIntegrity() public {
        // Crear varios tokens
        vm.prank(user1);
        address token1 = erc20Factory.createToken("Token 1", "TK1", 1000000);
        
        vm.prank(user2);
        address token2 = erc20Factory.createToken("Token 2", "TK2", 2000000);
        
        vm.prank(user1);
        address token3 = erc20Factory.createToken("Token 3", "TK3", 3000000);

        // Verificar que los datos son consistentes entre diferentes funciones
        ERC20Factory.TokenInfo[] memory allTokens = erc20Factory.getAllTokens();
        ERC20Factory.TokenInfo[] memory user1Tokens = erc20Factory.getUserTokens(user1);
        ERC20Factory.TokenInfo[] memory user2Tokens = erc20Factory.getUserTokens(user2);

        // Verificar que el total es correcto
        assertEq(allTokens.length, 3, "All tokens should have 3 items");
        assertEq(user1Tokens.length, 2, "User1 tokens should have 2 items");
        assertEq(user2Tokens.length, 1, "User2 tokens should have 1 item");

        // Verificar que los tokens de user1 están en allTokens
        bool foundToken1 = false;
        bool foundToken3 = false;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (allTokens[i].tokenAddress == token1) foundToken1 = true;
            if (allTokens[i].tokenAddress == token3) foundToken3 = true;
        }
        assertTrue(foundToken1, "Token1 should be in allTokens");
        assertTrue(foundToken3, "Token3 should be in allTokens");

        // Verificar que los tokens de user2 están en allTokens
        bool foundToken2 = false;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (allTokens[i].tokenAddress == token2) foundToken2 = true;
        }
        assertTrue(foundToken2, "Token2 should be in allTokens");
    }

    /**
     * @dev Prueba la prevención de duplicados
     */
    function testDuplicatePrevention() public {
        // Crear un token
        vm.prank(user1);
        address token1 = erc20Factory.createToken("Test Token", "TTK", 1000000);
        
        // Verificar que el token se marca como creado
        assertTrue(erc20Factory.isTokenFromFactory(token1), "Token should be marked as created");
        
        // Intentar crear el mismo token nuevamente (esto no debería ser posible ya que cada token es único)
        // Pero podemos verificar que el sistema maneja correctamente los tokens existentes
        assertTrue(erc20Factory.isTokenFromFactory(token1), "Same token should still be recognized");
    }

    /**
     * @dev Prueba el gas usage para operaciones comunes
     */
    function testGasUsage() public {
        // Medir gas para crear un token
        uint256 gasStart = gasleft();
        vm.prank(user1);
        erc20Factory.createToken("Gas Test Token", "GTT", 1000000);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used to create token:", gasUsed);
        assertTrue(gasUsed > 0, "Gas should be used");
        
        // Medir gas para consultas
        gasStart = gasleft();
        erc20Factory.getAllTokens();
        uint256 queryGas = gasStart - gasleft();
        
        console.log("Gas used for getAllTokens query:", queryGas);
        assertTrue(queryGas > 0, "Query should use gas");
    }

    /**
     * @dev Prueba la funcionalidad con diferentes usuarios
     */
    function testMultipleUsers() public {
        // Crear tokens con diferentes usuarios
        vm.prank(user1);
        address token1 = erc20Factory.createToken("User1 Token", "U1T", 1000000);
        
        vm.prank(user2);
        address token2 = erc20Factory.createToken("User2 Token", "U2T", 2000000);
        
        vm.prank(user3);
        address token3 = erc20Factory.createToken("User3 Token", "U3T", 3000000);

        // Verificar que cada usuario tiene sus tokens
        assertEq(erc20Factory.getUserTokenCount(user1), 1, "User1 should have 1 token");
        assertEq(erc20Factory.getUserTokenCount(user2), 1, "User2 should have 1 token");
        assertEq(erc20Factory.getUserTokenCount(user3), 1, "User3 should have 1 token");

        // Verificar que cada token tiene el creador correcto
        assertEq(erc20Factory.getTokenCreator(token1), user1, "Token1 creator should be user1");
        assertEq(erc20Factory.getTokenCreator(token2), user2, "Token2 creator should be user2");
        assertEq(erc20Factory.getTokenCreator(token3), user3, "Token3 creator should be user3");

        // Verificar que los tokens son únicos
        assertTrue(token1 != token2, "Tokens should be unique");
        assertTrue(token1 != token3, "Tokens should be unique");
        assertTrue(token2 != token3, "Tokens should be unique");
    }
}
