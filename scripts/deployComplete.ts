import { network } from "hardhat";

/**
 * Script completo de despliegue que ejecuta todos los contratos en secuencia
 * y devuelve un resumen JSON con todas las direcciones
 */
async function main() {
  console.log("Iniciando despliegue completo...\n");

  const { ethers } = await network.connect();
  
  // Obtener el deployer
  const [deployer] = await ethers.getSigners();
  console.log("Desplegando contratos con la cuenta:", deployer.address);
  console.log("Balance de la cuenta:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  const deploymentResults: any = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {}
  };

  try {
    // ========================================
    // PASO 1: Desplegar SimpleNFT
    // ========================================
    console.log("1️⃣ Desplegando SimpleNFT...");
    const SimpleNFT = await ethers.getContractFactory("SimpleNFT");
    const simpleNFT = await SimpleNFT.deploy(
      "PolkaDAO NFT",           // name
      "POLKA",                  // symbol
      "https://api.polkadao.com/metadata/" // baseURI
    );
    await simpleNFT.waitForDeployment();
    const nftAddress = await simpleNFT.getAddress();
    
    console.log("✅ SimpleNFT desplegado en:", nftAddress);
    deploymentResults.contracts.SimpleNFT = {
      address: nftAddress,
      name: "PolkaDAO NFT",
      symbol: "POLKA",
      baseURI: "https://api.polkadao.com/metadata/"
    };

    // ========================================
    // PASO 2: Desplegar DAO usando la dirección del NFT
    // ========================================
    console.log("\n2️⃣ Desplegando DAO...");
    const DAO = await ethers.getContractFactory("DAO");
    const dao = await DAO.deploy(
      "PolkaDAO",               // name
      nftAddress,               // nftContract
      10,                       // minProposalCreationTokens
      5,                        // minVotesToApprove
      50                        // minTokensToApprove
    );
    await dao.waitForDeployment();
    const daoAddress = await dao.getAddress();
    
    console.log("✅ DAO desplegado en:", daoAddress);
    deploymentResults.contracts.DAO = {
      address: daoAddress,
      name: "PolkaDAO",
      nftContract: nftAddress,
      minProposalCreationTokens: 10,
      minVotesToApprove: 5,
      minTokensToApprove: 50
    };

    // ========================================
    // PASO 3: Desplegar SimpleUserManager
    // ========================================
    console.log("\n3️⃣ Desplegando SimpleUserManager...");
    const SimpleUserManager = await ethers.getContractFactory("SimpleUserManager");
    const userManager = await SimpleUserManager.deploy();
    await userManager.waitForDeployment();
    const userManagerAddress = await userManager.getAddress();
    
    console.log("✅ SimpleUserManager desplegado en:", userManagerAddress);
    deploymentResults.contracts.SimpleUserManager = {
      address: userManagerAddress
    };

    // ========================================
    // PASO 4: Desplegar ERC20MembersFactory
    // ========================================
    console.log("\n4️⃣ Desplegando ERC20MembersFactory...");
    const ERC20MembersFactory = await ethers.getContractFactory("ERC20MembersFactory");
    const erc20Factory = await ERC20MembersFactory.deploy(
      userManagerAddress,       // userManager
      nftAddress                // nftContract
    );
    await erc20Factory.waitForDeployment();
    const erc20FactoryAddress = await erc20Factory.getAddress();
    
    console.log("✅ ERC20MembersFactory desplegado en:", erc20FactoryAddress);
    deploymentResults.contracts.ERC20MembersFactory = {
      address: erc20FactoryAddress,
      userManager: userManagerAddress,
      nftContract: nftAddress,
      minNFTsRequired: 5,
      tokenCreationFee: "0.001"
    };

    // ========================================
    // PASO 5: Desplegar DAOMembersFactory
    // ========================================
    console.log("\n5️⃣ Desplegando DAOMembersFactory...");
    const DAOMembersFactory = await ethers.getContractFactory("DAOMembersFactory");
    const daoFactory = await DAOMembersFactory.deploy(
      userManagerAddress,       // userManager
      nftAddress,               // nftContract
      deployer.address          // initialOwner
    );
    await daoFactory.waitForDeployment();
    const daoFactoryAddress = await daoFactory.getAddress();
    
    console.log("✅ DAOMembersFactory desplegado en:", daoFactoryAddress);
    deploymentResults.contracts.DAOMembersFactory = {
      address: daoFactoryAddress,
      userManager: userManagerAddress,
      nftContract: nftAddress,
      minNFTsRequired: 5,
      daoCreationFee: "0.001",
      owner: deployer.address
    };

    // ========================================
    // VERIFICACIÓN DE CONEXIONES
    // ========================================
    console.log("\nVerificando conexiones entre contratos...");
    
    // Verificar que el DAO tiene la dirección correcta del NFT
    const daoNftAddress = await dao.nftContract();
    console.log("DAO -> NFT:", daoNftAddress === nftAddress ? "✅ Correcto" : "❌ Incorrecto");
    
    // Verificar que ERC20MembersFactory tiene las direcciones correctas
    const erc20UserManager = await erc20Factory.getUserManagerAddress();
    const erc20NftContract = await erc20Factory.getNFTContractAddress();
    console.log("ERC20Factory -> UserManager:", erc20UserManager === userManagerAddress ? "✅ Correcto" : "❌ Incorrecto");
    console.log("ERC20Factory -> NFT:", erc20NftContract === nftAddress ? "✅ Correcto" : "❌ Incorrecto");
    
    // Verificar que DAOMembersFactory tiene las direcciones correctas
    const daoFactoryUserManager = await daoFactory.getUserManagerAddress();
    const daoFactoryNftContract = await daoFactory.getNFTContractAddress();
    console.log("DAOFactory -> UserManager:", daoFactoryUserManager === userManagerAddress ? "✅ Correcto" : "❌ Incorrecto");
    console.log("DAOFactory -> NFT:", daoFactoryNftContract === nftAddress ? "✅ Correcto" : "❌ Incorrecto");

    // ========================================
    // MOSTRAR RESULTADOS EN TERMINAL
    // ========================================
    
    // Mostrar resumen final
    console.log("\n" + "=".repeat(60));
    console.log("DESPLIEGUE COMPLETADO EXITOSAMENTE");
    console.log("=".repeat(60));
    console.log("RESUMEN DE DIRECCIONES:");
    console.log("=".repeat(60));
    console.log(`SimpleNFT:           ${nftAddress}`);
    console.log(`DAO:                 ${daoAddress}`);
    console.log(`SimpleUserManager:   ${userManagerAddress}`);
    console.log(`ERC20MembersFactory: ${erc20FactoryAddress}`);
    console.log(`DAOMembersFactory:   ${daoFactoryAddress}`);
    console.log("=".repeat(60));
    } catch (error) {
    console.error("❌ Error durante el despliegue:", error);
    throw error;
  }
}

// Ejecutar el script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
