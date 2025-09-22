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
import {DAOFactory} from "../contracts/DAOFactory.sol";
import {DAO} from "../contracts/DAO.sol";
import {SimpleNFT} from "../contracts/SimpleNFT.sol";

/**
 * @title DAOFactoryTest
 * @dev Pruebas completas para el contrato DAOFactory
 * @notice Cubre todas las funcionalidades del factory incluyendo despliegue, consultas y ownership
 */
contract DAOFactoryTest is Test {
    
    DAOFactory public daoFactory;
    SimpleNFT public nftContract;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    // Parámetros para crear DAOs
    uint256 public constant MIN_PROPOSAL_CREATION_TOKENS = 10;
    uint256 public constant MIN_VOTES_TO_APPROVE = 5;
    uint256 public constant MIN_TOKENS_TO_APPROVE = 50;
    
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
    
    function setUp() public {
        // Configurar cuentas de prueba
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // Desplegar SimpleNFT para las pruebas
        nftContract = new SimpleNFT("Test NFT", "TNFT", "https://api.example.com/metadata/");
        
        // Desplegar DAOFactory
        daoFactory = new DAOFactory(owner);
    }
    
    // ============ PRUEBAS DE DESPLIEGUE ============
    
    function test_DeployDAOFactory() public {
        assertEq(daoFactory.owner(), owner);
        assertEq(daoFactory.getTotalDAOs(), 0);
    }
    
    function test_TransferFactoryOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit DAOFactoryOwnershipTransferred(owner, user1);
        
        daoFactory.transferFactoryOwnership(user1);
        assertEq(daoFactory.owner(), user1);
    }
    
    // ============ PRUEBAS DE DEPLOYDAO ============
    
    function test_DeployDAOSuccess() public {
        address nftAddress = address(nftContract);
        
        vm.prank(user1);
        address daoAddress = daoFactory.deployDAO(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        // Verificaciones post-despliegue
        assertTrue(daoAddress != address(0));
        assertEq(daoFactory.getTotalDAOs(), 1);
        assertEq(daoFactory.getDAOByIndex(0), daoAddress);
        assertEq(daoFactory.daoCreator(daoAddress), user1);
        assertTrue(daoFactory.isValidDAO(daoAddress));
        
        // Verificar que el DAO tiene la configuración correcta
        DAO dao = DAO(daoAddress);
        assertEq(dao.owner(), user1);
        assertEq(address(dao.nftContract()), nftAddress);
        assertEq(dao.MIN_PROPOSAL_CREATION_TOKENS(), MIN_PROPOSAL_CREATION_TOKENS);
        assertEq(dao.MIN_VOTES_TO_APPROVE(), MIN_VOTES_TO_APPROVE);
        assertEq(dao.MIN_TOKENS_TO_APPROVE(), MIN_TOKENS_TO_APPROVE);
    }
    
    function test_DeployDAOMultipleUsers() public {
        address nftAddress = address(nftContract);
        
        // User1 crea un DAO
        vm.prank(user1);
        address dao1 = daoFactory.deployDAO(nftAddress, 10, 5, 50);
        
        // User2 crea otro DAO
        vm.prank(user2);
        address dao2 = daoFactory.deployDAO(nftAddress, 15, 7, 75);
        
        // User3 crea un tercer DAO
        vm.prank(user3);
        address dao3 = daoFactory.deployDAO(nftAddress, 20, 10, 100);
        
        // Verificaciones
        assertEq(daoFactory.getTotalDAOs(), 3);
        assertEq(daoFactory.daoCreator(dao1), user1);
        assertEq(daoFactory.daoCreator(dao2), user2);
        assertEq(daoFactory.daoCreator(dao3), user3);
        
        // Verificar que cada usuario es propietario de su DAO
        assertEq(DAO(dao1).owner(), user1);
        assertEq(DAO(dao2).owner(), user2);
        assertEq(DAO(dao3).owner(), user3);
    }
    
    function test_DeployDAOInvalidNFTAddress() public {
        vm.prank(user1);
        vm.expectRevert("Direccion del contrato NFT invalida");
        daoFactory.deployDAO(
            address(0),
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
    }
    
    function test_DeployDAOInvalidMinProposalTokens() public {
        address nftAddress = address(nftContract);
        
        vm.prank(user1);
        vm.expectRevert("Minimo de tokens para propuestas debe ser mayor a 0");
        daoFactory.deployDAO(nftAddress, 0, MIN_VOTES_TO_APPROVE, MIN_TOKENS_TO_APPROVE);
    }
    
    function test_DeployDAOInvalidMinVotes() public {
        address nftAddress = address(nftContract);
        
        vm.prank(user1);
        vm.expectRevert("Minimo de votos para aprobar debe ser mayor a 0");
        daoFactory.deployDAO(nftAddress, MIN_PROPOSAL_CREATION_TOKENS, 0, MIN_TOKENS_TO_APPROVE);
    }
    
    function test_DeployDAOInvalidMinTokensToApprove() public {
        address nftAddress = address(nftContract);
        
        vm.prank(user1);
        vm.expectRevert("Minimo de tokens para aprobar debe ser mayor a 0");
        daoFactory.deployDAO(nftAddress, MIN_PROPOSAL_CREATION_TOKENS, MIN_VOTES_TO_APPROVE, 0);
    }
    
    // ============ PRUEBAS DE FUNCIONES DE CONSULTA ============
    
    function test_GetTotalDAOs() public {
        address nftAddress = address(nftContract);
        
        assertEq(daoFactory.getTotalDAOs(), 0);
        
        vm.prank(user1);
        daoFactory.deployDAO(nftAddress, 10, 5, 50);
        assertEq(daoFactory.getTotalDAOs(), 1);
        
        vm.prank(user2);
        daoFactory.deployDAO(nftAddress, 15, 7, 75);
        assertEq(daoFactory.getTotalDAOs(), 2);
    }
    
    function test_GetDAOByIndex() public {
        address nftAddress = address(nftContract);
        
        vm.prank(user1);
        address dao1 = daoFactory.deployDAO(nftAddress, 10, 5, 50);
        
        vm.prank(user2);
        address dao2 = daoFactory.deployDAO(nftAddress, 15, 7, 75);
        
        assertEq(daoFactory.getDAOByIndex(0), dao1);
        assertEq(daoFactory.getDAOByIndex(1), dao2);
    }
    
    function test_GetDAOByIndexOutOfRange() public {
        vm.expectRevert("Indice fuera de rango");
        daoFactory.getDAOByIndex(0);
        
        address nftAddress = address(nftContract);
        vm.prank(user1);
        daoFactory.deployDAO(nftAddress, 10, 5, 50);
        
        vm.expectRevert("Indice fuera de rango");
        daoFactory.getDAOByIndex(1);
    }
    
    function test_GetAllDAOs() public {
        address nftAddress = address(nftContract);
        
        // Sin DAOs
        address[] memory emptyDAOs = daoFactory.getAllDAOs();
        assertEq(emptyDAOs.length, 0);
        
        // Con DAOs
        vm.prank(user1);
        address dao1 = daoFactory.deployDAO(nftAddress, 10, 5, 50);
        
        vm.prank(user2);
        address dao2 = daoFactory.deployDAO(nftAddress, 15, 7, 75);
        
        address[] memory allDAOs = daoFactory.getAllDAOs();
        assertEq(allDAOs.length, 2);
        assertEq(allDAOs[0], dao1);
        assertEq(allDAOs[1], dao2);
    }
    
    function test_GetDAOCreator() public {
        address nftAddress = address(nftContract);
        
        vm.prank(user1);
        address dao1 = daoFactory.deployDAO(nftAddress, 10, 5, 50);
        
        vm.prank(user2);
        address dao2 = daoFactory.deployDAO(nftAddress, 15, 7, 75);
        
        assertEq(daoFactory.getDAOCreator(dao1), user1);
        assertEq(daoFactory.getDAOCreator(dao2), user2);
    }
    
    function test_GetDAOCreatorInvalidDAO() public {
        vm.expectRevert("DAO no valido o no creado por esta factory");
        daoFactory.getDAOCreator(user1);
    }
    
    function test_IsDAO() public {
        address nftAddress = address(nftContract);
        
        // Dirección que no es un DAO
        assertFalse(daoFactory.isDAO(user1));
        
        // Crear un DAO
        vm.prank(user1);
        address dao1 = daoFactory.deployDAO(nftAddress, 10, 5, 50);
        
        // Verificar que es un DAO válido
        assertTrue(daoFactory.isDAO(dao1));
        assertFalse(daoFactory.isDAO(user2));
    }
    
    function test_GetFactoryStats() public {
        address nftAddress = address(nftContract);
        
        // Sin DAOs
        (uint256 totalDAOs, address factoryOwner) = daoFactory.getFactoryStats();
        assertEq(totalDAOs, 0);
        assertEq(factoryOwner, owner);
        
        // Con DAOs
        vm.prank(user1);
        daoFactory.deployDAO(nftAddress, 10, 5, 50);
        
        vm.prank(user2);
        daoFactory.deployDAO(nftAddress, 15, 7, 75);
        
        (totalDAOs, factoryOwner) = daoFactory.getFactoryStats();
        assertEq(totalDAOs, 2);
        assertEq(factoryOwner, owner);
    }
    
    // ============ PRUEBAS DE OWNERSHIP DEL FACTORY ============
    
    function test_TransferFactoryOwnershipSuccess() public {
        vm.expectEmit(true, true, true, true);
        emit DAOFactoryOwnershipTransferred(owner, user1);
        
        daoFactory.transferFactoryOwnership(user1);
        assertEq(daoFactory.owner(), user1);
    }
    
    function test_TransferFactoryOwnershipOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        daoFactory.transferFactoryOwnership(user2);
    }
    
    function test_TransferFactoryOwnershipToZeroAddress() public {
        vm.expectRevert("Nueva direccion de propietario no puede ser cero");
        daoFactory.transferFactoryOwnership(address(0));
    }
    
    function test_TransferFactoryOwnershipToCurrentOwner() public {
        vm.expectRevert("La nueva direccion debe ser diferente al propietario actual");
        daoFactory.transferFactoryOwnership(owner);
    }
    
    // ============ PRUEBAS DE INTEGRACIÓN ============
    
    function test_DAOFunctionalAfterCreation() public {
        address nftAddress = address(nftContract);
        
        // Crear un DAO
        vm.prank(user1);
        address daoAddress = daoFactory.deployDAO(
            nftAddress,
            MIN_PROPOSAL_CREATION_TOKENS,
            MIN_VOTES_TO_APPROVE,
            MIN_TOKENS_TO_APPROVE
        );
        
        DAO dao = DAO(daoAddress);
        
        // Verificar configuración inicial
        assertEq(dao.owner(), user1);
        assertEq(address(dao.nftContract()), nftAddress);
        assertEq(dao.MIN_PROPOSAL_CREATION_TOKENS(), MIN_PROPOSAL_CREATION_TOKENS);
        assertEq(dao.MIN_VOTES_TO_APPROVE(), MIN_VOTES_TO_APPROVE);
        assertEq(dao.MIN_TOKENS_TO_APPROVE(), MIN_TOKENS_TO_APPROVE);
        
        // Verificar que user1 puede usar funciones de owner
        uint256 newMinTokens = 25;
        vm.prank(user1);
        dao.updateCreationMinProposalTokens(newMinTokens);
        assertEq(dao.MIN_PROPOSAL_CREATION_TOKENS(), newMinTokens);
    }
    
    function test_MultipleDAOsIndependent() public {
        address nftAddress = address(nftContract);
        
        // Crear múltiples DAOs con diferentes configuraciones
        vm.prank(user1);
        address dao1 = daoFactory.deployDAO(nftAddress, 10, 5, 50);
        
        vm.prank(user2);
        address dao2 = daoFactory.deployDAO(nftAddress, 20, 10, 100);
        
        DAO dao1Instance = DAO(dao1);
        DAO dao2Instance = DAO(dao2);
        
        // Verificar que son independientes
        assertEq(dao1Instance.owner(), user1);
        assertEq(dao2Instance.owner(), user2);
        
        // Cambiar configuración en uno no afecta al otro
        vm.prank(user1);
        dao1Instance.updateCreationMinProposalTokens(15);
        
        assertEq(dao1Instance.MIN_PROPOSAL_CREATION_TOKENS(), 15);
        assertEq(dao2Instance.MIN_PROPOSAL_CREATION_TOKENS(), 20);
    }
    
    // ============ PRUEBAS DE LÍMITES Y EDGE CASES ============
    
    function test_DeployDAOMaxValues() public {
        address nftAddress = address(nftContract);
        
        // Probar con valores máximos
        uint256 maxValue = type(uint256).max;
        
        vm.prank(user1);
        address daoAddress = daoFactory.deployDAO(
            nftAddress,
            maxValue,
            maxValue,
            maxValue
        );
        
        DAO dao = DAO(daoAddress);
        assertEq(dao.MIN_PROPOSAL_CREATION_TOKENS(), maxValue);
        assertEq(dao.MIN_VOTES_TO_APPROVE(), maxValue);
        assertEq(dao.MIN_TOKENS_TO_APPROVE(), maxValue);
    }
    
    function test_DeployDAOMinValues() public {
        address nftAddress = address(nftContract);
        
        // Probar con valores mínimos válidos
        vm.prank(user1);
        address daoAddress = daoFactory.deployDAO(nftAddress, 1, 1, 1);
        
        DAO dao = DAO(daoAddress);
        assertEq(dao.MIN_PROPOSAL_CREATION_TOKENS(), 1);
        assertEq(dao.MIN_VOTES_TO_APPROVE(), 1);
        assertEq(dao.MIN_TOKENS_TO_APPROVE(), 1);
    }
    
    function test_DeployDAOLargeArray() public {
        address nftAddress = address(nftContract);
        
        // Crear muchos DAOs para probar el array
        uint256 numDAOs = 10;
        
        for (uint256 i = 0; i < numDAOs; i++) {
            address user = makeAddr(string(abi.encodePacked("user", i)));
            vm.prank(user);
            daoFactory.deployDAO(nftAddress, 10 + i, 5 + i, 50 + i);
        }
        
        assertEq(daoFactory.getTotalDAOs(), numDAOs);
        
        // Verificar que todos los DAOs son accesibles
        for (uint256 i = 0; i < numDAOs; i++) {
            address daoAddress = daoFactory.getDAOByIndex(i);
            assertTrue(daoAddress != address(0));
            assertTrue(daoFactory.isValidDAO(daoAddress));
        }
    }
}
