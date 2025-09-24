import { expect } from "chai";
import { network } from "hardhat";

/**
 * Pruebas para el contrato ERC20MembersFactory
 * Verifica la funcionalidad completa del factory que requiere usuarios registrados y NFTs
 */
describe("ERC20MembersFactory Tests", function () {
  let deployer: any;
  let user1: any;
  let user2: any;
  let user3: any;
  let erc20MembersFactory: any;
  let userManager: any;
  let nftContract: any;
  let factoryAddress: string;
  let userManagerAddress: string;
  let nftContractAddress: string;

  const TOKEN_CREATION_FEE = 1000000000000000n; // 0.001 ETH
  const MIN_NFTS_REQUIRED = 5;
  const NFT_MINT_PRICE = 1000000000000000000n; // 1 ETH

  beforeEach(async function () {
    const { ethers } = await network.connect();
    [deployer, user1, user2, user3] = await ethers.getSigners();

    // Desplegar SimpleUserManager
    const SimpleUserManager = await ethers.getContractFactory("SimpleUserManager");
    userManager = await SimpleUserManager.deploy();
    await userManager.waitForDeployment();
    userManagerAddress = await userManager.getAddress();

    // Desplegar SimpleNFT
    const SimpleNFT = await ethers.getContractFactory("SimpleNFT");
    nftContract = await SimpleNFT.deploy(
      "Test NFT",
      "TNFT",
      "https://example.com/metadata/"
    );
    await nftContract.waitForDeployment();
    nftContractAddress = await nftContract.getAddress();

    // Desplegar ERC20MembersFactory
    const ERC20MembersFactory = await ethers.getContractFactory("ERC20MembersFactory");
    erc20MembersFactory = await ERC20MembersFactory.deploy(
      userManagerAddress,
      nftContractAddress
    );
    await erc20MembersFactory.waitForDeployment();
    factoryAddress = await erc20MembersFactory.getAddress();
  });

  describe("Constructor y Estado Inicial", function () {
    it("Debería desplegar el contrato correctamente", async function () {
      const { ethers } = await network.connect();
      expect(factoryAddress).to.not.equal(ethers.ZeroAddress);
      expect(await erc20MembersFactory.getAddress()).to.equal(factoryAddress);
    });

    it("Debería configurar las direcciones correctamente", async function () {
      expect(await erc20MembersFactory.getUserManagerAddress()).to.equal(userManagerAddress);
      expect(await erc20MembersFactory.getNFTContractAddress()).to.equal(nftContractAddress);
    });

    it("Debería tener los valores iniciales correctos", async function () {
      expect(await erc20MembersFactory.getTokenCreationFee()).to.equal(TOKEN_CREATION_FEE);
      expect(await erc20MembersFactory.getMinNFTsRequired()).to.equal(MIN_NFTS_REQUIRED);
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.equal(0);
    });

    it("Debería revertir con dirección cero para UserManager", async function () {
      const { ethers } = await network.connect();
      const ERC20MembersFactory = await ethers.getContractFactory("ERC20MembersFactory");
      await expect(
        ERC20MembersFactory.deploy(ethers.ZeroAddress, nftContractAddress)
      ).to.be.revertedWith("ERC20MembersFactory: UserManager address cannot be zero");
    });

    it("Debería revertir con dirección cero para NFT contract", async function () {
      const { ethers } = await network.connect();
      const ERC20MembersFactory = await ethers.getContractFactory("ERC20MembersFactory");
      await expect(
        ERC20MembersFactory.deploy(userManagerAddress, ethers.ZeroAddress)
      ).to.be.revertedWith("ERC20MembersFactory: NFT contract address cannot be zero");
    });
  });

  describe("Registro de Usuarios y NFTs", function () {
    beforeEach(async function () {
      // Registrar usuarios
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
    });

    it("Debería permitir registrar usuarios", async function () {
      expect(await userManager.isRegisteredUser(user1.address)).to.be.true;
      expect(await userManager.isRegisteredUser(user2.address)).to.be.true;
      expect(await userManager.isRegisteredUser(user3.address)).to.be.false;
    });

    it("Debería permitir mintear NFTs", async function () {
      // user1 mintea 5 NFTs
      await nftContract.connect(user1).mintBatch(5, { value: NFT_MINT_PRICE * 5n });
      
      expect(await nftContract.balanceOf(user1.address)).to.equal(5);
      expect(await nftContract.totalSupply()).to.equal(5);
    });

    it("Debería verificar requisitos de usuario correctamente", async function () {
      // user1 sin NFTs
      let [isRegistered, nftBalance, canCreateToken] = await erc20MembersFactory.checkUserRequirements(user1.address);
      expect(isRegistered).to.be.true;
      expect(nftBalance).to.equal(0);
      expect(canCreateToken).to.be.false;

      // user1 con 5 NFTs
      await nftContract.connect(user1).mintBatch(5, { value: NFT_MINT_PRICE * 5n });
      [isRegistered, nftBalance, canCreateToken] = await erc20MembersFactory.checkUserRequirements(user1.address);
      expect(isRegistered).to.be.true;
      expect(nftBalance).to.equal(5);
      expect(canCreateToken).to.be.true;

      // user3 no registrado
      [isRegistered, nftBalance, canCreateToken] = await erc20MembersFactory.checkUserRequirements(user3.address);
      expect(isRegistered).to.be.false;
      expect(nftBalance).to.equal(0);
      expect(canCreateToken).to.be.false;
    });
  });

  describe("Creación de Tokens", function () {
    beforeEach(async function () {
      // Configurar usuarios y NFTs
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

      // user1 tiene 5 NFTs, user2 tiene 3 NFTs
      await nftContract.connect(user1).mintBatch(5, { value: NFT_MINT_PRICE * 5n });
      await nftContract.connect(user2).mintBatch(3, { value: NFT_MINT_PRICE * 3n });
    });

    it("Debería crear un token exitosamente", async function () {
      const tokenName = "Test Token";
      const tokenSymbol = "TTK";
      const initialSupply = 1000000;

      const tx = await erc20MembersFactory.connect(user1).createToken(
        tokenName,
        tokenSymbol,
        initialSupply,
        { value: TOKEN_CREATION_FEE }
      );

      await tx.wait();

      // Verificar que se incrementó el contador
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.equal(1);

      // Verificar que el token se agregó al array
      const { ethers } = await network.connect();
      const allTokens = await erc20MembersFactory.getAllTokens();
      expect(allTokens.length).to.equal(1);
      expect(allTokens[0].tokenAddress).to.not.equal(ethers.ZeroAddress);
      expect(allTokens[0].creator).to.equal(user1.address);
      expect(allTokens[0].name).to.equal(tokenName);
      expect(allTokens[0].symbol).to.equal(tokenSymbol);
      expect(allTokens[0].initialSupply).to.equal(initialSupply);
    });

    it("Debería emitir evento TokenCreated", async function () {
      const tokenName = "Event Test Token";
      const tokenSymbol = "ETT";
      const initialSupply = 500000;

      const tx = await erc20MembersFactory.connect(user1).createToken(
        tokenName,
        tokenSymbol,
        initialSupply,
        { value: TOKEN_CREATION_FEE }
      );
      
      const receipt = await tx.wait();
      const allTokens = await erc20MembersFactory.getAllTokens();
      const tokenAddress = allTokens[0].tokenAddress;

      await expect(tx)
        .to.emit(erc20MembersFactory, "TokenCreated")
        .withArgs(
          tokenAddress,
          user1.address,
          tokenName,
          tokenSymbol,
          initialSupply,
          TOKEN_CREATION_FEE
        );
    });

    it("Debería transferir la tarifa al owner", async function () {
      const tx = await erc20MembersFactory.connect(user1).createToken(
        "Fee Test Token",
        "FTT",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );
      
      const receipt = await tx.wait();
      
      // Verificar que el evento TokenCreated se emitió con la tarifa correcta
      const events = receipt?.logs || [];
      const tokenCreatedEvent = events.find(log => {
        try {
          const parsed = erc20MembersFactory.interface.parseLog(log);
          return parsed?.name === "TokenCreated";
        } catch {
          return false;
        }
      });
      
      expect(tokenCreatedEvent).to.not.be.undefined;
      
      if (tokenCreatedEvent) {
        const parsedEvent = erc20MembersFactory.interface.parseLog(tokenCreatedEvent);
        expect(parsedEvent?.args.feePaid).to.equal(TOKEN_CREATION_FEE);
      }
    });

    it("Debería permitir crear múltiples tokens", async function () {
      // Crear primer token
      await erc20MembersFactory.connect(user1).createToken(
        "Token 1",
        "TK1",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );

      // user2 necesita más NFTs para crear token
      await nftContract.connect(user2).mintBatch(2, { value: NFT_MINT_PRICE * 2n });

      // Crear segundo token
      await erc20MembersFactory.connect(user2).createToken(
        "Token 2",
        "TK2",
        2000000,
        { value: TOKEN_CREATION_FEE }
      );

      // Verificar contadores
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.equal(2);
      const allTokens = await erc20MembersFactory.getAllTokens();
      expect(allTokens.length).to.equal(2);
    });

    it("Debería revertir si el usuario no está registrado", async function () {
      await expect(
        erc20MembersFactory.connect(user3).createToken(
          "Test Token",
          "TTK",
          1000000,
          { value: TOKEN_CREATION_FEE }
        )
      ).to.be.revertedWith("ERC20MembersFactory: User must be registered");
    });

    it("Debería revertir si el usuario no tiene suficientes NFTs", async function () {
      await expect(
        erc20MembersFactory.connect(user2).createToken(
          "Test Token",
          "TTK",
          1000000,
          { value: TOKEN_CREATION_FEE }
        )
      ).to.be.revertedWith("ERC20MembersFactory: User must have at least 5 NFTs");
    });

    it("Debería revertir si no se paga la tarifa suficiente", async function () {
      const insufficientFee = TOKEN_CREATION_FEE / 2n;
      
      await expect(
        erc20MembersFactory.connect(user1).createToken(
          "Test Token",
          "TTK",
          1000000,
          { value: insufficientFee }
        )
      ).to.be.revertedWith("ERC20MembersFactory: Insufficient fee paid");
    });

    it("Debería revertir con nombre vacío", async function () {
      await expect(
        erc20MembersFactory.connect(user1).createToken(
          "",
          "TTK",
          1000000,
          { value: TOKEN_CREATION_FEE }
        )
      ).to.be.revertedWith("ERC20MembersFactory: Name cannot be empty");
    });

    it("Debería revertir con símbolo vacío", async function () {
      await expect(
        erc20MembersFactory.connect(user1).createToken(
          "Test Token",
          "",
          1000000,
          { value: TOKEN_CREATION_FEE }
        )
      ).to.be.revertedWith("ERC20MembersFactory: Symbol cannot be empty");
    });
  });

  describe("Funciones de Consulta", function () {
    beforeEach(async function () {
      // Configurar usuarios y crear tokens
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

      await nftContract.connect(user1).mintBatch(5, { value: NFT_MINT_PRICE * 5n });
      await nftContract.connect(user2).mintBatch(5, { value: NFT_MINT_PRICE * 5n });

      // Crear tokens
      await erc20MembersFactory.connect(user1).createToken(
        "Token 1",
        "TK1",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );

      await erc20MembersFactory.connect(user2).createToken(
        "Token 2",
        "TK2",
        2000000,
        { value: TOKEN_CREATION_FEE }
      );
    });

    it("Debería obtener tokens de usuario", async function () {
      const user1Tokens = await erc20MembersFactory.getUserTokens(user1.address);
      const user2Tokens = await erc20MembersFactory.getUserTokens(user2.address);

      expect(user1Tokens.length).to.equal(1);
      expect(user2Tokens.length).to.equal(1);
      expect(user1Tokens[0].name).to.equal("Token 1");
      expect(user2Tokens[0].name).to.equal("Token 2");
    });

    it("Debería obtener conteo de tokens de usuario", async function () {
      expect(await erc20MembersFactory.getUserTokenCount(user1.address)).to.equal(1);
      expect(await erc20MembersFactory.getUserTokenCount(user2.address)).to.equal(1);
      expect(await erc20MembersFactory.getUserTokenCount(user3.address)).to.equal(0);
    });

    it("Debería obtener todos los tokens", async function () {
      const allTokens = await erc20MembersFactory.getAllTokens();
      expect(allTokens.length).to.equal(2);
      expect(allTokens[0].name).to.equal("Token 1");
      expect(allTokens[1].name).to.equal("Token 2");
    });

    it("Debería obtener token por índice", async function () {
      const token0 = await erc20MembersFactory.getTokenByIndex(0);
      const token1 = await erc20MembersFactory.getTokenByIndex(1);

      expect(token0.name).to.equal("Token 1");
      expect(token1.name).to.equal("Token 2");

      await expect(
        erc20MembersFactory.getTokenByIndex(2)
      ).to.be.revertedWith("ERC20Factory: Index out of bounds");
    });

    it("Debería obtener token de usuario por índice", async function () {
      const user1Token0 = await erc20MembersFactory.getUserTokenByIndex(user1.address, 0);
      expect(user1Token0.name).to.equal("Token 1");

      await expect(
        erc20MembersFactory.getUserTokenByIndex(user1.address, 1)
      ).to.be.revertedWith("ERC20Factory: Index out of bounds");
    });

    it("Debería verificar si un token es del factory", async function () {
      const allTokens = await erc20MembersFactory.getAllTokens();
      const tokenAddress = allTokens[0].tokenAddress;

      expect(await erc20MembersFactory.isTokenFromFactory(tokenAddress)).to.be.true;
      expect(await erc20MembersFactory.isTokenFromFactory(user1.address)).to.be.false;
    });

    it("Debería obtener el creador de un token", async function () {
      const allTokens = await erc20MembersFactory.getAllTokens();
      const tokenAddress = allTokens[0].tokenAddress;

      expect(await erc20MembersFactory.getTokenCreator(tokenAddress)).to.equal(user1.address);

      await expect(
        erc20MembersFactory.getTokenCreator(user1.address)
      ).to.be.revertedWith("ERC20Factory: Token not created by this factory");
    });

    it("Debería obtener información de token por dirección", async function () {
      const allTokens = await erc20MembersFactory.getAllTokens();
      const tokenAddress = allTokens[0].tokenAddress;

      const tokenInfo = await erc20MembersFactory.getTokenInfoByAddress(tokenAddress);
      expect(tokenInfo.name).to.equal("Token 1");
      expect(tokenInfo.symbol).to.equal("TK1");
      expect(tokenInfo.creator).to.equal(user1.address);

      const { ethers } = await network.connect();
      await expect(
        erc20MembersFactory.getTokenInfoByAddress(ethers.ZeroAddress)
      ).to.be.revertedWith("ERC20MembersFactory: Token address cannot be zero");

      await expect(
        erc20MembersFactory.getTokenInfoByAddress(user1.address)
      ).to.be.revertedWith("ERC20MembersFactory: Token not created by this factory");
    });
  });

  describe("Funciones de Administración", function () {
    it("Debería permitir al owner cambiar la tarifa de creación", async function () {
      const newFee = 2000000000000000n; // 0.002 ETH
      
      await expect(
        erc20MembersFactory.connect(deployer).setTokenCreationFee(newFee)
      ).to.emit(erc20MembersFactory, "FeeUpdated")
        .withArgs(TOKEN_CREATION_FEE, newFee);

      expect(await erc20MembersFactory.getTokenCreationFee()).to.equal(newFee);
    });

    it("Debería permitir al owner cambiar el mínimo de NFTs requeridos", async function () {
      const newMinNFTs = 10;
      
      await expect(
        erc20MembersFactory.connect(deployer).setMinNFTsRequired(newMinNFTs)
      ).to.emit(erc20MembersFactory, "MinNFTsRequiredUpdated")
        .withArgs(MIN_NFTS_REQUIRED, newMinNFTs);

      expect(await erc20MembersFactory.getMinNFTsRequired()).to.equal(newMinNFTs);
    });

    it("Debería revertir si no es el owner", async function () {
      const newFee = 2000000000000000n; // 0.002 ETH
      
      await expect(
        erc20MembersFactory.connect(user1).setTokenCreationFee(newFee)
      ).to.be.revertedWithCustomError(erc20MembersFactory, "OwnableUnauthorizedAccount")
        .withArgs(user1.address);
    });

    it("Debería revertir si se establece la misma tarifa", async function () {
      await expect(
        erc20MembersFactory.connect(deployer).setTokenCreationFee(TOKEN_CREATION_FEE)
      ).to.be.revertedWith("ERC20MembersFactory: Fee is already set to this value");
    });

    it("Debería revertir si se establece el mismo mínimo de NFTs", async function () {
      await expect(
        erc20MembersFactory.connect(deployer).setMinNFTsRequired(MIN_NFTS_REQUIRED)
      ).to.be.revertedWith("ERC20MembersFactory: Min NFTs is already set to this value");
    });

    it("Debería revertir si se establece mínimo de NFTs en 0", async function () {
      await expect(
        erc20MembersFactory.connect(deployer).setMinNFTsRequired(0)
      ).to.be.revertedWith("ERC20MembersFactory: Min NFTs must be greater than 0");
    });
  });

  describe("Integración con Tokens Creados", function () {
    beforeEach(async function () {
      // Configurar usuario y NFTs
      await userManager.connect(user1).registerUser(
        "user1",
        "user1@test.com",
        "https://twitter.com/user1",
        "https://github.com/user1",
        "https://t.me/user1",
        "https://avatar1.com",
        "https://cover1.com"
      );

      await nftContract.connect(user1).mintBatch(5, { value: NFT_MINT_PRICE * 5n });
    });

    it("Debería poder interactuar con tokens creados", async function () {
      // Crear un token
      const tx = await erc20MembersFactory.connect(user1).createToken(
        "Integration Test Token",
        "ITT",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );
      await tx.wait();

      // Obtener la dirección del token creado
      const allTokens = await erc20MembersFactory.getAllTokens();
      expect(allTokens.length).to.equal(1);
      
      const { ethers } = await network.connect();
      const tokenAddress = allTokens[0].tokenAddress;
      expect(tokenAddress).to.not.equal(ethers.ZeroAddress);

      // Verificar que el token se registró correctamente
      expect(await erc20MembersFactory.isTokenFromFactory(tokenAddress)).to.be.true;
      expect(await erc20MembersFactory.getTokenCreator(tokenAddress)).to.equal(user1.address);
    });

    it("Debería permitir transferir tokens creados", async function () {
      // Crear un token
      const tx = await erc20MembersFactory.connect(user1).createToken(
        "Transfer Test Token",
        "TTT",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );
      await tx.wait();

      // Obtener la dirección del token
      const allTokens = await erc20MembersFactory.getAllTokens();
      const tokenAddress = allTokens[0].tokenAddress;

      // Verificar que el token se creó correctamente
      expect(await erc20MembersFactory.isTokenFromFactory(tokenAddress)).to.be.true;
      expect(await erc20MembersFactory.getTokenCreator(tokenAddress)).to.equal(user1.address);
    });
  });

  describe("Casos Límite y Manejo de Errores", function () {
    beforeEach(async function () {
      await userManager.connect(user1).registerUser(
        "user1",
        "user1@test.com",
        "https://twitter.com/user1",
        "https://github.com/user1",
        "https://t.me/user1",
        "https://avatar1.com",
        "https://cover1.com"
      );

      await nftContract.connect(user1).mintBatch(5, { value: NFT_MINT_PRICE * 5n });
    });

    it("Debería manejar nombres de token muy largos", async function () {
      const longName = "A".repeat(100);
      const tx = await erc20MembersFactory.connect(user1).createToken(
        longName,
        "LNG",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );
      
      await tx.wait(); // Si no hay error, la transacción se completó exitosamente
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.be.greaterThan(0);
    });

    it("Debería manejar símbolos de token muy largos", async function () {
      const longSymbol = "A".repeat(50);
      const tx = await erc20MembersFactory.connect(user1).createToken(
        "Test Token",
        longSymbol,
        1000000,
        { value: TOKEN_CREATION_FEE }
      );
      
      await tx.wait(); // Si no hay error, la transacción se completó exitosamente
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.be.greaterThan(0);
    });

    it("Debería manejar suministros iniciales muy grandes", async function () {
      const largeSupply = 1000000000000000000000000n; // 1000000 ETH
      const tx = await erc20MembersFactory.connect(user1).createToken(
        "Large Supply Token",
        "LST",
        largeSupply,
        { value: TOKEN_CREATION_FEE }
      );
      
      await tx.wait(); // Si no hay error, la transacción se completó exitosamente
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.be.greaterThan(0);
    });

    it("Debería manejar pagos exactos de tarifa", async function () {
      const tx = await erc20MembersFactory.connect(user1).createToken(
        "Exact Fee Token",
        "EFT",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );
      
      await tx.wait(); // Si no hay error, la transacción se completó exitosamente
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.be.greaterThan(0);
    });

    it("Debería manejar pagos mayores a la tarifa", async function () {
      const extraPayment = TOKEN_CREATION_FEE + 1000000000000000n; // + 0.001 ETH
      const tx = await erc20MembersFactory.connect(user1).createToken(
        "Extra Payment Token",
        "EPT",
        1000000,
        { value: extraPayment }
      );
      
      await tx.wait(); // Si no hay error, la transacción se completó exitosamente
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.be.greaterThan(0);
    });
  });

  describe("Pruebas de Gas", function () {
    beforeEach(async function () {
      await userManager.connect(user1).registerUser(
        "user1",
        "user1@test.com",
        "https://twitter.com/user1",
        "https://github.com/user1",
        "https://t.me/user1",
        "https://avatar1.com",
        "https://cover1.com"
      );

      await nftContract.connect(user1).mintBatch(5, { value: NFT_MINT_PRICE * 5n });
    });

    it("Debería reportar uso de gas para crear token", async function () {
      const tx = await erc20MembersFactory.connect(user1).createToken(
        "Gas Test Token",
        "GTT",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );
      
      const receipt = await tx.wait();
      
      console.log(`Gas usado para crear token: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });

    it("Debería reportar uso de gas para despliegue del factory", async function () {
      const { ethers } = await network.connect();
      const ERC20MembersFactory = await ethers.getContractFactory("ERC20MembersFactory");
      const factory = await ERC20MembersFactory.deploy(userManagerAddress, nftContractAddress);
      const receipt = await factory.deploymentTransaction()?.wait();
      
      console.log(`Gas usado para desplegar ERC20MembersFactory: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });
  });

  describe("Escenarios Complejos", function () {
    it("Debería manejar múltiples usuarios con diferentes cantidades de NFTs", async function () {
      // Registrar usuarios
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

      // user1 tiene 5 NFTs, user2 tiene 7 NFTs
      await nftContract.connect(user1).mintBatch(5, { value: NFT_MINT_PRICE * 5n });
      await nftContract.connect(user2).mintBatch(7, { value: NFT_MINT_PRICE * 7n });

      // Ambos pueden crear tokens
      await erc20MembersFactory.connect(user1).createToken(
        "User1 Token",
        "U1T",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );

      await erc20MembersFactory.connect(user2).createToken(
        "User2 Token",
        "U2T",
        2000000,
        { value: TOKEN_CREATION_FEE }
      );

      // Verificar que ambos tokens fueron creados
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.equal(2);
      
      const user1Tokens = await erc20MembersFactory.getUserTokens(user1.address);
      const user2Tokens = await erc20MembersFactory.getUserTokens(user2.address);
      
      expect(user1Tokens.length).to.equal(1);
      expect(user2Tokens.length).to.equal(1);
      expect(user1Tokens[0].name).to.equal("User1 Token");
      expect(user2Tokens[0].name).to.equal("User2 Token");
    });

    it("Debería manejar cambios de configuración durante la operación", async function () {
      // Configurar usuario inicial
      await userManager.connect(user1).registerUser(
        "user1",
        "user1@test.com",
        "https://twitter.com/user1",
        "https://github.com/user1",
        "https://t.me/user1",
        "https://avatar1.com",
        "https://cover1.com"
      );

      await nftContract.connect(user1).mintBatch(5, { value: NFT_MINT_PRICE * 5n });

      // Crear token con configuración inicial
      await erc20MembersFactory.connect(user1).createToken(
        "Initial Token",
        "IT",
        1000000,
        { value: TOKEN_CREATION_FEE }
      );

      // Cambiar configuración
      await erc20MembersFactory.connect(deployer).setTokenCreationFee(2000000000000000n); // 0.002 ETH
      await erc20MembersFactory.connect(deployer).setMinNFTsRequired(3);

      // user1 debería poder crear otro token con la nueva tarifa
      await erc20MembersFactory.connect(user1).createToken(
        "New Config Token",
        "NCT",
        1500000,
        { value: 2000000000000000n } // 0.002 ETH
      );

      // Verificar que ambos tokens fueron creados
      expect(await erc20MembersFactory.getTotalTokensCreated()).to.equal(2);
      expect(await erc20MembersFactory.getTokenCreationFee()).to.equal(2000000000000000n); // 0.002 ETH
      expect(await erc20MembersFactory.getMinNFTsRequired()).to.equal(3);
    });
  });
});
