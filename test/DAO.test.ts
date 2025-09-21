import { expect } from "chai";
import { network } from "hardhat";

describe("DAO - TypeScript Tests", function () {
  let dao: any;
  let nft: any;
  let deployer: any;
  let user1: any;
  let user2: any;
  let user3: any;
  let user4: any;
  
  const NAME = "Test NFT";
  const SYMBOL = "TNFT";
  const BASE_URI = "https://api.example.com/metadata/";
  const MINT_PRICE = 1000000000000000000n;

  // Parámetros del DAO
  const MIN_PROPOSAL_CREATION_TOKENS = 10;
  const MIN_VOTES_TO_APPROVE = 10;
  const MIN_TOKENS_TO_APPROVE = 50;

  beforeEach(async function () {
    const { ethers } = await network.connect();
    [deployer, user1, user2, user3, user4] = await ethers.getSigners();
    
    // Desplegar contrato NFT primero
    const SimpleNFTFactory = await ethers.getContractFactory("SimpleNFT");
    nft = await SimpleNFTFactory.deploy(NAME, SYMBOL, BASE_URI);
    await nft.waitForDeployment();
    
    // Desplegar contrato DAO
    const DAOFactory = await ethers.getContractFactory("DAO");
    dao = await DAOFactory.deploy(await nft.getAddress());
    await dao.waitForDeployment();

    // Configurar usuarios con NFTs para las pruebas
    await setupTestUsers();
  });

  async function setupTestUsers() {
    // User1: 15 NFTs (puede crear propuestas)
    for (let i = 0; i < 15; i++) {
      await nft.connect(user1).mint({ value: MINT_PRICE });
    }
    
    // User2: 5 NFTs (puede votar pero no crear propuestas)
    for (let i = 0; i < 5; i++) {
      await nft.connect(user2).mint({ value: MINT_PRICE });
    }
    
    // User3: 8 NFTs (puede votar pero no crear propuestas)
    for (let i = 0; i < 8; i++) {
      await nft.connect(user3).mint({ value: MINT_PRICE });
    }
    
    // User4: 20 NFTs (puede crear propuestas)
    for (let i = 0; i < 20; i++) {
      await nft.connect(user4).mint({ value: MINT_PRICE });
    }
  }

  describe("Constructor y Configuración Inicial", function () {
    it("Debería establecer el contrato NFT correctamente", async function () {
      expect(await dao.nftContract()).to.equal(await nft.getAddress());
    });

    it("Debería establecer el owner correctamente", async function () {
      expect(await dao.owner()).to.equal(deployer.address);
    });

    it("Debería tener proposalCount inicial de 0", async function () {
      expect(await dao.proposalCount()).to.equal(0);
    });

    it("Debería tener parámetros iniciales correctos", async function () {
      expect(await dao.MIN_PROPOSAL_CREATION_TOKENS()).to.equal(MIN_PROPOSAL_CREATION_TOKENS);
      expect(await dao.MIN_VOTES_TO_APPROVE()).to.equal(MIN_VOTES_TO_APPROVE);
      expect(await dao.MIN_TOKENS_TO_APPROVE()).to.equal(MIN_TOKENS_TO_APPROVE);
    });
  });

  describe("Creación de Propuestas", function () {
    it("Debería permitir crear propuesta con suficientes NFTs", async function () {
      const username = "testuser";
      const description = "Propuesta de prueba";
      const link = "https://example.com";
      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime + 60; // 1 minuto en el futuro
      const endTime = startTime + 3600; // 1 hora después

      await expect(dao.connect(user1).createProposal(username, description, link, startTime, endTime))
        .to.emit(dao, "ProposalCreated")
        .withArgs(0, user1.address, description, startTime, endTime);

      const proposal = await dao.getProposal(0);
      expect(proposal.id).to.equal(0);
      expect(proposal.proposer).to.equal(user1.address);
      expect(proposal.username).to.equal(username);
      expect(proposal.description).to.equal(description);
      expect(proposal.link).to.equal(link);
      expect(proposal.votesFor).to.equal(0);
      expect(proposal.votesAgainst).to.equal(0);
      expect(proposal.startTime).to.equal(startTime);
      expect(proposal.endTime).to.equal(endTime);
      expect(proposal.cancelled).to.be.false;
    });

    it("Debería incrementar proposalCount después de crear propuesta", async function () {
      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime + 60;
      const endTime = startTime + 3600;

      await dao.connect(user1).createProposal("user", "desc", "link", startTime, endTime);
      expect(await dao.proposalCount()).to.equal(1);

      await dao.connect(user4).createProposal("user2", "desc2", "link2", startTime, endTime);
      expect(await dao.proposalCount()).to.equal(2);
    });

    it("Debería revertir si no tiene suficientes NFTs", async function () {
      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime + 60;
      const endTime = startTime + 3600;

      await expect(
        dao.connect(user2).createProposal("user", "desc", "link", startTime, endTime)
      ).to.be.revertedWith("Necesitas al menos 10 NFTs para crear propuesta");
    });

    it("Debería revertir si startTime es en el pasado", async function () {
      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime - 60;
      const endTime = startTime + 3600;

      await expect(
        dao.connect(user1).createProposal("user", "desc", "link", startTime, endTime)
      ).to.be.revertedWith("startTime debe ser en el futuro");
    });

    it("Debería revertir si endTime no es mayor que startTime", async function () {
      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime + 60;
      const endTime = startTime;

      await expect(
        dao.connect(user1).createProposal("user", "desc", "link", startTime, endTime)
      ).to.be.revertedWith("endTime debe ser mayor que startTime");
    });
  });

  describe("Funciones de Consulta", function () {
    it("Debería retornar el poder de votación correcto", async function () {
      expect(await dao.getVotingPower(user1.address)).to.equal(15);
      expect(await dao.getVotingPower(user2.address)).to.equal(5);
      expect(await dao.getVotingPower(user3.address)).to.equal(8);
      expect(await dao.getVotingPower(user4.address)).to.equal(20);
    });

    it("Debería retornar el total de propuestas correctamente", async function () {
      expect(await dao.getTotalProposals()).to.equal(0);

      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime + 60;
      const endTime = startTime + 3600;
      
      await dao.connect(user1).createProposal("user", "desc", "link", startTime, endTime);
      expect(await dao.getTotalProposals()).to.equal(1);

      await dao.connect(user4).createProposal("user2", "desc2", "link2", startTime, endTime);
      expect(await dao.getTotalProposals()).to.equal(2);
    });

    it("Debería retornar información completa de propuesta", async function () {
      const username = "testuser";
      const description = "Propuesta de prueba";
      const link = "https://example.com";
      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime + 60;
      const endTime = startTime + 3600;

      await dao.connect(user1).createProposal(username, description, link, startTime, endTime);

      const proposal = await dao.getProposal(0);
      expect(proposal.id).to.equal(0);
      expect(proposal.proposer).to.equal(user1.address);
      expect(proposal.username).to.equal(username);
      expect(proposal.description).to.equal(description);
      expect(proposal.link).to.equal(link);
      expect(proposal.votesFor).to.equal(0);
      expect(proposal.votesAgainst).to.equal(0);
      expect(proposal.startTime).to.equal(startTime);
      expect(proposal.endTime).to.equal(endTime);
      expect(proposal.cancelled).to.be.false;
    });
  });

  describe("Estados de Propuestas", function () {
    it("Debería retornar 'No existe' para propuesta inexistente", async function () {
      expect(await dao.getProposalStatus(999)).to.equal("No existe");
    });

    it("Debería retornar 'Pendiente' antes del tiempo de inicio", async function () {
      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime + 3600;
      const endTime = startTime + 3600;
      
      await dao.connect(user1).createProposal("user", "desc", "link", startTime, endTime);

      expect(await dao.getProposalStatus(0)).to.equal("Pendiente");
    });
  });

  describe("Funciones Administrativas", function () {
    it("Debería permitir al owner actualizar contrato NFT", async function () {
      const { ethers } = await network.connect();
      // Crear una dirección diferente usando un contrato mock
      const MockNFTFactory = await ethers.getContractFactory("SimpleNFT");
      const newNft = await MockNFTFactory.deploy("New NFT", "NNFT", "https://new.example.com/");
      await newNft.waitForDeployment();

      const oldAddress = await nft.getAddress();
      const newAddress = await newNft.getAddress();

      // En Hardhat, los contratos pueden tener la misma dirección en diferentes deployments
      // Por eso vamos a usar una dirección arbitraria diferente
      const arbitraryAddress = "0x1234567890123456789012345678901234567890";
      
      // Primero vamos a hacer que el contrato apunte a una dirección diferente
      // y luego la cambiaremos por la nueva
      await dao.connect(deployer).updateNFTContract(arbitraryAddress);
      
      await expect(dao.connect(deployer).updateNFTContract(newAddress))
        .to.emit(dao, "NFTContractUpdated")
        .withArgs(arbitraryAddress, newAddress);

      expect(await dao.nftContract()).to.equal(newAddress);
    });

    it("Debería revertir al actualizar con dirección inválida", async function () {
      const { ethers } = await network.connect();
      await expect(
        dao.connect(deployer).updateNFTContract(ethers.ZeroAddress)
      ).to.be.revertedWith("Direccion invalida");
    });

    it("Debería revertir al actualizar con la misma dirección", async function () {
      await expect(
        dao.connect(deployer).updateNFTContract(await nft.getAddress())
      ).to.be.revertedWith("Misma direccion actual");
    });

    it("Debería permitir al owner actualizar MIN_PROPOSAL_CREATION_TOKENS", async function () {
      const newValue = 15;

      await expect(dao.connect(deployer).updateCreationMinProposalTokens(newValue))
        .to.emit(dao, "MinProposalVotesUpdated")
        .withArgs(MIN_PROPOSAL_CREATION_TOKENS, newValue);

      expect(await dao.MIN_PROPOSAL_CREATION_TOKENS()).to.equal(newValue);
    });

    it("Debería permitir al owner actualizar MIN_VOTES_TO_APPROVE", async function () {
      const newValue = 15;

      await expect(dao.connect(deployer).updateMinVotesToApprove(newValue))
        .to.emit(dao, "MinVotesToApproveUpdated")
        .withArgs(MIN_VOTES_TO_APPROVE, newValue);

      expect(await dao.MIN_VOTES_TO_APPROVE()).to.equal(newValue);
    });

    it("Debería permitir al owner actualizar MIN_TOKENS_TO_APPROVE", async function () {
      const newValue = 100;

      await expect(dao.connect(deployer).updateMinTokensToApprove(newValue))
        .to.emit(dao, "MinTokensToApproveUpdated")
        .withArgs(MIN_TOKENS_TO_APPROVE, newValue);

      expect(await dao.MIN_TOKENS_TO_APPROVE()).to.equal(newValue);
    });

    it("Debería revertir al actualizar parámetros con valor 0", async function () {
      await expect(
        dao.connect(deployer).updateCreationMinProposalTokens(0)
      ).to.be.revertedWith("Valor debe ser mayor a 0");

      await expect(
        dao.connect(deployer).updateMinVotesToApprove(0)
      ).to.be.revertedWith("Valor debe ser mayor a 0");

      await expect(
        dao.connect(deployer).updateMinTokensToApprove(0)
      ).to.be.revertedWith("Valor debe ser mayor a 0");
    });

    it("Debería revertir funciones administrativas si no es owner", async function () {
      await expect(
        dao.connect(user1).updateNFTContract(user2.address)
      ).to.be.revertedWithCustomError(dao, "OwnableUnauthorizedAccount");

      await expect(
        dao.connect(user1).updateCreationMinProposalTokens(15)
      ).to.be.revertedWithCustomError(dao, "OwnableUnauthorizedAccount");

      await expect(
        dao.connect(user1).updateMinVotesToApprove(15)
      ).to.be.revertedWithCustomError(dao, "OwnableUnauthorizedAccount");

      await expect(
        dao.connect(user1).updateMinTokensToApprove(100)
      ).to.be.revertedWithCustomError(dao, "OwnableUnauthorizedAccount");
    });
  });

  describe("Tests de Gas", function () {
    it("Debería reportar uso de gas para crear propuesta", async function () {
      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime + 60;
      const endTime = startTime + 3600;
      
      const tx = await dao.connect(user1).createProposal("user", "desc", "link", startTime, endTime);
      const receipt = await tx.wait();
      
      console.log(`Gas usado para crear propuesta: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });
  });

  describe("Casos Límite y Edge Cases", function () {
    it("Debería manejar propuesta con descripción muy larga", async function () {
      const longDescription = "A".repeat(1000); // 1000 caracteres
      const { ethers } = await network.connect();
      const currentTime = Math.floor(Date.now() / 1000);
      const startTime = currentTime + 60;
      const endTime = startTime + 3600;
      
      await expect(
        dao.connect(user1).createProposal("user", longDescription, "link", startTime, endTime)
      ).to.not.be.revertedWith("Error");
      
      const proposal = await dao.getProposal(0);
      expect(proposal.description).to.equal(longDescription);
    });
  });
});