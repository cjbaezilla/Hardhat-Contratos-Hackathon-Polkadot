import { expect } from "chai";
import { network } from "hardhat";

describe("DAOMembersFactory", function () {
  let daoMembersFactory: any;
  let userManager: any;
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
  let daoCreationFee: any;
  const minNFTsRequired = 5;

  beforeEach(async function () {
    const { ethers: ethersInstance } = await network.connect();
    ethers = ethersInstance;
    [owner, user1, user2, user3] = await ethers.getSigners();
    
    // Inicializar daoCreationFee después de obtener ethers
    daoCreationFee = ethers.parseEther("0.001");

    // Desplegar SimpleUserManager
    const SimpleUserManager = await ethers.getContractFactory("SimpleUserManager");
    userManager = await SimpleUserManager.deploy();
    await userManager.waitForDeployment();

    // Desplegar SimpleNFT
    const SimpleNFT = await ethers.getContractFactory("SimpleNFT");
    nftContract = await SimpleNFT.deploy("Test NFT", "TNFT", "https://api.example.com/metadata/");
    await nftContract.waitForDeployment();

    // Desplegar DAOMembersFactory
    const DAOMembersFactory = await ethers.getContractFactory("DAOMembersFactory");
    daoMembersFactory = await DAOMembersFactory.deploy(
      await userManager.getAddress(),
      await nftContract.getAddress(),
      owner.address
    );
    await daoMembersFactory.waitForDeployment();

    // Registrar usuarios para las pruebas
    await userManager.connect(user1).registerUser(
      "user1",
      "user1@test.com",
      "https://twitter.com/user1",
      "https://github.com/user1",
      "https://t.me/user1",
      "https://avatar1.com",
      "https://cover1.com"
    );

    await userManager.connect(user2).registerUser(
      "user2",
      "user2@test.com",
      "https://twitter.com/user2",
      "https://github.com/user2",
      "https://t.me/user2",
      "https://avatar2.com",
      "https://cover2.com"
    );

    // Mintear NFTs para user1 (más de 5 para cumplir requisitos)
    for (let i = 0; i < 6; i++) {
      await nftContract.connect(user1).mint({ value: ethers.parseEther("1") });
    }

    // Mintear algunos NFTs para user2 (menos de 5 para pruebas de error)
    for (let i = 0; i < 3; i++) {
      await nftContract.connect(user2).mint({ value: ethers.parseEther("1") });
    }
  });

  describe("Despliegue", function () {
    it("Debería desplegar correctamente con las direcciones correctas", async function () {
      expect(await daoMembersFactory.owner()).to.equal(owner.address);
      expect(await daoMembersFactory.getUserManagerAddress()).to.equal(await userManager.getAddress());
      expect(await daoMembersFactory.getNFTContractAddress()).to.equal(await nftContract.getAddress());
      expect(await daoMembersFactory.getTotalDAOs()).to.equal(0);
      expect(await daoMembersFactory.getMinNFTsRequired()).to.equal(minNFTsRequired);
      expect(await daoMembersFactory.getDAOCreationFee()).to.equal(daoCreationFee);
    });

    it("Debería fallar si se pasa address(0) para userManager", async function () {
      const DAOMembersFactory = await ethers.getContractFactory("DAOMembersFactory");
      await expect(
        DAOMembersFactory.deploy(
          ethers.ZeroAddress,
          await nftContract.getAddress(),
          owner.address
        )
      ).to.be.revertedWith("DAOMembersFactory: UserManager address cannot be zero");
    });

    it("Debería fallar si se pasa address(0) para nftContract", async function () {
      const DAOMembersFactory = await ethers.getContractFactory("DAOMembersFactory");
      await expect(
        DAOMembersFactory.deploy(
          await userManager.getAddress(),
          ethers.ZeroAddress,
          owner.address
        )
      ).to.be.revertedWith("DAOMembersFactory: NFT contract address cannot be zero");
    });
  });

  describe("deployDAO", function () {
    it("Debería desplegar un nuevo DAO correctamente", async function () {
      const nftAddress = await nftContract.getAddress();
      
      const tx = await daoMembersFactory.connect(user1).deployDAO(
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove,
        { value: daoCreationFee }
      );

      const receipt = await tx.wait();
      const daoCreatedEvent = receipt.logs.find(log => {
        try {
          const parsed = daoMembersFactory.interface.parseLog(log);
          return parsed.name === "DAOCreated";
        } catch {
          return false;
        }
      });

      expect(daoCreatedEvent).to.not.be.undefined;
      
      const daoAddress = await daoMembersFactory.getDAOByIndex(0);
      expect(await daoMembersFactory.getTotalDAOs()).to.equal(1);
      expect(await daoMembersFactory.getDAOCreator(daoAddress)).to.equal(user1.address);
      expect(await daoMembersFactory.isDAO(daoAddress)).to.be.true;
    });

    it("Debería fallar si el usuario no está registrado", async function () {
      const nftAddress = await nftContract.getAddress();
      
      await expect(
        daoMembersFactory.connect(user3).deployDAO(
          nftAddress,
          minProposalCreationTokens,
          minVotesToApprove,
          minTokensToApprove,
          { value: daoCreationFee }
        )
      ).to.be.revertedWith("DAOMembersFactory: User must be registered");
    });

    it("Debería fallar si el usuario no tiene suficientes NFTs", async function () {
      const nftAddress = await nftContract.getAddress();
      
      await expect(
        daoMembersFactory.connect(user2).deployDAO(
          nftAddress,
          minProposalCreationTokens,
          minVotesToApprove,
          minTokensToApprove,
          { value: daoCreationFee }
        )
      ).to.be.revertedWith("DAOMembersFactory: User must have at least 5 NFTs");
    });

    it("Debería fallar si no se paga la tarifa suficiente", async function () {
      const nftAddress = await nftContract.getAddress();
      
      await expect(
        daoMembersFactory.connect(user1).deployDAO(
          nftAddress,
          minProposalCreationTokens,
          minVotesToApprove,
          minTokensToApprove,
          { value: ethers.parseEther("0.0005") } // Menos de la tarifa requerida
        )
      ).to.be.revertedWith("DAOMembersFactory: Insufficient fee paid");
    });

    it("Debería fallar si se pasa address(0) para nftContract", async function () {
      await expect(
        daoMembersFactory.connect(user1).deployDAO(
          ethers.ZeroAddress,
          minProposalCreationTokens,
          minVotesToApprove,
          minTokensToApprove,
          { value: daoCreationFee }
        )
      ).to.be.revertedWith("DAOMembersFactory: Direccion del contrato NFT invalida");
    });

    it("Debería fallar si minProposalCreationTokens es 0", async function () {
      const nftAddress = await nftContract.getAddress();
      
      await expect(
        daoMembersFactory.connect(user1).deployDAO(
          nftAddress,
          0, // Valor inválido
          minVotesToApprove,
          minTokensToApprove,
          { value: daoCreationFee }
        )
      ).to.be.revertedWith("DAOMembersFactory: Minimo de tokens para propuestas debe ser mayor a 0");
    });

    it("Debería fallar si minVotesToApprove es 0", async function () {
      const nftAddress = await nftContract.getAddress();
      
      await expect(
        daoMembersFactory.connect(user1).deployDAO(
          nftAddress,
          minProposalCreationTokens,
          0, // Valor inválido
          minTokensToApprove,
          { value: daoCreationFee }
        )
      ).to.be.revertedWith("DAOMembersFactory: Minimo de votos para aprobar debe ser mayor a 0");
    });

    it("Debería fallar si minTokensToApprove es 0", async function () {
      const nftAddress = await nftContract.getAddress();
      
      await expect(
        daoMembersFactory.connect(user1).deployDAO(
          nftAddress,
          minProposalCreationTokens,
          minVotesToApprove,
          0, // Valor inválido
          { value: daoCreationFee }
        )
      ).to.be.revertedWith("DAOMembersFactory: Minimo de tokens para aprobar debe ser mayor a 0");
    });

    it("Debería transferir la tarifa al propietario del factory", async function () {
      const nftAddress = await nftContract.getAddress();
      const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);
      
      await daoMembersFactory.connect(user1).deployDAO(
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove,
        { value: daoCreationFee }
      );

      const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);
      expect(ownerBalanceAfter).to.be.greaterThan(ownerBalanceBefore);
    });

    it("Debería transferir la propiedad del DAO al creador", async function () {
      const nftAddress = await nftContract.getAddress();
      
      await daoMembersFactory.connect(user1).deployDAO(
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove,
        { value: daoCreationFee }
      );

      const daoAddress = await daoMembersFactory.getDAOByIndex(0);
      const DAO = await ethers.getContractFactory("DAO");
      const daoContract = DAO.attach(daoAddress);
      
      expect(await daoContract.owner()).to.equal(user1.address);
    });
  });

  describe("Funciones de consulta", function () {
    beforeEach(async function () {
      // Crear algunos DAOs para las pruebas
      const nftAddress = await nftContract.getAddress();
      
      await daoMembersFactory.connect(user1).deployDAO(
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove,
        { value: daoCreationFee }
      );
    });

    it("Debería retornar el número total de DAOs correctamente", async function () {
      expect(await daoMembersFactory.getTotalDAOs()).to.equal(1);
    });

    it("Debería retornar la dirección del DAO por índice", async function () {
      const daoAddress = await daoMembersFactory.getDAOByIndex(0);
      expect(daoAddress).to.not.equal(ethers.ZeroAddress);
    });

    it("Debería fallar al obtener DAO con índice fuera de rango", async function () {
      await expect(daoMembersFactory.getDAOByIndex(1))
        .to.be.revertedWith("Indice fuera de rango");
    });

    it("Debería retornar todos los DAOs", async function () {
      const allDAOs = await daoMembersFactory.getAllDAOs();
      expect(allDAOs.length).to.equal(1);
      expect(allDAOs[0]).to.not.equal(ethers.ZeroAddress);
    });

    it("Debería retornar el creador del DAO", async function () {
      const daoAddress = await daoMembersFactory.getDAOByIndex(0);
      expect(await daoMembersFactory.getDAOCreator(daoAddress)).to.equal(user1.address);
    });

    it("Debería fallar al obtener creador de DAO inválido", async function () {
      await expect(daoMembersFactory.getDAOCreator(user2.address))
        .to.be.revertedWith("DAO no valido o no creado por esta factory");
    });

    it("Debería verificar si una dirección es un DAO válido", async function () {
      const daoAddress = await daoMembersFactory.getDAOByIndex(0);
      expect(await daoMembersFactory.isDAO(daoAddress)).to.be.true;
      expect(await daoMembersFactory.isDAO(user2.address)).to.be.false;
    });

    it("Debería retornar las estadísticas del factory", async function () {
      const [totalDAOs, factoryOwner] = await daoMembersFactory.getFactoryStats();
      expect(totalDAOs).to.equal(1);
      expect(factoryOwner).to.equal(owner.address);
    });

    it("Debería verificar los requisitos del usuario", async function () {
      const [isRegistered, nftBalance, canCreateDAO] = await daoMembersFactory.checkUserRequirements(user1.address);
      expect(isRegistered).to.be.true;
      expect(nftBalance).to.equal(6);
      expect(canCreateDAO).to.be.true;

      const [isRegistered2, nftBalance2, canCreateDAO2] = await daoMembersFactory.checkUserRequirements(user2.address);
      expect(isRegistered2).to.be.true;
      expect(nftBalance2).to.equal(3);
      expect(canCreateDAO2).to.be.false;

      const [isRegistered3, nftBalance3, canCreateDAO3] = await daoMembersFactory.checkUserRequirements(user3.address);
      expect(isRegistered3).to.be.false;
      expect(nftBalance3).to.equal(0);
      expect(canCreateDAO3).to.be.false;
    });
  });

  describe("Funciones de administración (solo owner)", function () {
    it("Debería transferir la propiedad del factory", async function () {
      await expect(daoMembersFactory.transferFactoryOwnership(user1.address))
        .to.emit(daoMembersFactory, "DAOFactoryOwnershipTransferred")
        .withArgs(owner.address, user1.address);

      expect(await daoMembersFactory.owner()).to.equal(user1.address);
    });

    it("Debería fallar al transferir propiedad a address(0)", async function () {
      await expect(daoMembersFactory.transferFactoryOwnership(ethers.ZeroAddress))
        .to.be.revertedWith("Nueva direccion de propietario no puede ser cero");
    });

    it("Debería fallar al transferir propiedad al propietario actual", async function () {
      await expect(daoMembersFactory.transferFactoryOwnership(owner.address))
        .to.be.revertedWith("La nueva direccion debe ser diferente al propietario actual");
    });

    it("Debería fallar si un usuario no propietario intenta transferir propiedad", async function () {
      await expect(daoMembersFactory.connect(user1).transferFactoryOwnership(user2.address))
        .to.be.revertedWithCustomError(daoMembersFactory, "OwnableUnauthorizedAccount")
        .withArgs(user1.address);
    });

    it("Debería actualizar la tarifa de creación de DAO", async function () {
      const newFee = ethers.parseEther("0.002");
      
      await expect(daoMembersFactory.setDAOCreationFee(newFee))
        .to.emit(daoMembersFactory, "FeeUpdated")
        .withArgs(daoCreationFee, newFee);

      expect(await daoMembersFactory.getDAOCreationFee()).to.equal(newFee);
    });

    it("Debería fallar al establecer la misma tarifa", async function () {
      await expect(daoMembersFactory.setDAOCreationFee(daoCreationFee))
        .to.be.revertedWith("DAOMembersFactory: Fee is already set to this value");
    });

    it("Debería fallar si un usuario no propietario intenta cambiar la tarifa", async function () {
      await expect(daoMembersFactory.connect(user1).setDAOCreationFee(ethers.parseEther("0.002")))
        .to.be.revertedWithCustomError(daoMembersFactory, "OwnableUnauthorizedAccount")
        .withArgs(user1.address);
    });

    it("Debería actualizar el mínimo de NFTs requeridos", async function () {
      const newMinNFTs = 10;
      
      await expect(daoMembersFactory.setMinNFTsRequired(newMinNFTs))
        .to.emit(daoMembersFactory, "MinNFTsRequiredUpdated")
        .withArgs(minNFTsRequired, newMinNFTs);

      expect(await daoMembersFactory.getMinNFTsRequired()).to.equal(newMinNFTs);
    });

    it("Debería fallar al establecer el mismo mínimo de NFTs", async function () {
      await expect(daoMembersFactory.setMinNFTsRequired(minNFTsRequired))
        .to.be.revertedWith("DAOMembersFactory: Min NFTs is already set to this value");
    });

    it("Debería fallar al establecer mínimo de NFTs en 0", async function () {
      await expect(daoMembersFactory.setMinNFTsRequired(0))
        .to.be.revertedWith("DAOMembersFactory: Min NFTs must be greater than 0");
    });

    it("Debería fallar si un usuario no propietario intenta cambiar el mínimo de NFTs", async function () {
      await expect(daoMembersFactory.connect(user1).setMinNFTsRequired(10))
        .to.be.revertedWithCustomError(daoMembersFactory, "OwnableUnauthorizedAccount")
        .withArgs(user1.address);
    });
  });

  describe("Casos edge y validaciones adicionales", function () {
    it("Debería permitir crear múltiples DAOs", async function () {
      const nftAddress = await nftContract.getAddress();
      
      // Crear primer DAO
      await daoMembersFactory.connect(user1).deployDAO(
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove,
        { value: daoCreationFee }
      );

      // Mintear más NFTs para user2 para que pueda crear un DAO
      for (let i = 0; i < 3; i++) {
        await nftContract.connect(user2).mint({ value: ethers.parseEther("1") });
      }

      // Crear segundo DAO
      await daoMembersFactory.connect(user2).deployDAO(
        nftAddress,
        minProposalCreationTokens + 5,
        minVotesToApprove + 2,
        minTokensToApprove + 10,
        { value: daoCreationFee }
      );

      expect(await daoMembersFactory.getTotalDAOs()).to.equal(2);
      expect(await daoMembersFactory.getDAOCreator(await daoMembersFactory.getDAOByIndex(0))).to.equal(user1.address);
      expect(await daoMembersFactory.getDAOCreator(await daoMembersFactory.getDAOByIndex(1))).to.equal(user2.address);
    });

    it("Debería funcionar correctamente después de cambiar los requisitos", async function () {
      const nftAddress = await nftContract.getAddress();
      
      // Cambiar el mínimo de NFTs requeridos a 3
      await daoMembersFactory.setMinNFTsRequired(3);
      
      // Ahora user2 debería poder crear un DAO
      await daoMembersFactory.connect(user2).deployDAO(
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove,
        { value: daoCreationFee }
      );

      expect(await daoMembersFactory.getTotalDAOs()).to.equal(1);
    });

    it("Debería funcionar correctamente después de cambiar la tarifa", async function () {
      const nftAddress = await nftContract.getAddress();
      const newFee = ethers.parseEther("0.002");
      
      // Cambiar la tarifa
      await daoMembersFactory.setDAOCreationFee(newFee);
      
      // Crear DAO con la nueva tarifa
      await daoMembersFactory.connect(user1).deployDAO(
        nftAddress,
        minProposalCreationTokens,
        minVotesToApprove,
        minTokensToApprove,
        { value: newFee }
      );

      expect(await daoMembersFactory.getTotalDAOs()).to.equal(1);
    });
  });
});
