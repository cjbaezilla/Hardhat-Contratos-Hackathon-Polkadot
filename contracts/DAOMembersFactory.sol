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
import "./SimpleUserManager.sol";
import "./SimpleNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DAOMembersFactory is Ownable {
    SimpleUserManager public immutable userManager;
    SimpleNFT public immutable nftContract;
    
    uint256 public MIN_NFTS_REQUIRED = 5;
    
    uint256 public daoCreationFee = 0.001 ether;
    
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
    
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event MinNFTsRequiredUpdated(uint256 oldMinNFTs, uint256 newMinNFTs);
    
    constructor(address _userManager, address _nftContract, address initialOwner) Ownable(initialOwner) {
        require(_userManager != address(0), "DAOMembersFactory: UserManager address cannot be zero");
        require(_nftContract != address(0), "DAOMembersFactory: NFT contract address cannot be zero");
        
        userManager = SimpleUserManager(_userManager);
        nftContract = SimpleNFT(_nftContract);
    }
    
    function deployDAO(
        address nftContractAddress,
        uint256 minProposalCreationTokens,
        uint256 minVotesToApprove,
        uint256 minTokensToApprove
    ) external payable returns (address daoAddress) {
        require(nftContractAddress != address(0), "DAOMembersFactory: Direccion del contrato NFT invalida");
        require(minProposalCreationTokens > 0, "DAOMembersFactory: Minimo de tokens para propuestas debe ser mayor a 0");
        require(minVotesToApprove > 0, "DAOMembersFactory: Minimo de votos para aprobar debe ser mayor a 0");
        require(minTokensToApprove > 0, "DAOMembersFactory: Minimo de tokens para aprobar debe ser mayor a 0");
        
        require(userManager.isRegisteredUser(msg.sender), "DAOMembersFactory: User must be registered");
        
        uint256 userNFTBalance = nftContract.balanceOf(msg.sender);
        require(userNFTBalance >= MIN_NFTS_REQUIRED, "DAOMembersFactory: User must have at least 5 NFTs");
        
        require(msg.value >= daoCreationFee, "DAOMembersFactory: Insufficient fee paid");
        
        if (msg.value > 0) {
            (bool success, ) = payable(owner()).call{value: msg.value}("");
            require(success, "DAOMembersFactory: Failed to transfer fee to owner");
        }
        
        DAO newDAO = new DAO(
            nftContractAddress,
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
            nftContractAddress,
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
    
    function getUserManagerAddress() external view returns (address) {
        return address(userManager);
    }

    function getNFTContractAddress() external view returns (address) {
        return address(nftContract);
    }

    function checkUserRequirements(address user) external view returns (
        bool isRegistered,
        uint256 nftBalance,
        bool canCreateDAO
    ) {
        isRegistered = userManager.isRegisteredUser(user);
        nftBalance = nftContract.balanceOf(user);
        canCreateDAO = isRegistered && nftBalance >= MIN_NFTS_REQUIRED;
    }

    function getMinNFTsRequired() external view returns (uint256) {
        return MIN_NFTS_REQUIRED;
    }
    
    function getDAOCreationFee() external view returns (uint256) {
        return daoCreationFee;
    }
    
    function setDAOCreationFee(uint256 newFee) external onlyOwner {
        require(newFee != daoCreationFee, "DAOMembersFactory: Fee is already set to this value");
        
        uint256 oldFee = daoCreationFee;
        daoCreationFee = newFee;
        
        emit FeeUpdated(oldFee, newFee);
    }
    
    function setMinNFTsRequired(uint256 newMinNFTs) external onlyOwner {
        require(newMinNFTs != MIN_NFTS_REQUIRED, "DAOMembersFactory: Min NFTs is already set to this value");
        require(newMinNFTs > 0, "DAOMembersFactory: Min NFTs must be greater than 0");
        
        uint256 oldMinNFTs = MIN_NFTS_REQUIRED;
        MIN_NFTS_REQUIRED = newMinNFTs;
        
        emit MinNFTsRequiredUpdated(oldMinNFTs, newMinNFTs);
    }
}
