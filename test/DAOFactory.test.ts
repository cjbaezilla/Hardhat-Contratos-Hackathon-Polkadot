import { expect } from "chai";
import { network } from "hardhat";

describe("DAOFactory", function () {
  let daoFactory: any;
  let nftContract: any;
  let owner: any;
  let user1: any;
  let user2: any;
  let user3: any;
  let ethers: any;

  // Parámetros para crear DAOs
  const minProposalCreationTokens = 10;
  const minVotesToApprove = 5;
  const minTokensToApprove = 50;

  beforeEach(async function () {
    const { ethers: ethersInstance } = await network.connect();
    ethers = ethersInstance;
    [owner, user1, user2, user3] = await ethers.getSigners();

    // Desplegar SimpleNFT para las pruebas
    const SimpleNFT = await ethers.getContractFactory("SimpleNFT");
    nftContract = await SimpleNFT.deploy("Test NFT", "TNFT", "https://api.example.com/metadata/");
    await nftContract.waitForDeployment();

    // Desplegar DAOFactory
    const DAOFactory = await ethers.getContractFactory("DAOFactory");
    daoFactory = await DAOFactory.deploy(owner.address);
    await daoFactory.waitForDeployment();
  });

  describe("Despliegue", function () {
    it("Debería desplegar correctamente con el propietario correcto", async function () {
      expect(await daoFactory.owner()).to.equal(owner.address);
      expect(await daoFactory.getTotalDAOs()).to.equal(0);
    });

    it("Debería emitir evento al transferir ownership del factory", async function () {
      await expect(daoFactory.transferFactoryOwnership(user1.address))
        .to.emit(daoFactory, "DAOFactoryOwnershipTransferred")
        .withArgs(owner.address, user1.address);
    });
  });

  describe("deployDAO", function () {
    it("Debería desplegar un nuevo DAO correctamente", async function () {
      const nftAddress = await nftContract.getAddress();
      
      const tx = await daoFactory.connect(user1).deployDAO(
        "Test DAO",
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove
      );

      await expect(tx)
        .to.emit(daoFactory, "DAOCreated")
        .withArgs(
          await daoFactory.deployedDAOs(0),
          user1.address,
          "Test DAO",
          nftAddress,
          minProposalCreationTokens,
          minVotesToApprove,
          minTokensToApprove
        );

      // Verificar que el DAO fue creado
      const totalDAOs = await daoFactory.getTotalDAOs();
      expect(totalDAOs).to.equal(1);

      const daoAddress = await daoFactory.getDAOByIndex(0);
      expect(daoAddress).to.not.equal(ethers.ZeroAddress);

      // Verificar que user1 es el creador del DAO
      expect(await daoFactory.daoCreator(daoAddress)).to.equal(user1.address);

      // Verificar que es un DAO válido
      expect(await daoFactory.isValidDAO(daoAddress)).to.be.true;
    });

    it("Debería asignar el ownership del DAO al usuario que lo despliega", async function () {
      const nftAddress = await nftContract.getAddress();
      
      await daoFactory.connect(user1).deployDAO(
        "Test DAO",
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove
      );

      const daoAddress = await daoFactory.getDAOByIndex(0);
      const dao = await ethers.getContractAt("DAO", daoAddress);

      // Verificar que user1 es el propietario del DAO, no el factory
      expect(await dao.owner()).to.equal(user1.address);
      expect(await dao.owner()).to.not.equal(await daoFactory.getAddress());
    });

    it("Debería permitir a múltiples usuarios crear sus propios DAOs", async function () {
      const nftAddress = await nftContract.getAddress();

      // User1 crea un DAO
      await daoFactory.connect(user1).deployDAO(
        "Test DAO",
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove
      );

      // User2 crea otro DAO
      await daoFactory.connect(user2).deployDAO(
        "Test DAO 2",
        nftAddress,
        minProposalCreationTokens + 1,
        minVotesToApprove + 1,
        minTokensToApprove + 1
      );

      // User3 crea un tercer DAO
      await daoFactory.connect(user3).deployDAO(
        "Test DAO 3",
        nftAddress,
        minProposalCreationTokens + 2,
        minVotesToApprove + 2,
        minTokensToApprove + 2
      );

      const totalDAOs = await daoFactory.getTotalDAOs();
      expect(totalDAOs).to.equal(3);

      // Verificar que cada usuario es propietario de su DAO
      for (let i = 0; i < 3; i++) {
        const daoAddress = await daoFactory.getDAOByIndex(i);
        const dao = await ethers.getContractAt("DAO", daoAddress);
        const creator = await daoFactory.daoCreator(daoAddress);
        
        expect(await dao.owner()).to.equal(creator);
      }
    });

    it("Debería fallar con parámetros inválidos", async function () {
      const nftAddress = await nftContract.getAddress();

      // Dirección cero para NFT
      await expect(
        daoFactory.connect(user1).deployDAO(
          "Test DAO",
          ethers.ZeroAddress,
          minProposalCreationTokens,
          minVotesToApprove,
          minTokensToApprove
        )
      ).to.be.revertedWith("Direccion del contrato NFT invalida");

      // Mínimo de tokens para propuestas = 0
      await expect(
        daoFactory.connect(user1).deployDAO(
          "Test DAO",
          nftAddress,
          0,
          minVotesToApprove,
          minTokensToApprove
        )
      ).to.be.revertedWith("Minimo de tokens para propuestas debe ser mayor a 0");

      // Mínimo de votos para aprobar = 0
      await expect(
        daoFactory.connect(user1).deployDAO(
          "Test DAO",
          nftAddress,
          minProposalCreationTokens,
          0,
          minTokensToApprove
        )
      ).to.be.revertedWith("Minimo de votos para aprobar debe ser mayor a 0");

      // Mínimo de tokens para aprobar = 0
      await expect(
        daoFactory.connect(user1).deployDAO(
          "Test DAO",
          nftAddress,
          minProposalCreationTokens,
          minVotesToApprove,
          0
        )
      ).to.be.revertedWith("Minimo de tokens para aprobar debe ser mayor a 0");
    });
  });

  describe("Funciones de consulta", function () {
    beforeEach(async function () {
      const nftAddress = await nftContract.getAddress();
      
      // Crear algunos DAOs para las pruebas
      await daoFactory.connect(user1).deployDAO("DAO 1", nftAddress, 10, 5, 50);
      await daoFactory.connect(user2).deployDAO("DAO 2", nftAddress, 15, 7, 75);
      await daoFactory.connect(user3).deployDAO("DAO 3", nftAddress, 20, 10, 100);
    });

    it("Debería retornar el número total de DAOs correctamente", async function () {
      expect(await daoFactory.getTotalDAOs()).to.equal(3);
    });

    it("Debería retornar DAOs por índice correctamente", async function () {
      const dao0 = await daoFactory.getDAOByIndex(0);
      const dao1 = await daoFactory.getDAOByIndex(1);
      const dao2 = await daoFactory.getDAOByIndex(2);

      expect(dao0).to.not.equal(ethers.ZeroAddress);
      expect(dao1).to.not.equal(ethers.ZeroAddress);
      expect(dao2).to.not.equal(ethers.ZeroAddress);
      expect(dao0).to.not.equal(dao1);
      expect(dao1).to.not.equal(dao2);
    });

    it("Debería fallar al obtener DAO con índice fuera de rango", async function () {
      await expect(daoFactory.getDAOByIndex(3))
        .to.be.revertedWith("Indice fuera de rango");
    });

    it("Debería retornar todos los DAOs correctamente", async function () {
      const allDAOs = await daoFactory.getAllDAOs();
      expect(allDAOs).to.have.length(3);
      
      for (let i = 0; i < 3; i++) {
        expect(allDAOs[i]).to.equal(await daoFactory.getDAOByIndex(i));
      }
    });

    it("Debería retornar el creador del DAO correctamente", async function () {
      const dao0 = await daoFactory.getDAOByIndex(0);
      const dao1 = await daoFactory.getDAOByIndex(1);
      const dao2 = await daoFactory.getDAOByIndex(2);

      expect(await daoFactory.getDAOCreator(dao0)).to.equal(user1.address);
      expect(await daoFactory.getDAOCreator(dao1)).to.equal(user2.address);
      expect(await daoFactory.getDAOCreator(dao2)).to.equal(user3.address);
    });

    it("Debería verificar correctamente si una dirección es un DAO válido", async function () {
      const dao0 = await daoFactory.getDAOByIndex(0);
      const randomAddress = user1.address;

      expect(await daoFactory.isDAO(dao0)).to.be.true;
      expect(await daoFactory.isDAO(randomAddress)).to.be.false;
    });

    it("Debería retornar estadísticas del factory correctamente", async function () {
      const [totalDAOs, factoryOwner] = await daoFactory.getFactoryStats();
      
      expect(totalDAOs).to.equal(3);
      expect(factoryOwner).to.equal(owner.address);
    });
  });

  describe("Ownership del Factory", function () {
    it("Debería permitir al propietario transferir ownership", async function () {
      await daoFactory.transferFactoryOwnership(user1.address);
      expect(await daoFactory.owner()).to.equal(user1.address);
    });

    it("Debería fallar si un no-propietario intenta transferir ownership", async function () {
      await expect(
        daoFactory.connect(user1).transferFactoryOwnership(user2.address)
      ).to.be.revertedWithCustomError(daoFactory, "OwnableUnauthorizedAccount");
    });

    it("Debería fallar al transferir ownership a dirección cero", async function () {
      await expect(
        daoFactory.transferFactoryOwnership(ethers.ZeroAddress)
      ).to.be.revertedWith("Nueva direccion de propietario no puede ser cero");
    });

    it("Debería fallar al transferir ownership al propietario actual", async function () {
      await expect(
        daoFactory.transferFactoryOwnership(owner.address)
      ).to.be.revertedWith("La nueva direccion debe ser diferente al propietario actual");
    });
  });

  describe("Integración con DAO", function () {
    it("Debería crear un DAO funcional que pueda ser usado", async function () {
      const nftAddress = await nftContract.getAddress();
      
      // Crear un DAO
      await daoFactory.connect(user1).deployDAO(
        "Test DAO",
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove
      );

      const daoAddress = await daoFactory.getDAOByIndex(0);
      const dao = await ethers.getContractAt("DAO", daoAddress);

      // Verificar que el DAO tiene la configuración correcta
      expect(await dao.nftContract()).to.equal(nftAddress);
      expect(await dao.MIN_PROPOSAL_CREATION_TOKENS()).to.equal(minProposalCreationTokens);
      expect(await dao.MIN_VOTES_TO_APPROVE()).to.equal(minVotesToApprove);
      expect(await dao.MIN_TOKENS_TO_APPROVE()).to.equal(minTokensToApprove);

      // Verificar que user1 puede usar funciones de owner
      const newMinTokens = 25;
      await dao.connect(user1).updateCreationMinProposalTokens(newMinTokens);
      expect(await dao.MIN_PROPOSAL_CREATION_TOKENS()).to.equal(newMinTokens);
    });
  });
});
