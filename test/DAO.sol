// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/DAO.sol";
import "../contracts/SimpleNFT.sol";

/**
 * @title DAOTest
 * @dev Pruebas completas para el contrato DAO
 * @author cjbaezilla
 * @notice Este archivo contiene todas las pruebas unitarias para el contrato DAO
 */
contract DAOTest is Test {
    DAO public dao;
    SimpleNFT public nft;
    
    // Función para recibir ether del minting
    receive() external payable {}
    
    address public deployer;
    address public user1;
    address public user2;
    address public user3;
    address public user4;
    address public nonOwner;
    
    // Parámetros de prueba
    string constant NAME = "Test NFT";
    string constant SYMBOL = "TNFT";
    string constant BASE_URI = "https://api.example.com/metadata/";
    uint256 constant MINT_PRICE = 1 ether;
    
    // Parámetros del DAO
    string constant DAO_NAME = "Test DAO";
    uint256 constant MIN_PROPOSAL_CREATION_TOKENS = 10;
    uint256 constant MIN_VOTES_TO_APPROVE = 10;
    uint256 constant MIN_TOKENS_TO_APPROVE = 50;
    
    // Eventos esperados
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        uint256 startTime,
        uint256 endTime
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 votes
    );
    
    event ProposalCancelled(uint256 indexed proposalId);
    
    event NFTContractUpdated(address indexed oldContract, address indexed newContract);
    event MinProposalVotesUpdated(uint256 indexed oldValue, uint256 indexed newValue);
    event MinVotesToApproveUpdated(uint256 indexed oldValue, uint256 indexed newValue);
    event MinTokensToApproveUpdated(uint256 indexed oldValue, uint256 indexed newValue);

    function setUp() public {
        // Configurar cuentas de prueba
        deployer = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");
        nonOwner = makeAddr("nonOwner");
        
        // Dar ether al contrato de prueba para recibir transferencias
        vm.deal(address(this), 1000 ether);
        
        // Desplegar contrato NFT
        nft = new SimpleNFT(NAME, SYMBOL, BASE_URI);
        
        // Desplegar contrato DAO
        dao = new DAO(DAO_NAME, address(nft), MIN_PROPOSAL_CREATION_TOKENS, MIN_VOTES_TO_APPROVE, MIN_TOKENS_TO_APPROVE);
        
        // Configurar usuarios con NFTs para las pruebas
        setupTestUsers();
        
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
     * @dev Función helper para crear propuestas en las pruebas
     */
    function createTestProposal(address proposer, uint256 startTime, uint256 endTime) internal returns (uint256) {
        vm.prank(proposer);
        dao.createProposal("Test proposal", "https://example.com", startTime, endTime);
        return dao.proposalCount() - 1;
    }
    
    /**
     * @dev Configura usuarios de prueba con diferentes cantidades de NFTs
     */
    function setupTestUsers() internal {
        // Dar ether a los usuarios para que puedan mintear
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(user4, 100 ether);
        
        // User1: 15 NFTs (puede crear propuestas)
        vm.startPrank(user1);
        for (uint256 i = 0; i < 15; i++) {
            nft.mint{value: MINT_PRICE}();
        }
        vm.stopPrank();
        
        // User2: 5 NFTs (puede votar pero no crear propuestas)
        vm.startPrank(user2);
        for (uint256 i = 0; i < 5; i++) {
            nft.mint{value: MINT_PRICE}();
        }
        vm.stopPrank();
        
        // User3: 8 NFTs (puede votar pero no crear propuestas)
        vm.startPrank(user3);
        for (uint256 i = 0; i < 8; i++) {
            nft.mint{value: MINT_PRICE}();
        }
        vm.stopPrank();
        
        // User4: 20 NFTs (puede crear propuestas)
        vm.startPrank(user4);
        for (uint256 i = 0; i < 20; i++) {
            nft.mint{value: MINT_PRICE}();
        }
        vm.stopPrank();
    }

    // ============ PRUEBAS DEL CONSTRUCTOR ============
    
    function test_Constructor_SetsName() public view {
        assertEq(dao.name(), DAO_NAME);
    }
    
    function test_Constructor_SetsNFTContract() public view {
        assertEq(address(dao.nftContract()), address(nft));
    }
    
    function test_Constructor_SetsOwner() public view {
        assertEq(dao.owner(), deployer);
    }
    
    function test_Constructor_InitialProposalCount() public view {
        assertEq(dao.proposalCount(), 0);
    }
    
    function test_Constructor_InitialParameters() public view {
        assertEq(dao.MIN_PROPOSAL_CREATION_TOKENS(), MIN_PROPOSAL_CREATION_TOKENS);
        assertEq(dao.MIN_VOTES_TO_APPROVE(), MIN_VOTES_TO_APPROVE);
        assertEq(dao.MIN_TOKENS_TO_APPROVE(), MIN_TOKENS_TO_APPROVE);
    }

    // ============ PRUEBAS DE CREACIÓN DE PROPUESTAS ============
    
    function test_CreateProposal_Success() public {
        string memory description = "Propuesta de prueba";
        string memory link = "https://example.com";
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal(description, link, startTime, endTime);
        
        DAO.Proposal memory proposal = dao.getProposal(0);
        assertEq(proposal.id, 0);
        assertEq(proposal.proposer, user1);
        assertEq(proposal.description, description);
        assertEq(proposal.link, link);
        assertEq(proposal.votesFor, 0);
        assertEq(proposal.votesAgainst, 0);
        assertEq(proposal.startTime, startTime);
        assertEq(proposal.endTime, endTime);
        assertFalse(proposal.cancelled);
    }
    
    function test_CreateProposal_IncrementsProposalCount() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        assertEq(dao.proposalCount(), 0);
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        assertEq(dao.proposalCount(), 1);
        
        vm.prank(user4);
        dao.createProposal("desc2", "link2", startTime, endTime);
        assertEq(dao.proposalCount(), 2);
    }
    
    function test_CreateProposal_RevertsInsufficientNFTs() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user2); // Solo tiene 5 NFTs
        vm.expectRevert("Necesitas al menos 10 NFTs para crear propuesta");
        dao.createProposal("desc", "link", startTime, endTime);
    }
    
    function test_CreateProposal_RevertsStartTimeInPast() public {
        uint256 startTime = block.timestamp - 1;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        vm.expectRevert("startTime debe ser en el futuro");
        dao.createProposal("desc", "link", startTime, endTime);
    }
    
    function test_CreateProposal_RevertsEndTimeNotGreater() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime;
        
        vm.prank(user1);
        vm.expectRevert("endTime debe ser mayor que startTime");
        dao.createProposal("desc", "link", startTime, endTime);
    }
    
    function test_CreateProposal_RevertsCooldownNotMet() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear primera propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Intentar crear segunda propuesta inmediatamente
        vm.prank(user1);
        vm.expectRevert("Solo puedes crear una propuesta cada 24 horas");
        dao.createProposal("desc2", "link2", startTime + 120, endTime + 120);
    }
    
    function test_CreateProposal_AllowsAfterCooldown() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear primera propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Avanzar tiempo 25 horas
        vm.warp(block.timestamp + 25 hours);
        
        // Crear segunda propuesta
        vm.prank(user1);
        dao.createProposal("desc2", "link2", block.timestamp + 60, block.timestamp + 3660);
        
        assertEq(dao.proposalCount(), 2);
    }

    // ============ PRUEBAS DEL SISTEMA DE VOTACIÓN ============
    
    function test_Vote_SuccessFor() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Avanzar tiempo para que comience la votación
        vm.warp(startTime + 1);
        
        vm.expectEmit(true, true, true, true);
        emit VoteCast(0, user2, true, 5);
        
        vm.prank(user2);
        dao.vote(0, true);
        
        DAO.Proposal memory proposal = dao.getProposal(0);
        assertEq(proposal.votesFor, 5);
        assertEq(proposal.votesAgainst, 0);
        assertTrue(dao.hasVoted(0, user2));
        assertEq(dao.proposalUniqueVotersCount(0), 1);
        assertEq(dao.proposalTotalVotingPowerSum(0), 5);
    }
    
    function test_Vote_SuccessAgainst() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Avanzar tiempo para que comience la votación
        vm.warp(startTime + 1);
        
        vm.expectEmit(true, true, true, true);
        emit VoteCast(0, user2, false, 5);
        
        vm.prank(user2);
        dao.vote(0, false);
        
        DAO.Proposal memory proposal = dao.getProposal(0);
        assertEq(proposal.votesFor, 0);
        assertEq(proposal.votesAgainst, 5);
        assertTrue(dao.hasVoted(0, user2));
    }
    
    function test_Vote_MultipleVoters() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Avanzar tiempo para que comience la votación
        vm.warp(startTime + 1);
        
        // User2 vota a favor
        vm.prank(user2);
        dao.vote(0, true);
        
        // User3 vota en contra
        vm.prank(user3);
        dao.vote(0, false);
        
        DAO.Proposal memory proposal = dao.getProposal(0);
        assertEq(proposal.votesFor, 5); // user2 tiene 5 NFTs
        assertEq(proposal.votesAgainst, 8); // user3 tiene 8 NFTs
        assertEq(dao.proposalUniqueVotersCount(0), 2);
        assertEq(dao.proposalTotalVotingPowerSum(0), 13); // 5 + 8
    }
    
    function test_Vote_RevertsProposalNotExists() public {
        vm.prank(user2);
        vm.expectRevert("Propuesta no existe");
        dao.vote(999, true);
    }
    
    function test_Vote_RevertsVotingNotStarted() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Intentar votar antes del inicio
        vm.prank(user2);
        vm.expectRevert("Votacion no ha comenzado");
        dao.vote(0, true);
    }
    
    function test_Vote_RevertsVotingEnded() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Avanzar tiempo después del final
        vm.warp(endTime + 1);
        
        vm.prank(user2);
        vm.expectRevert("Votacion ha terminado");
        dao.vote(0, true);
    }
    
    function test_Vote_RevertsProposalCancelled() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Cancelar propuesta
        vm.prank(user1);
        dao.cancelProposal(0);
        
        // Avanzar tiempo para que comience la votación
        vm.warp(startTime + 1);
        
        vm.prank(user2);
        vm.expectRevert("Propuesta cancelada");
        dao.vote(0, true);
    }
    
    function test_Vote_RevertsAlreadyVoted() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Avanzar tiempo para que comience la votación
        vm.warp(startTime + 1);
        
        // Votar primera vez
        vm.prank(user2);
        dao.vote(0, true);
        
        // Intentar votar segunda vez
        vm.prank(user2);
        vm.expectRevert("Ya votaste en esta propuesta");
        dao.vote(0, false);
    }
    
    function test_Vote_RevertsNoNFTs() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Avanzar tiempo para que comience la votación
        vm.warp(startTime + 1);
        
        // Usuario sin NFTs intenta votar
        vm.prank(nonOwner);
        vm.expectRevert("Necesitas al menos 1 NFT para votar");
        dao.vote(0, true);
    }

    // ============ PRUEBAS DE CANCELACIÓN DE PROPUESTAS ============
    
    function test_CancelProposal_Success() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        vm.expectEmit(true, false, false, false);
        emit ProposalCancelled(0);
        
        vm.prank(user1);
        dao.cancelProposal(0);
        
        DAO.Proposal memory proposal = dao.getProposal(0);
        assertTrue(proposal.cancelled);
    }
    
    function test_CancelProposal_RevertsProposalNotExists() public {
        vm.prank(user1);
        vm.expectRevert("Propuesta no existe");
        dao.cancelProposal(999);
    }
    
    function test_CancelProposal_RevertsNotProposer() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // User2 intenta cancelar
        vm.prank(user2);
        vm.expectRevert("Solo el proposer puede cancelar");
        dao.cancelProposal(0);
    }
    
    function test_CancelProposal_RevertsAlreadyCancelled() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Cancelar primera vez
        vm.prank(user1);
        dao.cancelProposal(0);
        
        // Intentar cancelar segunda vez
        vm.prank(user1);
        vm.expectRevert("Propuesta ya cancelada");
        dao.cancelProposal(0);
    }
    
    function test_CancelProposal_RevertsVotingEnded() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        // Crear propuesta
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        // Avanzar tiempo después del final
        vm.warp(endTime + 1);
        
        vm.prank(user1);
        vm.expectRevert("Votacion ya termino");
        dao.cancelProposal(0);
    }

    // ============ PRUEBAS DE FUNCIONES DE CONSULTA ============
    
    function test_GetVotingPower() public view {
        assertEq(dao.getVotingPower(user1), 15);
        assertEq(dao.getVotingPower(user2), 5);
        assertEq(dao.getVotingPower(user3), 8);
        assertEq(dao.getVotingPower(user4), 20);
        assertEq(dao.getVotingPower(nonOwner), 0);
    }
    
    function test_GetTotalProposals() public {
        assertEq(dao.getTotalProposals(), 0);
        
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        assertEq(dao.getTotalProposals(), 1);
        
        vm.prank(user4);
        dao.createProposal("desc2", "link2", startTime, endTime);
        assertEq(dao.getTotalProposals(), 2);
    }
    
    function test_GetProposalStatus_NotExists() public view {
        assertEq(dao.getProposalStatus(999), "No existe");
    }
    
    function test_GetProposalStatus_Pending() public {
        uint256 startTime = block.timestamp + 3600;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        assertEq(dao.getProposalStatus(0), "Pendiente");
    }
    
    function test_GetProposalStatus_Voting() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        vm.warp(startTime + 1);
        assertEq(dao.getProposalStatus(0), "Votando");
    }
    
    function test_GetProposalStatus_Cancelled() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        vm.prank(user1);
        dao.cancelProposal(0);
        
        assertEq(dao.getProposalStatus(0), "Cancelada");
    }
    
    function test_GetProposalStatus_Approved() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        vm.warp(startTime + 1);
        
        // Crear más usuarios para cumplir con los requisitos mínimos
        address[] memory additionalUsers = new address[](6);
        for (uint256 i = 0; i < 6; i++) {
            additionalUsers[i] = makeAddr(string(abi.encodePacked("user", i + 5)));
            vm.deal(additionalUsers[i], 100 ether);
            vm.startPrank(additionalUsers[i]);
            nft.mint{value: MINT_PRICE}();
            vm.stopPrank();
        }
        
        // Votar con suficientes usuarios y tokens
        vm.prank(user1);
        dao.vote(0, true);
        vm.prank(user2);
        dao.vote(0, true);
        vm.prank(user3);
        dao.vote(0, true);
        vm.prank(user4);
        dao.vote(0, true);
        
        // Votar con usuarios adicionales para cumplir requisitos
        for (uint256 i = 0; i < 6; i++) {
            vm.prank(additionalUsers[i]);
            dao.vote(0, true);
        }
        
        vm.warp(endTime + 1);
        assertEq(dao.getProposalStatus(0), "Aprobada");
    }
    
    function test_GetProposalStatus_Rejected() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        vm.warp(startTime + 1);
        
        // Votar en contra
        vm.prank(user2);
        dao.vote(0, false);
        vm.prank(user3);
        dao.vote(0, false);
        
        vm.warp(endTime + 1);
        assertEq(dao.getProposalStatus(0), "Rechazada");
    }
    
    function test_GetUniqueVotersCount() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        vm.warp(startTime + 1);
        
        assertEq(dao.getUniqueVotersCount(0), 0);
        
        vm.prank(user2);
        dao.vote(0, true);
        assertEq(dao.getUniqueVotersCount(0), 1);
        
        vm.prank(user3);
        dao.vote(0, false);
        assertEq(dao.getUniqueVotersCount(0), 2);
    }
    
    function test_GetProposalTotalVotingPower() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        vm.warp(startTime + 1);
        
        assertEq(dao.getProposalTotalVotingPower(0), 0);
        
        vm.prank(user2);
        dao.vote(0, true);
        assertEq(dao.getProposalTotalVotingPower(0), 5);
        
        vm.prank(user3);
        dao.vote(0, false);
        assertEq(dao.getProposalTotalVotingPower(0), 13); // 5 + 8
    }

    // ============ PRUEBAS DE FUNCIONES ADMINISTRATIVAS ============
    
    function test_UpdateNFTContract_Success() public {
        address newNftAddress = makeAddr("newNft");
        
        vm.expectEmit(true, true, false, false);
        emit NFTContractUpdated(address(nft), newNftAddress);
        
        dao.updateNFTContract(newNftAddress);
        
        assertEq(address(dao.nftContract()), newNftAddress);
    }
    
    function test_UpdateNFTContract_RevertsInvalidAddress() public {
        vm.expectRevert("Direccion invalida");
        dao.updateNFTContract(address(0));
    }
    
    function test_UpdateNFTContract_RevertsSameAddress() public {
        vm.expectRevert("Misma direccion actual");
        dao.updateNFTContract(address(nft));
    }
    
    function test_UpdateCreationMinProposalTokens_Success() public {
        uint256 newValue = 15;
        
        vm.expectEmit(true, true, false, false);
        emit MinProposalVotesUpdated(MIN_PROPOSAL_CREATION_TOKENS, newValue);
        
        dao.updateCreationMinProposalTokens(newValue);
        
        assertEq(dao.MIN_PROPOSAL_CREATION_TOKENS(), newValue);
    }
    
    function test_UpdateMinVotesToApprove_Success() public {
        uint256 newValue = 15;
        
        vm.expectEmit(true, true, false, false);
        emit MinVotesToApproveUpdated(MIN_VOTES_TO_APPROVE, newValue);
        
        dao.updateMinVotesToApprove(newValue);
        
        assertEq(dao.MIN_VOTES_TO_APPROVE(), newValue);
    }
    
    function test_UpdateMinTokensToApprove_Success() public {
        uint256 newValue = 100;
        
        vm.expectEmit(true, true, false, false);
        emit MinTokensToApproveUpdated(MIN_TOKENS_TO_APPROVE, newValue);
        
        dao.updateMinTokensToApprove(newValue);
        
        assertEq(dao.MIN_TOKENS_TO_APPROVE(), newValue);
    }
    
    function test_UpdateParameters_RevertsZeroValue() public {
        vm.expectRevert("Valor debe ser mayor a 0");
        dao.updateCreationMinProposalTokens(0);
        
        vm.expectRevert("Valor debe ser mayor a 0");
        dao.updateMinVotesToApprove(0);
        
        vm.expectRevert("Valor debe ser mayor a 0");
        dao.updateMinTokensToApprove(0);
    }
    
    function test_AdminFunctions_RevertsNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert();
        dao.updateNFTContract(makeAddr("newNft"));
        
        vm.prank(nonOwner);
        vm.expectRevert();
        dao.updateCreationMinProposalTokens(15);
        
        vm.prank(nonOwner);
        vm.expectRevert();
        dao.updateMinVotesToApprove(15);
        
        vm.prank(nonOwner);
        vm.expectRevert();
        dao.updateMinTokensToApprove(100);
    }

    // ============ PRUEBAS DE CASOS LÍMITE ============
    
    function test_LongDescription() public {
        string memory longDescription = new string(1000);
        for (uint256 i = 0; i < 1000; i++) {
            // Simular descripción larga
        }
        
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal(longDescription, "link", startTime, endTime);
        
        DAO.Proposal memory proposal = dao.getProposal(0);
        assertEq(proposal.description, longDescription);
    }
    
    function test_EdgeCase_MinimumVotingPower() public {
        // Crear usuario con exactamente 1 NFT
        address minUser = makeAddr("minUser");
        vm.deal(minUser, 100 ether);
        vm.startPrank(minUser);
        nft.mint{value: MINT_PRICE}();
        vm.stopPrank();
        
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        vm.warp(startTime + 1);
        
        // Debería poder votar con 1 NFT
        vm.prank(minUser);
        dao.vote(0, true);
        
        DAO.Proposal memory proposal = dao.getProposal(0);
        assertEq(proposal.votesFor, 1);
    }
    
    function test_EdgeCase_MaximumProposalCount() public {
        // Crear múltiples propuestas para probar el límite
        for (uint256 i = 0; i < 10; i++) {
            uint256 startTime = block.timestamp + 60;
            uint256 endTime = startTime + 3600;
            
            vm.prank(user1);
            dao.createProposal("desc", "link", startTime, endTime);
            vm.warp(block.timestamp + 25 hours); // Esperar cooldown
        }
        
        assertEq(dao.proposalCount(), 10);
    }

    // ============ PRUEBAS DE GAS ============
    
    function test_GasUsage_CreateProposal() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        uint256 gasStart = gasleft();
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas usado para crear propuesta:", gasUsed);
        assertTrue(gasUsed > 0);
    }
    
    function test_GasUsage_Vote() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 3600;
        
        vm.prank(user1);
        dao.createProposal("desc", "link", startTime, endTime);
        
        vm.warp(startTime + 1);
        
        uint256 gasStart = gasleft();
        vm.prank(user2);
        dao.vote(0, true);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas usado para votar:", gasUsed);
        assertTrue(gasUsed > 0);
    }
}
