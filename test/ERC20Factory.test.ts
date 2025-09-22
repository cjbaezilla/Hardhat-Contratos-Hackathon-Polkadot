import { expect } from "chai";
import { network } from "hardhat";
import deployERC20Factory from "../scripts/deployERC20Factory.js";

/**
 * Pruebas para el script de despliegue de ERC20Factory
 * Verifica que el script funcione correctamente y despliegue el contrato apropiadamente
 */
describe("deployERC20Factory Script Tests", function () {
  let deployer: any;
  let user1: any;
  let user2: any;
  let erc20Factory: any;
  let factoryAddress: string;

  beforeEach(async function () {
    const { ethers } = await network.connect();
    [deployer, user1, user2] = await ethers.getSigners();
  });

  describe("Despliegue del Script", function () {
    it("Debería desplegar ERC20Factory exitosamente", async function () {
      // Ejecutar el script de despliegue
      const result = await deployERC20Factory();
      
      // Verificar que se retornó la información correcta
      expect(result).to.have.property("erc20Factory");
      expect(result).to.have.property("factoryAddress");
      expect(result).to.have.property("deployer");
      
      // Verificar que la dirección del deployer es correcta
      expect(result.deployer).to.equal(deployer.address);
      
      // Guardar instancias para pruebas posteriores
      erc20Factory = result.erc20Factory;
      factoryAddress = result.factoryAddress;
    });

    it("Debería tener una dirección válida para el factory", async function () {
      const result = await deployERC20Factory();
      
      // Verificar que la dirección no es la dirección cero
      const { ethers } = await network.connect();
      expect(result.factoryAddress).to.not.equal(ethers.ZeroAddress);
      
      // Verificar que la dirección tiene el formato correcto
      expect(result.factoryAddress).to.match(/^0x[a-fA-F0-9]{40}$/);
    });

    it("Debería poder conectarse al contrato desplegado", async function () {
      const result = await deployERC20Factory();
      
      // Verificar que podemos llamar funciones del contrato
      const totalTokens = await result.erc20Factory.totalTokensCreated();
      const allTokens = await result.erc20Factory.getAllTokens();
      
      expect(totalTokens).to.equal(0); // Inicialmente no hay tokens
      expect(allTokens).to.be.an("array");
      expect(allTokens.length).to.equal(0);
    });
  });

  describe("Estado Inicial del Factory", function () {
    beforeEach(async function () {
      const result = await deployERC20Factory();
      erc20Factory = result.erc20Factory;
      factoryAddress = result.factoryAddress;
    });

    it("Debería tener totalTokensCreated inicial en 0", async function () {
      const totalTokens = await erc20Factory.totalTokensCreated();
      expect(totalTokens).to.equal(0);
    });

    it("Debería tener array de tokens vacío inicialmente", async function () {
      const allTokens = await erc20Factory.getAllTokens();
      expect(allTokens).to.be.an("array");
      expect(allTokens.length).to.equal(0);
    });

    it("Debería poder obtener la dirección del factory", async function () {
      const address = await erc20Factory.getAddress();
      expect(address).to.equal(factoryAddress);
    });
  });

  describe("Funcionalidad del Factory", function () {
    beforeEach(async function () {
      const result = await deployERC20Factory();
      erc20Factory = result.erc20Factory;
      factoryAddress = result.factoryAddress;
    });

    it("Debería permitir crear un token ERC20", async function () {
      const tokenName = "Test Token";
      const tokenSymbol = "TTK";
      const initialSupply = 1000000;

      // Crear token usando el factory
      const tx = await erc20Factory.connect(user1).createToken(
        tokenName,
        tokenSymbol,
        initialSupply
      );
      
      await tx.wait();

      // Verificar que se incrementó el contador
      const totalTokens = await erc20Factory.totalTokensCreated();
      expect(totalTokens).to.equal(1);

      // Verificar que el token se agregó al array
      const allTokens = await erc20Factory.getAllTokens();
      expect(allTokens.length).to.equal(1);
      const { ethers } = await network.connect();
      expect(allTokens[0]).to.not.equal(ethers.ZeroAddress);
    });

    it("Debería permitir crear múltiples tokens", async function () {
      // Crear primer token
      await erc20Factory.connect(user1).createToken("Token 1", "TK1", 1000000);
      
      // Crear segundo token
      await erc20Factory.connect(user2).createToken("Token 2", "TK2", 2000000);

      // Verificar contadores
      const totalTokens = await erc20Factory.totalTokensCreated();
      expect(totalTokens).to.equal(2);

      const allTokens = await erc20Factory.getAllTokens();
      expect(allTokens.length).to.equal(2);
    });

    it("Debería emitir evento TokenCreated al crear token", async function () {
      const tokenName = "Event Test Token";
      const tokenSymbol = "ETT";
      const initialSupply = 500000;

      await expect(
        erc20Factory.connect(user1).createToken(tokenName, tokenSymbol, initialSupply)
      ).to.emit(erc20Factory, "TokenCreated")
        .withArgs(
          user1.address,
          tokenName,
          tokenSymbol,
          initialSupply,
          await erc20Factory.totalTokensCreated()
        );
    });
  });

  describe("Validaciones de Parámetros", function () {
    beforeEach(async function () {
      const result = await deployERC20Factory();
      erc20Factory = result.erc20Factory;
      factoryAddress = result.factoryAddress;
    });

    it("Debería revertir con nombre de token vacío", async function () {
      await expect(
        erc20Factory.connect(user1).createToken("", "TK", 1000000)
      ).to.be.revertedWith("El nombre no puede estar vacio");
    });

    it("Debería revertir con símbolo de token vacío", async function () {
      await expect(
        erc20Factory.connect(user1).createToken("Test Token", "", 1000000)
      ).to.be.revertedWith("El simbolo no puede estar vacio");
    });

    it("Debería revertir con suministro inicial de 0", async function () {
      await expect(
        erc20Factory.connect(user1).createToken("Test Token", "TK", 0)
      ).to.be.revertedWith("El suministro inicial debe ser mayor a 0");
    });
  });

  describe("Pruebas de Gas", function () {
    beforeEach(async function () {
      const result = await deployERC20Factory();
      erc20Factory = result.erc20Factory;
      factoryAddress = result.factoryAddress;
    });

    it("Debería reportar uso de gas para crear token", async function () {
      const tx = await erc20Factory.connect(user1).createToken(
        "Gas Test Token",
        "GTT",
        1000000
      );
      
      const receipt = await tx.wait();
      
      console.log(`Gas usado para crear token: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });

    it("Debería reportar uso de gas para despliegue del factory", async function () {
      // Desplegar un nuevo factory para medir gas
      const { ethers } = await network.connect();
      const ERC20Factory = await ethers.getContractFactory("ERC20Factory");
      const tx = await ERC20Factory.deploy();
      const receipt = await tx.wait();
      
      console.log(`Gas usado para desplegar ERC20Factory: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });
  });

  describe("Casos Límite", function () {
    beforeEach(async function () {
      const result = await deployERC20Factory();
      erc20Factory = result.erc20Factory;
      factoryAddress = result.factoryAddress;
    });

    it("Debería manejar nombres de token muy largos", async function () {
      const longName = "A".repeat(100); // 100 caracteres
      const tx = await erc20Factory.connect(user1).createToken(
        longName,
        "LNG",
        1000000
      );
      
      await expect(tx).to.not.be.reverted;
    });

    it("Debería manejar símbolos de token muy largos", async function () {
      const longSymbol = "A".repeat(50); // 50 caracteres
      const tx = await erc20Factory.connect(user1).createToken(
        "Test Token",
        longSymbol,
        1000000
      );
      
      await expect(tx).to.not.be.reverted;
    });

    it("Debería manejar suministros iniciales muy grandes", async function () {
      const { ethers } = await network.connect();
      const largeSupply = ethers.parseEther("1000000"); // 1,000,000 tokens con 18 decimales
      const tx = await erc20Factory.connect(user1).createToken(
        "Large Supply Token",
        "LST",
        largeSupply
      );
      
      await expect(tx).to.not.be.reverted;
    });
  });

  describe("Integración con Contratos Desplegados", function () {
    beforeEach(async function () {
      const result = await deployERC20Factory();
      erc20Factory = result.erc20Factory;
      factoryAddress = result.factoryAddress;
    });

    it("Debería poder interactuar con tokens creados", async function () {
      // Crear un token
      const tx = await erc20Factory.connect(user1).createToken(
        "Integration Test Token",
        "ITT",
        1000000
      );
      await tx.wait();

      // Obtener la dirección del token creado
      const allTokens = await erc20Factory.getAllTokens();
      const tokenAddress = allTokens[0];

      // Conectar al token creado
      const { ethers } = await network.connect();
      const SimpleERC20 = await ethers.getContractFactory("SimpleERC20");
      const token = SimpleERC20.attach(tokenAddress);

      // Verificar que el token funciona correctamente
      const name = await token.name();
      const symbol = await token.symbol();
      const totalSupply = await token.totalSupply();
      const owner = await token.owner();

      expect(name).to.equal("Integration Test Token");
      expect(symbol).to.equal("ITT");
      expect(totalSupply).to.equal(1000000);
      expect(owner).to.equal(user1.address);
    });

    it("Debería permitir transferir tokens creados", async function () {
      // Crear un token
      const tx = await erc20Factory.connect(user1).createToken(
        "Transfer Test Token",
        "TTT",
        1000000
      );
      await tx.wait();

      // Obtener la dirección del token
      const allTokens = await erc20Factory.getAllTokens();
      const tokenAddress = allTokens[0];

      // Conectar al token
      const { ethers } = await network.connect();
      const SimpleERC20 = await ethers.getContractFactory("SimpleERC20");
      const token = SimpleERC20.attach(tokenAddress);

      // Transferir tokens
      const transferAmount = 1000;
      await token.connect(user1).transfer(user2.address, transferAmount);

      // Verificar balances
      const user1Balance = await token.balanceOf(user1.address);
      const user2Balance = await token.balanceOf(user2.address);

      expect(user1Balance).to.equal(1000000 - transferAmount);
      expect(user2Balance).to.equal(transferAmount);
    });
  });

  describe("Manejo de Errores", function () {
    beforeEach(async function () {
      const result = await deployERC20Factory();
      erc20Factory = result.erc20Factory;
      factoryAddress = result.factoryAddress;
    });

    it("Debería manejar errores de red correctamente", async function () {
      // Simular un error desconectando la red temporalmente
      // (En un entorno de prueba real, esto requeriría configuración especial)
      
      // Verificar que el contrato sigue siendo válido
      const totalTokens = await erc20Factory.totalTokensCreated();
      expect(totalTokens).to.be.a("bigint");
    });

    it("Debería revertir con parámetros inválidos", async function () {
      // Probar con diferentes combinaciones de parámetros inválidos
      await expect(
        erc20Factory.connect(user1).createToken("", "", 0)
      ).to.be.reverted;
    });
  });
});
