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

import {DAO} from "./DAO.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DAOFactory
 * @dev Factory contract para desplegar instancias de DAO
 * @notice Permite a cualquier usuario crear su propia instancia de DAO donde será el propietario
 */
contract DAOFactory is Ownable {
    
    // Array para almacenar todas las direcciones de DAOs creados
    address[] public deployedDAOs;
    
    // Mapping para rastrear quién creó cada DAO
    mapping(address => address) public daoCreator;
    
    // Mapping para verificar si una dirección es un DAO válido creado por esta factory
    mapping(address => bool) public isValidDAO;
    
    // Eventos para rastrear la creación de DAOs
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
    
    /**
     * @dev Constructor del DAOFactory
     * @param initialOwner Dirección del propietario inicial del factory
     */
    constructor(address initialOwner) Ownable(initialOwner) {}
    
    /**
     * @dev Despliega una nueva instancia de DAO
     * @param nftContract Dirección del contrato NFT que se usará para votaciones
     * @param minProposalCreationTokens Mínimo de NFTs necesarios para crear propuestas
     * @param minVotesToApprove Mínimo número de votantes únicos para aprobar
     * @param minTokensToApprove Mínimo poder de votación total para aprobar
     * @return daoAddress Dirección del nuevo contrato DAO desplegado
     */
    function deployDAO(
        address nftContract,
        uint256 minProposalCreationTokens,
        uint256 minVotesToApprove,
        uint256 minTokensToApprove
    ) external returns (address daoAddress) {
        // Validaciones de entrada
        require(nftContract != address(0), "Direccion del contrato NFT invalida");
        require(minProposalCreationTokens > 0, "Minimo de tokens para propuestas debe ser mayor a 0");
        require(minVotesToApprove > 0, "Minimo de votos para aprobar debe ser mayor a 0");
        require(minTokensToApprove > 0, "Minimo de tokens para aprobar debe ser mayor a 0");
        
        // Desplegar nuevo contrato DAO con msg.sender como propietario
        DAO newDAO = new DAO(
            nftContract,
            minProposalCreationTokens,
            minVotesToApprove,
            minTokensToApprove
        );
        
        daoAddress = address(newDAO);
        
        // Transferir ownership del DAO al usuario que lo despliega
        newDAO.transferOwnership(msg.sender);
        
        // Registrar el DAO en la factory
        deployedDAOs.push(daoAddress);
        daoCreator[daoAddress] = msg.sender;
        isValidDAO[daoAddress] = true;
        
        // Emitir evento
        emit DAOCreated(
            daoAddress,
            msg.sender,
            nftContract,
            minProposalCreationTokens,
            minVotesToApprove,
            minTokensToApprove
        );
        
        return daoAddress;
    }
    
    /**
     * @dev Obtiene el número total de DAOs desplegados
     * @return Número total de DAOs creados por esta factory
     */
    function getTotalDAOs() external view returns (uint256) {
        return deployedDAOs.length;
    }
    
    /**
     * @dev Obtiene la dirección de un DAO por índice
     * @param index Índice del DAO en el array
     * @return Dirección del DAO en el índice especificado
     */
    function getDAOByIndex(uint256 index) external view returns (address) {
        require(index < deployedDAOs.length, "Indice fuera de rango");
        return deployedDAOs[index];
    }
    
    /**
     * @dev Obtiene todos los DAOs desplegados
     * @return Array con todas las direcciones de DAOs
     */
    function getAllDAOs() external view returns (address[] memory) {
        return deployedDAOs;
    }
    
    /**
     * @dev Obtiene información del creador de un DAO
     * @param daoAddress Dirección del DAO
     * @return Dirección del usuario que creó el DAO
     */
    function getDAOCreator(address daoAddress) external view returns (address) {
        require(isValidDAO[daoAddress], "DAO no valido o no creado por esta factory");
        return daoCreator[daoAddress];
    }
    
    /**
     * @dev Verifica si una dirección es un DAO válido creado por esta factory
     * @param daoAddress Dirección a verificar
     * @return true si es un DAO válido, false en caso contrario
     */
    function isDAO(address daoAddress) external view returns (bool) {
        return isValidDAO[daoAddress];
    }
    
    /**
     * @dev Función para transferir ownership del factory (solo el propietario actual)
     * @param newOwner Nueva dirección del propietario
     */
    function transferFactoryOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Nueva direccion de propietario no puede ser cero");
        require(newOwner != owner(), "La nueva direccion debe ser diferente al propietario actual");
        
        address previousOwner = owner();
        _transferOwnership(newOwner);
        
        emit DAOFactoryOwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev Función para obtener estadísticas de la factory
     * @return totalDAOs Número total de DAOs desplegados
     * @return factoryOwner Dirección del propietario del factory
     */
    function getFactoryStats() external view returns (uint256 totalDAOs, address factoryOwner) {
        return (deployedDAOs.length, owner());
    }
}
