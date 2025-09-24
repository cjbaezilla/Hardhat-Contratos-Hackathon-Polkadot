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
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {DAOMembersFactory} from "../contracts/DAOMembersFactory.sol";
import {DAO} from "../contracts/DAO.sol";
import {SimpleUserManager} from "../contracts/SimpleUserManager.sol";
import {SimpleNFT} from "../contracts/SimpleNFT.sol";

/**
 * @title ETHReceiver
 * @dev Contrato auxiliar para recibir ETH en las pruebas
 */
contract ETHReceiver {
    receive() external payable {}
}

/**
 * @title TestSimpleNFT
 * @dev Versión de prueba del SimpleNFT que no transfiere ETH
 */
contract TestSimpleNFT {
    uint256 private _nextTokenId = 1;
    uint256 public constant MINT_PRICE = 1 ether;
    
    string private _baseTokenURI;
    address private _deployer;
    address[] public nftHolders;
    mapping(address => bool) private _isHolder;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    
    event TokenMinted(address indexed to, uint256 indexed tokenId, uint256 price);
    
    constructor(
        string memory /* name */,
        string memory /* symbol */,
        string memory baseURI
    ) {
        _baseTokenURI = baseURI;
        _deployer = msg.sender;
    }
    
    function mint() public payable returns (uint256) {
        require(msg.value == MINT_PRICE, "Debe enviar exactamente 1 PES para mintear");
        
        uint256 tokenId = _nextTokenId;
        unchecked {
            ++_nextTokenId;
        }
        
        _owners[tokenId] = msg.sender;
        _balances[msg.sender]++;
        
        if (!_isHolder[msg.sender]) {
            nftHolders.push(msg.sender);
            _isHolder[msg.sender] = true;
        }
        
        // No transferir ETH en las pruebas
        // payable(_deployer).transfer(msg.value);
        
        emit TokenMinted(msg.sender, tokenId, MINT_PRICE);
        
        return tokenId;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }
}

/**
 * @title DAOMembersFactoryTest
 * @dev Pruebas completas para el contrato DAOMembersFactory
 * @notice Cubre todas las funcionalidades del factory incluyendo despliegue, consultas, ownership y validaciones de miembros
 */
contract DAOMembersFactoryTest is Test {
    
    DAOMembersFactory public daoMembersFactory;
    SimpleUserManager public userManager;
    TestSimpleNFT public nftContract;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    // Permitir que el contrato de prueba reciba ETH
    receive() external payable {}
    
    // Parámetros para crear DAOs
    uint256 public constant MIN_PROPOSAL_CREATION_TOKENS = 10;
    uint256 public constant MIN_VOTES_TO_APPROVE = 5;
    uint256 public constant MIN_TOKENS_TO_APPROVE = 50;
    uint256 public constant DAO_CREATION_FEE = 0.001 ether;
    uint256 public constant MIN_NFTS_REQUIRED = 5;
    
    // Eventos esperados
    event DAOCreated(
        address indexed daoAddress,
        address indexed creator,
        address indexed nftContract,
        uint256 minProposalCreationTokens,
        uint256 minVotesToApprove,
        uint256 minTokensToApprove
    );
    
    event DAOFactoryOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event MinNFTsRequiredUpdated(uint256 oldMinNFTs, uint256 newMinNFTs);
    
    function setUp() public {
        // Configurar cuentas de prueba
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // Desplegar SimpleUserManager
        userManager = new SimpleUserManager();
        
        // Desplegar TestSimpleNFT
        nftContract = new TestSimpleNFT("Test NFT", "TNFT", "https://api.example.com/metadata/");
        
        // Desplegar DAOMembersFactory
        daoMembersFactory = new DAOMembersFactory(
            address(userManager),
            address(nftContract),
            owner
        );
        
        // Registrar usuarios para las pruebas
        vm.prank(user1);
        userManager.registerUser(
            "user1",
            "user1@test.com",
            "https://twitter.com/user1",
            "https://github.com/user1",
            "https://t.me/user1",
            "https://avatar1.com",
            "https://cover1.com"
        );
        
        vm.prank(user2);
        userManager.registerUser(
            "user2",
            "user2@test.com",
            "https://twitter.com/user2",
            "https://github.com/user2",
            "https://t.me/user2",
            "https://avatar2.com",
            "https://cover2.com"
        );
        
        // Mintear NFTs para user1 (más de 5 para cumplir requisitos)
        vm.deal(user1, 10 ether);
        for (uint256 i = 0; i < 6; i++) {
            vm.prank(user1);
            nftContract.mint{value: 1 ether}();
        }
        
        // Mintear algunos NFTs para user2 (menos de 5 para pruebas de error)
        vm.deal(user2, 10 ether);
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(user2);
            nftContract.mint{value: 1 ether}();
        }
        
        // Dar ETH al owner para recibir las tarifas
        vm.deal(owner, 100 ether);
    }
    
    /**
     * @dev Prueba el estado inicial del contrato
     */
    function testInitialState() public view {
        assertEq(daoMembersFactory.owner(), owner, "Owner should be set correctly");
        assertEq(daoMembersFactory.getUserManagerAddress(), address(userManager), "UserManager address should be set correctly");
        assertEq(daoMembersFactory.getNFTContractAddress(), address(nftContract), "NFT contract address should be set correctly");
        assertEq(daoMembersFactory.getTotalDAOs(), 0, "Total DAOs should be 0 initially");
        assertEq(daoMembersFactory.getMinNFTsRequired(), MIN_NFTS_REQUIRED, "Min NFTs required should be set correctly");
        assertEq(daoMembersFactory.getDAOCreationFee(), DAO_CREATION_FEE, "DAO creation fee should be set correctly");
    }
    
    /**
     * @dev Prueba el constructor con direcciones inválidas
     */
    function testConstructorWithInvalidAddresses() public {
        // Prueba con userManager address(0)
        vm.expectRevert("DAOMembersFactory: UserManager address cannot be zero");
        new DAOMembersFactory(address(0), address(nftContract), owner);
        
        // Prueba con nftContract address(0)
        vm.expectRevert("DAOMembersFactory: NFT contract address cannot be zero");
        new DAOMembersFactory(address(userManager), address(0), owner);
    }
    
    /**
     * @dev Prueba el despliegue exitoso de un DAO
     */
    function testDeployDAOSuccess() public {
        address nftAddress = address(nftContract);
        
        vm.prank(user1);
        address daoAddress = daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        // Verificaciones post-despliegue
        assertTrue(daoAddress != address(0), "DAO address should not be zero");
        assertEq(daoMembersFactory.getTotalDAOs(), 1, "Total DAOs should be 1");
        assertEq(daoMembersFactory.getDAOByIndex(0), daoAddress, "DAO address should match");
        assertEq(daoMembersFactory.getDAOCreator(daoAddress), user1, "DAO creator should be user1");
        assertTrue(daoMembersFactory.isDAO(daoAddress), "DAO should be valid");
        
        // Verificar que el DAO tiene la propiedad correcta
        DAO dao = DAO(daoAddress);
        assertEq(dao.owner(), user1, "DAO owner should be user1");
    }
    
    /**
     * @dev Prueba el fallo al desplegar DAO con usuario no registrado
     */
    function testDeployDAOWithUnregisteredUser() public {
        address nftAddress = address(nftContract);
        
        // Dar ETH a user3 para la prueba
        vm.deal(user3, 10 ether);
        
        vm.prank(user3);
        vm.expectRevert("DAOMembersFactory: User must be registered");
        daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
    }
    
    /**
     * @dev Prueba el fallo al desplegar DAO con NFTs insuficientes
     */
    function testDeployDAOWithInsufficientNFTs() public {
        address nftAddress = address(nftContract);
        
        vm.expectRevert("DAOMembersFactory: User must have at least 5 NFTs");
        vm.prank(user2);
        daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
    }
    
    /**
     * @dev Prueba el fallo al desplegar DAO con tarifa insuficiente
     */
    function testDeployDAOWithInsufficientFee() public {
        address nftAddress = address(nftContract);
        
        vm.expectRevert("DAOMembersFactory: Insufficient fee paid");
        vm.prank(user1);
        daoMembersFactory.deployDAO{value: 0.0005 ether}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
    }
    
    /**
     * @dev Prueba el fallo al desplegar DAO con parámetros inválidos
     */
    function testDeployDAOWithInvalidParameters() public {
        address nftAddress = address(nftContract);
        
        // Prueba con nftContract address(0)
        vm.expectRevert("DAOMembersFactory: Direccion del contrato NFT invalida");
        vm.prank(user1);
        daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            address(0),
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        // Prueba con minProposalCreationTokens = 0
        vm.expectRevert("DAOMembersFactory: Minimo de tokens para propuestas debe ser mayor a 0");
        vm.prank(user1);
        daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            0,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        // Prueba con minVotesToApprove = 0
        vm.expectRevert("DAOMembersFactory: Minimo de votos para aprobar debe ser mayor a 0");
        vm.prank(user1);
        daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            0,
            MIN_TOKENS_TO_APPROVE
        );
        
        // Prueba con minTokensToApprove = 0
        vm.expectRevert("DAOMembersFactory: Minimo de tokens para aprobar debe ser mayor a 0");
        vm.prank(user1);
        daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            0
        );
    }
    
    /**
     * @dev Prueba la transferencia de tarifa al propietario
     */
    function testFeeTransferToOwner() public {
        address nftAddress = address(nftContract);
        uint256 ownerBalanceBefore = owner.balance;
        
        vm.prank(user1);
        daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        uint256 ownerBalanceAfter = owner.balance;
        assertEq(ownerBalanceAfter - ownerBalanceBefore, DAO_CREATION_FEE, "Owner should receive the fee");
    }
    
    /**
     * @dev Prueba las funciones de consulta
     */
    function testQueryFunctions() public {
        address nftAddress = address(nftContract);
        
        // Crear un DAO primero
        vm.prank(user1);
        address daoAddress = daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        // Prueba getTotalDAOs
        assertEq(daoMembersFactory.getTotalDAOs(), 1, "Total DAOs should be 1");
        
        // Prueba getDAOByIndex
        assertEq(daoMembersFactory.getDAOByIndex(0), daoAddress, "DAO address should match");
        
        // Prueba getAllDAOs
        address[] memory allDAOs = daoMembersFactory.getAllDAOs();
        assertEq(allDAOs.length, 1, "All DAOs array should have 1 element");
        assertEq(allDAOs[0], daoAddress, "First DAO should match");
        
        // Prueba getDAOCreator
        assertEq(daoMembersFactory.getDAOCreator(daoAddress), user1, "DAO creator should be user1");
        
        // Prueba isDAO
        assertTrue(daoMembersFactory.isDAO(daoAddress), "DAO should be valid");
        assertFalse(daoMembersFactory.isDAO(user2), "Non-DAO address should be invalid");
        
        // Prueba getFactoryStats
        (uint256 totalDAOs, address factoryOwner) = daoMembersFactory.getFactoryStats();
        assertEq(totalDAOs, 1, "Total DAOs in stats should be 1");
        assertEq(factoryOwner, owner, "Factory owner should match");
        
        // Prueba checkUserRequirements
        (bool isRegistered, uint256 nftBalance, bool canCreateDAO) = daoMembersFactory.checkUserRequirements(user1);
        assertTrue(isRegistered, "User1 should be registered");
        assertEq(nftBalance, 6, "User1 should have 6 NFTs");
        assertTrue(canCreateDAO, "User1 should be able to create DAO");
        
        (bool isRegistered2, uint256 nftBalance2, bool canCreateDAO2) = daoMembersFactory.checkUserRequirements(user2);
        assertTrue(isRegistered2, "User2 should be registered");
        assertEq(nftBalance2, 3, "User2 should have 3 NFTs");
        assertFalse(canCreateDAO2, "User2 should not be able to create DAO");
        
        (bool isRegistered3, uint256 nftBalance3, bool canCreateDAO3) = daoMembersFactory.checkUserRequirements(user3);
        assertFalse(isRegistered3, "User3 should not be registered");
        assertEq(nftBalance3, 0, "User3 should have 0 NFTs");
        assertFalse(canCreateDAO3, "User3 should not be able to create DAO");
    }
    
    /**
     * @dev Prueba el fallo al obtener DAO con índice fuera de rango
     */
    function testGetDAOByIndexOutOfRange() public {
        vm.expectRevert("Indice fuera de rango");
        daoMembersFactory.getDAOByIndex(0);
    }
    
    /**
     * @dev Prueba el fallo al obtener creador de DAO inválido
     */
    function testGetDAOCreatorInvalidDAO() public {
        vm.expectRevert("DAO no valido o no creado por esta factory");
        daoMembersFactory.getDAOCreator(user2);
    }
    
    /**
     * @dev Prueba la transferencia de propiedad del factory
     */
    function testTransferFactoryOwnership() public {
        vm.expectEmit(true, true, false, false);
        emit DAOFactoryOwnershipTransferred(owner, user1);
        
        daoMembersFactory.transferFactoryOwnership(user1);
        assertEq(daoMembersFactory.owner(), user1, "New owner should be user1");
    }
    
    /**
     * @dev Prueba el fallo al transferir propiedad a address(0)
     */
    function testTransferFactoryOwnershipToZero() public {
        vm.expectRevert("Nueva direccion de propietario no puede ser cero");
        daoMembersFactory.transferFactoryOwnership(address(0));
    }
    
    /**
     * @dev Prueba el fallo al transferir propiedad al propietario actual
     */
    function testTransferFactoryOwnershipToCurrentOwner() public {
        vm.expectRevert("La nueva direccion debe ser diferente al propietario actual");
        daoMembersFactory.transferFactoryOwnership(owner);
    }
    
    /**
     * @dev Prueba el fallo al transferir propiedad sin ser propietario
     */
    function testTransferFactoryOwnershipUnauthorized() public {
        vm.expectRevert();
        vm.prank(user1);
        daoMembersFactory.transferFactoryOwnership(user2);
    }
    
    /**
     * @dev Prueba la actualización de la tarifa de creación
     */
    function testSetDAOCreationFee() public {
        uint256 newFee = 0.002 ether;
        
        vm.expectEmit(false, false, false, true);
        emit FeeUpdated(DAO_CREATION_FEE, newFee);
        
        daoMembersFactory.setDAOCreationFee(newFee);
        assertEq(daoMembersFactory.getDAOCreationFee(), newFee, "Fee should be updated");
    }
    
    /**
     * @dev Prueba el fallo al establecer la misma tarifa
     */
    function testSetDAOCreationFeeSameValue() public {
        vm.expectRevert("DAOMembersFactory: Fee is already set to this value");
        daoMembersFactory.setDAOCreationFee(DAO_CREATION_FEE);
    }
    
    /**
     * @dev Prueba el fallo al cambiar tarifa sin ser propietario
     */
    function testSetDAOCreationFeeUnauthorized() public {
        vm.expectRevert();
        vm.prank(user1);
        daoMembersFactory.setDAOCreationFee(0.002 ether);
    }
    
    /**
     * @dev Prueba la actualización del mínimo de NFTs requeridos
     */
    function testSetMinNFTsRequired() public {
        uint256 newMinNFTs = 10;
        
        vm.expectEmit(false, false, false, true);
        emit MinNFTsRequiredUpdated(MIN_NFTS_REQUIRED, newMinNFTs);
        
        daoMembersFactory.setMinNFTsRequired(newMinNFTs);
        assertEq(daoMembersFactory.getMinNFTsRequired(), newMinNFTs, "Min NFTs should be updated");
    }
    
    /**
     * @dev Prueba el fallo al establecer el mismo mínimo de NFTs
     */
    function testSetMinNFTsRequiredSameValue() public {
        vm.expectRevert("DAOMembersFactory: Min NFTs is already set to this value");
        daoMembersFactory.setMinNFTsRequired(MIN_NFTS_REQUIRED);
    }
    
    /**
     * @dev Prueba el fallo al establecer mínimo de NFTs en 0
     */
    function testSetMinNFTsRequiredZero() public {
        vm.expectRevert("DAOMembersFactory: Min NFTs must be greater than 0");
        daoMembersFactory.setMinNFTsRequired(0);
    }
    
    /**
     * @dev Prueba el fallo al cambiar mínimo de NFTs sin ser propietario
     */
    function testSetMinNFTsRequiredUnauthorized() public {
        vm.expectRevert();
        vm.prank(user1);
        daoMembersFactory.setMinNFTsRequired(10);
    }
    
    /**
     * @dev Prueba la creación de múltiples DAOs
     */
    function testMultipleDAOCreation() public {
        address nftAddress = address(nftContract);
        
        // Crear primer DAO
        vm.prank(user1);
        address daoAddress1 = daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        // Mintear más NFTs para user2 para que pueda crear un DAO
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(user2);
            nftContract.mint{value: 1 ether}();
        }
        
        // Crear segundo DAO
        vm.prank(user2);
        address daoAddress2 = daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS + 5,
            MIN_VOTES_TO_APPROVE + 2,
            MIN_TOKENS_TO_APPROVE + 10
        );
        
        assertEq(daoMembersFactory.getTotalDAOs(), 2, "Total DAOs should be 2");
        assertEq(daoMembersFactory.getDAOByIndex(0), daoAddress1, "First DAO should match");
        assertEq(daoMembersFactory.getDAOByIndex(1), daoAddress2, "Second DAO should match");
        assertEq(daoMembersFactory.getDAOCreator(daoAddress1), user1, "First DAO creator should be user1");
        assertEq(daoMembersFactory.getDAOCreator(daoAddress2), user2, "Second DAO creator should be user2");
    }
    
    /**
     * @dev Prueba el funcionamiento después de cambiar los requisitos
     */
    function testFunctionalityAfterChangingRequirements() public {
        address nftAddress = address(nftContract);
        
        // Cambiar el mínimo de NFTs requeridos a 3
        daoMembersFactory.setMinNFTsRequired(3);
        
        // Ahora user2 debería poder crear un DAO
        vm.prank(user2);
        address daoAddress = daoMembersFactory.deployDAO{value: DAO_CREATION_FEE}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        assertTrue(daoAddress != address(0), "DAO should be created successfully");
        assertEq(daoMembersFactory.getTotalDAOs(), 1, "Total DAOs should be 1");
    }
    
    /**
     * @dev Prueba el funcionamiento después de cambiar la tarifa
     */
    function testFunctionalityAfterChangingFee() public {
        address nftAddress = address(nftContract);
        uint256 newFee = 0.002 ether;
        
        // Cambiar la tarifa
        daoMembersFactory.setDAOCreationFee(newFee);
        
        // Crear DAO con la nueva tarifa
        vm.prank(user1);
        address daoAddress = daoMembersFactory.deployDAO{value: newFee}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        assertTrue(daoAddress != address(0), "DAO should be created successfully");
        assertEq(daoMembersFactory.getTotalDAOs(), 1, "Total DAOs should be 1");
    }
    
    /**
     * @dev Prueba que el contrato maneja correctamente el ETH enviado
     */
    function testETHHandling() public {
        address nftAddress = address(nftContract);
        uint256 ownerBalanceBefore = owner.balance;
        
        // Enviar más ETH del necesario
        vm.prank(user1);
        daoMembersFactory.deployDAO{value: DAO_CREATION_FEE + 0.001 ether}(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        uint256 ownerBalanceAfter = owner.balance;
        assertEq(ownerBalanceAfter - ownerBalanceBefore, DAO_CREATION_FEE + 0.001 ether, "Owner should receive all ETH sent");
    }
}
