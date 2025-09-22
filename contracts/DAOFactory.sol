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

contract DAOFactory is Ownable {
    
    address[] public deployedDAOs;
    
    mapping(address => address) public daoCreator;
    
    mapping(address => bool) public isValidDAO;
    
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
    
    constructor(address initialOwner) Ownable(initialOwner) {}
    
    function deployDAO(
        address nftContract,
        uint256 minProposalCreationTokens,
        uint256 minVotesToApprove,
        uint256 minTokensToApprove
    ) external returns (address daoAddress) {
        require(nftContract != address(0), "Direccion del contrato NFT invalida");
        require(minProposalCreationTokens > 0, "Minimo de tokens para propuestas debe ser mayor a 0");
        require(minVotesToApprove > 0, "Minimo de votos para aprobar debe ser mayor a 0");
        require(minTokensToApprove > 0, "Minimo de tokens para aprobar debe ser mayor a 0");
        
        DAO newDAO = new DAO(
            nftContract,
            minProposalCreationTokens,
            minVotesToApprove,
            minTokensToApprove
        );
        
        daoAddress = address(newDAO);
        
        newDAO.transferOwnership(msg.sender);
        
        deployedDAOs.push(daoAddress);
        daoCreator[daoAddress] = msg.sender;
        isValidDAO[daoAddress] = true;
        
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
    
    function getTotalDAOs() external view returns (uint256) {
        return deployedDAOs.length;
    }
    
    function getDAOByIndex(uint256 index) external view returns (address) {
        require(index < deployedDAOs.length, "Indice fuera de rango");
        return deployedDAOs[index];
    }
    
    function getAllDAOs() external view returns (address[] memory) {
        return deployedDAOs;
    }
    
    function getDAOCreator(address daoAddress) external view returns (address) {
        require(isValidDAO[daoAddress], "DAO no valido o no creado por esta factory");
        return daoCreator[daoAddress];
    }
    
    function isDAO(address daoAddress) external view returns (bool) {
        return isValidDAO[daoAddress];
    }
    
    function transferFactoryOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Nueva direccion de propietario no puede ser cero");
        require(newOwner != owner(), "La nueva direccion debe ser diferente al propietario actual");
        
        address previousOwner = owner();
        _transferOwnership(newOwner);
        
        emit DAOFactoryOwnershipTransferred(previousOwner, newOwner);
    }
    
    function getFactoryStats() external view returns (uint256 totalDAOs, address factoryOwner) {
        return (deployedDAOs.length, owner());
    }
}
