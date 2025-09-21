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

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DAO is Ownable {
    struct Proposal {
        uint256 id;
        address proposer;
        string username;
        string description;
        string link;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        bool cancelled;
    }

    IERC721 public nftContract;
    uint256 public proposalCount;
    uint256 public MIN_PROPOSAL_VOTES = 10;
    uint256 public MIN_VOTES_TO_APPROVE = 10;
    uint256 public MIN_TOKENS_TO_APPROVE = 50;
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => uint256) public proposalUniqueVotersCount;
    mapping(uint256 => uint256) public proposalTotalVotingPowerSum;
    mapping(address => uint256) public lastProposalTime;
    
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

    constructor(address _nftContract) Ownable(msg.sender) {
        nftContract = IERC721(_nftContract);
    }

    function createProposal(string calldata username, string calldata description, string calldata link, uint256 startTime, uint256 endTime) external {
        uint256 nftBalance = nftContract.balanceOf(msg.sender);
        require(nftBalance >= MIN_PROPOSAL_VOTES, "Necesitas al menos 10 NFTs para crear propuesta");
        
        require(
            block.timestamp >= lastProposalTime[msg.sender] + 1 days,
            "Solo puedes crear una propuesta cada 24 horas"
        );
        
        require(startTime >= block.timestamp, "startTime debe ser en el futuro");
        require(endTime > startTime, "endTime debe ser mayor que startTime");
        
        uint256 proposalId = proposalCount++;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            username: username,
            description: description,
            link: link,
            votesFor: 0,
            votesAgainst: 0,
            startTime: startTime,
            endTime: endTime,
            cancelled: false
        });
        
        lastProposalTime[msg.sender] = block.timestamp;
        
        emit ProposalCreated(proposalId, msg.sender, description, startTime, endTime);
    }
    
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Propuesta no existe");
        require(block.timestamp >= proposal.startTime, "Votacion no ha comenzado");
        require(block.timestamp <= proposal.endTime, "Votacion ha terminado");
        require(!proposal.cancelled, "Propuesta cancelada");
        require(!hasVoted[proposalId][msg.sender], "Ya votaste en esta propuesta");
        
        uint256 nftBalance = nftContract.balanceOf(msg.sender);
        require(nftBalance > 0, "Necesitas al menos 1 NFT para votar");
        
        hasVoted[proposalId][msg.sender] = true;
        proposalUniqueVotersCount[proposalId]++;
        proposalTotalVotingPowerSum[proposalId] += nftBalance;
        
        if (support) {
            proposal.votesFor += nftBalance;
        } else {
            proposal.votesAgainst += nftBalance;
        }
        
        emit VoteCast(proposalId, msg.sender, support, nftBalance);
    }
    
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Propuesta no existe");
        require(msg.sender == proposal.proposer, "Solo el proposer puede cancelar");
        require(!proposal.cancelled, "Propuesta ya cancelada");
        require(block.timestamp <= proposal.endTime, "Votacion ya termino");
        
        proposal.cancelled = true;
        emit ProposalCancelled(proposalId);
    }

    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }
    
    function getVotingPower(address voter) external view returns (uint256) {
        return nftContract.balanceOf(voter);
    }
    
    function getProposalStatus(uint256 proposalId) external view returns (string memory) {
        Proposal memory proposal = proposals[proposalId];
        
        if (proposal.id != proposalId) return "No existe";
        if (proposal.cancelled) return "Cancelada";
        if (block.timestamp < proposal.startTime) return "Pendiente";
        if (block.timestamp <= proposal.endTime) return "Votando";
        
        if (proposal.votesFor > proposal.votesAgainst && 
            proposalUniqueVotersCount[proposalId] >= MIN_VOTES_TO_APPROVE &&
            proposalTotalVotingPowerSum[proposalId] >= MIN_TOKENS_TO_APPROVE) {
            return "Aprobada";
        }
        return "Rechazada";
    }
    
    function getTotalProposals() external view returns (uint256) {
        return proposalCount;
    }
    
    function getUniqueVotersCount(uint256 proposalId) external view returns (uint256) {
        require(proposals[proposalId].id == proposalId, "Propuesta no existe");
        return proposalUniqueVotersCount[proposalId];
    }
    
    function getProposalTotalVotingPower(uint256 proposalId) external view returns (uint256) {
        require(proposals[proposalId].id == proposalId, "Propuesta no existe");
        return proposalTotalVotingPowerSum[proposalId];
    }
    
    function updateNFTContract(address _newNftContract) external onlyOwner {
        require(_newNftContract != address(0), "Direccion invalida");
        require(_newNftContract != address(nftContract), "Misma direccion actual");
        
        address oldContract = address(nftContract);
        nftContract = IERC721(_newNftContract);
        
        emit NFTContractUpdated(oldContract, _newNftContract);
    }
    
    function updateMinProposalVotes(uint256 _newMinProposalVotes) external onlyOwner {
        require(_newMinProposalVotes > 0, "Valor debe ser mayor a 0");
        
        uint256 oldValue = MIN_PROPOSAL_VOTES;
        MIN_PROPOSAL_VOTES = _newMinProposalVotes;
        
        emit MinProposalVotesUpdated(oldValue, _newMinProposalVotes);
    }
    
    function updateMinVotesToApprove(uint256 _newMinVotesToApprove) external onlyOwner {
        require(_newMinVotesToApprove > 0, "Valor debe ser mayor a 0");
        
        uint256 oldValue = MIN_VOTES_TO_APPROVE;
        MIN_VOTES_TO_APPROVE = _newMinVotesToApprove;
        
        emit MinVotesToApproveUpdated(oldValue, _newMinVotesToApprove);
    }
    
    function updateMinTokensToApprove(uint256 _newMinTokensToApprove) external onlyOwner {
        require(_newMinTokensToApprove > 0, "Valor debe ser mayor a 0");
        
        uint256 oldValue = MIN_TOKENS_TO_APPROVE;
        MIN_TOKENS_TO_APPROVE = _newMinTokensToApprove;
        
        emit MinTokensToApproveUpdated(oldValue, _newMinTokensToApprove);
    }
}
