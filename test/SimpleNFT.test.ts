import { expect } from "chai";
import { network } from "hardhat";

describe("SimpleNFT - TypeScript Tests", function () {
  let nft: any;
  let deployer: any;
  let user1: any;
  let user2: any;
  
  const NAME = "Test NFT";
  const SYMBOL = "TNFT";
  const BASE_URI = "https://api.example.com/metadata/";
  const MINT_PRICE = 1000000000000000000n;

  beforeEach(async function () {
    const { ethers } = await network.connect();
    [deployer, user1, user2] = await ethers.getSigners();
    
    const SimpleNFTFactory = await ethers.getContractFactory("SimpleNFT");
    nft = await SimpleNFTFactory.deploy(NAME, SYMBOL, BASE_URI);
    await nft.waitForDeployment();
  });

  describe("Constructor", function () {
    it("Debería establecer el nombre correctamente", async function () {
      expect(await nft.name()).to.equal(NAME);
    });

    it("Debería establecer el símbolo correctamente", async function () {
      expect(await nft.symbol()).to.equal(SYMBOL);
    });

    it("Debería tener totalSupply inicial de 0", async function () {
      expect(await nft.totalSupply()).to.equal(0);
    });

    it("Debería tener nextTokenId inicial de 1", async function () {
      expect(await nft.nextTokenId()).to.equal(1);
    });

    it("Debería tener MINT_PRICE de 1 ether", async function () {
      expect(await nft.MINT_PRICE()).to.equal(MINT_PRICE);
    });
  });

  describe("Mint Individual", function () {
    it("Debería permitir mint con pago correcto", async function () {
      const tx = await nft.connect(user1).mint({ value: MINT_PRICE });
      const receipt = await tx.wait();
      
      expect(receipt).to.not.be.null;
      expect(await nft.ownerOf(1)).to.equal(user1.address);
      expect(await nft.totalSupply()).to.equal(1);
      expect(await nft.nextTokenId()).to.equal(2);
      expect(await nft.exists(1)).to.be.true;
    });

    it("Debería emitir evento TokenMinted", async function () {
      await expect(nft.connect(user1).mint({ value: MINT_PRICE }))
        .to.emit(nft, "TokenMinted")
        .withArgs(user1.address, 1, MINT_PRICE);
    });

    it("Debería revertir con pago insuficiente", async function () {
      const insufficientPayment = MINT_PRICE - 1n;
      await expect(
        nft.connect(user1).mint({ value: insufficientPayment })
      ).to.be.revertedWith("Debe enviar exactamente 1 PES para mintear");
    });

    it("Debería revertir con pago excesivo", async function () {
      const excessivePayment = MINT_PRICE + 1n;
      await expect(
        nft.connect(user1).mint({ value: excessivePayment })
      ).to.be.revertedWith("Debe enviar exactamente 1 PES para mintear");
    });

    it("Debería revertir sin pago", async function () {
      await expect(
        nft.connect(user1).mint()
      ).to.be.revertedWith("Debe enviar exactamente 1 PES para mintear");
    });
  });

  describe("Mint Batch", function () {
    it("Debería permitir mint batch con pago correcto", async function () {
      const quantity = 5;
      const totalCost = MINT_PRICE * BigInt(quantity);
      
      const tx = await nft.connect(user1).mintBatch(quantity, { value: totalCost });
      const receipt = await tx.wait();
      
      expect(receipt).to.not.be.null;
      expect(await nft.totalSupply()).to.equal(quantity);
      expect(await nft.nextTokenId()).to.equal(quantity + 1);
      
      for (let i = 1; i <= quantity; i++) {
        expect(await nft.ownerOf(i)).to.equal(user1.address);
        expect(await nft.exists(i)).to.be.true;
      }
    });

    it("Debería emitir eventos TokenMinted para cada token en batch", async function () {
      const quantity = 3;
      const totalCost = MINT_PRICE * BigInt(quantity);
      
      const tx = nft.connect(user1).mintBatch(quantity, { value: totalCost });
      
      for (let i = 1; i <= quantity; i++) {
        await expect(tx)
          .to.emit(nft, "TokenMinted")
          .withArgs(user1.address, i, MINT_PRICE);
      }
    });

    it("Debería revertir con cantidad 0", async function () {
      await expect(
        nft.connect(user1).mintBatch(0, { value: 0 })
      ).to.be.revertedWith("La cantidad debe ser mayor a 0");
    });

    it("Debería revertir con pago insuficiente", async function () {
      const quantity = 3;
      const totalCost = MINT_PRICE * BigInt(quantity);
      const insufficientPayment = totalCost - 1n;
      
      await expect(
        nft.connect(user1).mintBatch(quantity, { value: insufficientPayment })
      ).to.be.revertedWith("Debe enviar el precio correcto para la cantidad");
    });

    it("Debería revertir con pago excesivo", async function () {
      const quantity = 2;
      const totalCost = MINT_PRICE * BigInt(quantity);
      const excessivePayment = totalCost + 1n;
      
      await expect(
        nft.connect(user1).mintBatch(quantity, { value: excessivePayment })
      ).to.be.revertedWith("Debe enviar el precio correcto para la cantidad");
    });
  });

  describe("Múltiples Mints", function () {
    it("Debería permitir múltiples mints de diferentes usuarios", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      await nft.connect(user2).mint({ value: MINT_PRICE });
      
      expect(await nft.ownerOf(1)).to.equal(user1.address);
      expect(await nft.ownerOf(2)).to.equal(user2.address);
      expect(await nft.totalSupply()).to.equal(2);
      expect(await nft.nextTokenId()).to.equal(3);
    });

    it("Debería permitir combinación de mint individual y batch", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      const quantity = 3;
      const totalCost = MINT_PRICE * BigInt(quantity);
      await nft.connect(user2).mintBatch(quantity, { value: totalCost });
      
      expect(await nft.totalSupply()).to.equal(4);
      expect(await nft.nextTokenId()).to.equal(5);
      expect(await nft.ownerOf(1)).to.equal(user1.address);
      expect(await nft.ownerOf(2)).to.equal(user2.address);
      expect(await nft.ownerOf(3)).to.equal(user2.address);
      expect(await nft.ownerOf(4)).to.equal(user2.address);
    });
  });

  describe("URI Management", function () {
    it("Debería retornar URI base para token existente", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      expect(await nft.tokenURI(1)).to.equal(BASE_URI);
    });

    it("Debería retornar getBaseURI correctamente", async function () {
      expect(await nft.getBaseURI()).to.equal(BASE_URI);
    });

    it("Debería permitir cambiar baseURI y afectar todos los tokens", async function () {
      const newURI = "https://new-api.example.com/metadata/";
      
      await nft.setBaseURI(newURI);
      expect(await nft.getBaseURI()).to.equal(newURI);
      
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      expect(await nft.tokenURI(1)).to.equal(newURI);
    });

    it("Debería retornar la misma URI para todos los tokens", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      await nft.connect(user2).mint({ value: MINT_PRICE });
      await nft.connect(user1).mintBatch(2, { value: MINT_PRICE * 2n });
      
      expect(await nft.tokenURI(1)).to.equal(BASE_URI);
      expect(await nft.tokenURI(2)).to.equal(BASE_URI);
      expect(await nft.tokenURI(3)).to.equal(BASE_URI);
      expect(await nft.tokenURI(4)).to.equal(BASE_URI);
    });

    it("Debería revertir al establecer URI vacía", async function () {
      await expect(
        nft.setBaseURI("")
      ).to.be.revertedWith("La URI base no puede estar vacia");
    });

    it("Debería revertir al consultar URI de token inexistente", async function () {
      await expect(
        nft.tokenURI(999)
      ).to.be.revertedWithCustomError(nft, "ERC721NonexistentToken");
    });

    it("Debería actualizar URI de tokens existentes al cambiar baseURI", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      expect(await nft.tokenURI(1)).to.equal(BASE_URI);
      
      const newURI = "https://updated-api.example.com/metadata/";
      await nft.setBaseURI(newURI);
      
      expect(await nft.tokenURI(1)).to.equal(newURI);
      
      await nft.connect(user2).mint({ value: MINT_PRICE });
      expect(await nft.tokenURI(2)).to.equal(newURI);
    });
  });

  describe("Funciones de Utilidad", function () {
    it("Debería actualizar totalSupply correctamente", async function () {
      expect(await nft.totalSupply()).to.equal(0);
      
      await nft.connect(user1).mint({ value: MINT_PRICE });
      expect(await nft.totalSupply()).to.equal(1);
      
      await nft.connect(user2).mintBatch(3, { value: MINT_PRICE * 3n });
      expect(await nft.totalSupply()).to.equal(4);
    });

    it("Debería actualizar nextTokenId correctamente", async function () {
      expect(await nft.nextTokenId()).to.equal(1);
      
      await nft.connect(user1).mint({ value: MINT_PRICE });
      expect(await nft.nextTokenId()).to.equal(2);
      
      await nft.connect(user2).mintBatch(2, { value: MINT_PRICE * 2n });
      expect(await nft.nextTokenId()).to.equal(4);
    });

    it("Debería retornar correctamente si token existe", async function () {
      expect(await nft.exists(1)).to.be.false;
      
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      expect(await nft.exists(1)).to.be.true;
      expect(await nft.exists(2)).to.be.false;
    });
  });

  describe("Transferencia de Fondos", function () {
    it.skip("Debería transferir fondos al deployer en mint individual", async function () {
      const { ethers } = await network.connect();
      const deployerBalanceBefore = await ethers.provider.getBalance(deployer.address);
      
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      const deployerBalanceAfter = await ethers.provider.getBalance(deployer.address);
      expect(deployerBalanceAfter - deployerBalanceBefore).to.equal(MINT_PRICE);
    });

    it.skip("Debería transferir fondos al deployer en mint batch", async function () {
      const { ethers } = await network.connect();
      const quantity = 5;
      const totalCost = MINT_PRICE * BigInt(quantity);
      const deployerBalanceBefore = await ethers.provider.getBalance(deployer.address);
      
      await nft.connect(user1).mintBatch(quantity, { value: totalCost });
      
      const deployerBalanceAfter = await ethers.provider.getBalance(deployer.address);
      expect(deployerBalanceAfter - deployerBalanceBefore).to.equal(totalCost);
    });
  });

  describe("Tests de Integración", function () {
    it("Debería funcionar correctamente con flujo completo", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      await nft.connect(user2).mintBatch(3, { value: MINT_PRICE * 3n });
      
      const newURI = "https://final-api.example.com/metadata/";
      await nft.setBaseURI(newURI);
      
      expect(await nft.totalSupply()).to.equal(4);
      expect(await nft.nextTokenId()).to.equal(5);
      expect(await nft.ownerOf(1)).to.equal(user1.address);
      expect(await nft.ownerOf(2)).to.equal(user2.address);
      expect(await nft.ownerOf(3)).to.equal(user2.address);
      expect(await nft.ownerOf(4)).to.equal(user2.address);
      expect(await nft.tokenURI(1)).to.equal(newURI);
      expect(await nft.tokenURI(2)).to.equal(newURI);
      expect(await nft.tokenURI(3)).to.equal(newURI);
      expect(await nft.tokenURI(4)).to.equal(newURI);
    });
  });

  describe("Tests de Gas", function () {
    it("Debería reportar uso de gas para mint individual", async function () {
      const tx = await nft.connect(user1).mint({ value: MINT_PRICE });
      const receipt = await tx.wait();
      
      console.log(`Gas usado para mint individual: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });

    it("Debería reportar uso de gas para mint batch", async function () {
      const quantity = 5;
      const totalCost = MINT_PRICE * BigInt(quantity);
      
      const tx = await nft.connect(user1).mintBatch(quantity, { value: totalCost });
      const receipt = await tx.wait();
      
      console.log(`Gas usado para mint batch (${quantity} tokens): ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });
  });

  describe("Array nftHolders", function () {
    it("Debería tener array vacío inicialmente", async function () {
      await expect(nft.nftHolders(0)).to.be.revertedWithCustomError(nft, "Panic");
    });

    it("Debería agregar holder después de mint individual", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      expect(await nft.nftHolders(0)).to.equal(user1.address);
      await expect(nft.nftHolders(1)).to.be.revertedWithCustomError(nft, "Panic");
    });

    it("Debería agregar múltiples holders con mints separados", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      await nft.connect(user2).mint({ value: MINT_PRICE });
      
      expect(await nft.nftHolders(0)).to.equal(user1.address);
      expect(await nft.nftHolders(1)).to.equal(user2.address);
    });

    it("Debería agregar múltiples entradas para mint batch", async function () {
      const quantity = 3;
      const totalCost = MINT_PRICE * BigInt(quantity);
      
      await nft.connect(user1).mintBatch(quantity, { value: totalCost });
      
      expect(await nft.nftHolders(0)).to.equal(user1.address);
      expect(await nft.nftHolders(1)).to.equal(user1.address);
      expect(await nft.nftHolders(2)).to.equal(user1.address);
      await expect(nft.nftHolders(3)).to.be.revertedWithCustomError(nft, "Panic");
    });

    it("Debería manejar correctamente mints mixtos", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      await nft.connect(user2).mintBatch(2, { value: MINT_PRICE * 2n });
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      expect(await nft.nftHolders(0)).to.equal(user1.address);
      expect(await nft.nftHolders(1)).to.equal(user2.address);
      expect(await nft.nftHolders(2)).to.equal(user2.address);
      expect(await nft.nftHolders(3)).to.equal(user1.address);
    });
  });

  describe("Función getMintPrice", function () {
    it("Debería retornar el precio correcto de mint", async function () {
      expect(await nft.getMintPrice()).to.equal(MINT_PRICE);
    });

    it("Debería ser igual a la constante MINT_PRICE", async function () {
      const mintPrice = await nft.getMintPrice();
      const constantPrice = await nft.MINT_PRICE();
      expect(mintPrice).to.equal(constantPrice);
    });
  });

  describe("Casos Límite y Edge Cases", function () {
    it("Debería manejar mint batch de un solo token", async function () {
      await nft.connect(user1).mintBatch(1, { value: MINT_PRICE });
      
      expect(await nft.totalSupply()).to.equal(1);
      expect(await nft.nextTokenId()).to.equal(2);
      expect(await nft.ownerOf(1)).to.equal(user1.address);
      expect(await nft.nftHolders(0)).to.equal(user1.address);
    });

    it("Debería manejar mint batch de cantidad grande", async function () {
      const quantity = 50;
      const totalCost = MINT_PRICE * BigInt(quantity);
      
      await user1.sendTransaction({ to: user1.address, value: totalCost + MINT_PRICE });
      
      await nft.connect(user1).mintBatch(quantity, { value: totalCost });
      
      expect(await nft.totalSupply()).to.equal(quantity);
      expect(await nft.nextTokenId()).to.equal(quantity + 1);
      
      for (let i = 1; i <= quantity; i++) {
        expect(await nft.ownerOf(i)).to.equal(user1.address);
        expect(await nft.exists(i)).to.be.true;
      }
    });

    it("Debería retornar false para exists con tokenId 0", async function () {
      expect(await nft.exists(0)).to.be.false;
    });

    it("Debería retornar false para exists con tokenId muy grande", async function () {
      expect(await nft.exists("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")).to.be.false;
    });

    it("Debería revertir al consultar tokenURI con tokenId 0", async function () {
      await expect(nft.tokenURI(0)).to.be.revertedWithCustomError(nft, "ERC721NonexistentToken");
    });

    it("Debería revertir al consultar tokenURI con tokenId muy grande", async function () {
      await expect(nft.tokenURI("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))
        .to.be.revertedWithCustomError(nft, "ERC721NonexistentToken");
    });

    it("Debería manejar URI con caracteres especiales", async function () {
      const specialURI = "https://api.example.com/metadata/?token=%20&special=chars#fragment";
      
      await nft.setBaseURI(specialURI);
      expect(await nft.getBaseURI()).to.equal(specialURI);
      
      await nft.connect(user1).mint({ value: MINT_PRICE });
      expect(await nft.tokenURI(1)).to.equal(specialURI);
    });

    it("Debería manejar URI muy larga", async function () {
      const longURI = "https://very-long-domain-name-that-exceeds-normal-limits.example.com/api/v1/metadata/tokens/with/very/long/path/and/even/more/segments/to/test/limits/";
      
      await nft.setBaseURI(longURI);
      expect(await nft.getBaseURI()).to.equal(longURI);
      
      await nft.connect(user1).mint({ value: MINT_PRICE });
      expect(await nft.tokenURI(1)).to.equal(longURI);
    });
  });

  describe("Pruebas de Integración Avanzadas", function () {
    it("Debería manejar flujo completo de integración", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      await nft.connect(user2).mintBatch(3, { value: MINT_PRICE * 3n });
      
      const newURI = "https://new-api.example.com/metadata/";
      await nft.setBaseURI(newURI);
      
      await nft.connect(user1).mint({ value: MINT_PRICE });
      
      expect(await nft.totalSupply()).to.equal(5);
      expect(await nft.nextTokenId()).to.equal(6);
      expect(await nft.ownerOf(1)).to.equal(user1.address);
      expect(await nft.ownerOf(2)).to.equal(user2.address);
      expect(await nft.ownerOf(3)).to.equal(user2.address);
      expect(await nft.ownerOf(4)).to.equal(user2.address);
      expect(await nft.ownerOf(5)).to.equal(user1.address);
      
      expect(await nft.tokenURI(1)).to.equal(newURI);
      expect(await nft.tokenURI(2)).to.equal(newURI);
      expect(await nft.tokenURI(5)).to.equal(newURI);
      
      expect(await nft.nftHolders(0)).to.equal(user1.address);
      expect(await nft.nftHolders(1)).to.equal(user2.address);
      expect(await nft.nftHolders(2)).to.equal(user2.address);
      expect(await nft.nftHolders(3)).to.equal(user2.address);
      expect(await nft.nftHolders(4)).to.equal(user1.address);
    });

    it("Debería manejar múltiples cambios de URI con tokens existentes", async function () {
      await nft.connect(user1).mint({ value: MINT_PRICE });
      await nft.connect(user2).mint({ value: MINT_PRICE });
      
      const originalURI = await nft.getBaseURI();
      
      const uri1 = "https://api1.example.com/metadata/";
      const uri2 = "https://api2.example.com/metadata/";
      const uri3 = "https://api3.example.com/metadata/";
      
      await nft.setBaseURI(uri1);
      expect(await nft.tokenURI(1)).to.equal(uri1);
      expect(await nft.tokenURI(2)).to.equal(uri1);
      
      await nft.setBaseURI(uri2);
      expect(await nft.tokenURI(1)).to.equal(uri2);
      expect(await nft.tokenURI(2)).to.equal(uri2);
      
      await nft.setBaseURI(uri3);
      expect(await nft.tokenURI(1)).to.equal(uri3);
      expect(await nft.tokenURI(2)).to.equal(uri3);
      
      await nft.connect(user1).mint({ value: MINT_PRICE });
      expect(await nft.tokenURI(3)).to.equal(uri3);
    });
  });

  describe("Pruebas de Rendimiento y Gas", function () {
    it("Debería reportar gas para mint individual", async function () {
      const tx = await nft.connect(user1).mint({ value: MINT_PRICE });
      const receipt = await tx.wait();
      
      console.log(`Gas usado para mint individual: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });

    it("Debería reportar gas para mint batch", async function () {
      const quantity = 10;
      const totalCost = MINT_PRICE * BigInt(quantity);
      
      const tx = await nft.connect(user1).mintBatch(quantity, { value: totalCost });
      const receipt = await tx.wait();
      
      console.log(`Gas usado para mint batch (${quantity} tokens): ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });

    it("Debería reportar gas para cambio de URI", async function () {
      const tx = await nft.setBaseURI("https://new-api.example.com/metadata/");
      const receipt = await tx.wait();
      
      console.log(`Gas usado para cambiar URI: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });
  });

  describe("Pruebas de Eventos Detalladas", function () {
    it("Debería emitir TokenMinted con parámetros correctos", async function () {
      await expect(nft.connect(user1).mint({ value: MINT_PRICE }))
        .to.emit(nft, "TokenMinted")
        .withArgs(user1.address, 1, MINT_PRICE);
    });

    it("Debería emitir múltiples eventos TokenMinted en batch", async function () {
      const quantity = 3;
      const totalCost = MINT_PRICE * BigInt(quantity);
      
      const tx = nft.connect(user1).mintBatch(quantity, { value: totalCost });
      
      for (let i = 1; i <= quantity; i++) {
        await expect(tx)
          .to.emit(nft, "TokenMinted")
          .withArgs(user1.address, i, MINT_PRICE);
      }
    });

    it("Debería emitir eventos para diferentes usuarios", async function () {
      await expect(nft.connect(user1).mint({ value: MINT_PRICE }))
        .to.emit(nft, "TokenMinted")
        .withArgs(user1.address, 1, MINT_PRICE);
      
      await expect(nft.connect(user2).mint({ value: MINT_PRICE }))
        .to.emit(nft, "TokenMinted")
        .withArgs(user2.address, 2, MINT_PRICE);
    });
  });

  describe("Pruebas de Stress", function () {
    it("Debería manejar muchos mints individuales secuenciales", async function () {
      const count = 20;
      
      for (let i = 0; i < count; i++) {
        await nft.connect(user1).mint({ value: MINT_PRICE });
      }
      
      expect(await nft.totalSupply()).to.equal(count);
      expect(await nft.nextTokenId()).to.equal(count + 1);
      
      for (let i = 1; i <= count; i++) {
        expect(await nft.ownerOf(i)).to.equal(user1.address);
        expect(await nft.exists(i)).to.be.true;
      }
    });

    it("Debería manejar múltiples mints batch grandes", async function () {
      const batchSize = 10;
      const numBatches = 5;
      
      for (let batch = 0; batch < numBatches; batch++) {
        await nft.connect(user1).mintBatch(batchSize, { value: MINT_PRICE * BigInt(batchSize) });
      }
      
      expect(await nft.totalSupply()).to.equal(batchSize * numBatches);
      expect(await nft.nextTokenId()).to.equal(batchSize * numBatches + 1);
    });
  });
});