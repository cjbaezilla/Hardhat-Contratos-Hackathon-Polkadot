import { network } from "hardhat";

/**
 * Script para desplegar el contrato DAOFactory y crear una nueva DAO usando la cuenta 2
 * Este script demuestra el flujo completo: Factory -> NFT -> DAO
 */
async function main() {
  console.log("🚀 Iniciando despliegue completo: DAOFactory + SimpleNFT + DAO...");
  
  // Conectar a la red y obtener ethers
  const { ethers } = await network.connect();
  
  // Obtener las cuentas
  const [deployer, account2] = await ethers.getSigners();
  console.log("📝 Desplegando con la cuenta principal:", deployer.address);
  console.log("👤 Cuenta 2 (creará la DAO):", account2.address);
  console.log("💰 Balance cuenta principal:", ethers.formatEther(await deployer.provider!.getBalance(deployer.address)), "ETH");
  console.log("💰 Balance cuenta 2:", ethers.formatEther(await account2.provider!.getBalance(account2.address)), "ETH");

  // Paso 1: Desplegar DAOFactory
  console.log("\n🏭 Paso 1: Desplegando DAOFactory...");
  const DAOFactory = await ethers.getContractFactory("DAOFactory");
  const daoFactory = await DAOFactory.deploy(deployer.address);
  
  await daoFactory.waitForDeployment();
  const factoryAddress = await daoFactory.getAddress();
  
  console.log("✅ DAOFactory desplegado exitosamente!");
  console.log("📍 Dirección del DAOFactory:", factoryAddress);
  console.log("👑 Propietario del Factory:", deployer.address);

  // Paso 2: Desplegar SimpleNFT
  console.log("\n🎨 Paso 2: Desplegando SimpleNFT...");
  const SimpleNFT = await ethers.getContractFactory("SimpleNFT");
  const simpleNFT = await SimpleNFT.deploy(
    "DAO Governance Token",
    "DGT",
    "https://baeza.me/metadata/"
  );
  
  await simpleNFT.waitForDeployment();
  const nftAddress = await simpleNFT.getAddress();
  
  console.log("✅ SimpleNFT desplegado exitosamente!");
  console.log("📍 Dirección del SimpleNFT:", nftAddress);

  // Paso 3: Crear DAO usando la cuenta 2
  console.log("\n🗳️ Paso 3: Creando DAO con la cuenta 2...");
  
  // Conectar la cuenta 2 al contrato DAOFactory
  const daoFactoryWithAccount2 = daoFactory.connect(account2);
  
  // Parámetros para la nueva DAO
  const minProposalCreationTokens = 1; // Mínimo 1 NFT para crear propuestas
  const minVotesToApprove = 2; // Mínimo 2 votantes únicos para aprobar
  const minTokensToApprove = 2; // Mínimo 2 NFTs de poder de votación para aprobar
  
  console.log("📋 Parámetros de la DAO:");
  console.log("   - Contrato NFT:", nftAddress);
  console.log("   - Mínimo NFTs para crear propuestas:", minProposalCreationTokens);
  console.log("   - Mínimo votantes únicos para aprobar:", minVotesToApprove);
  console.log("   - Mínimo poder de votación para aprobar:", minTokensToApprove);
  
  // Llamar deployDAO() con la cuenta 2
  const deployDAOTx = await daoFactoryWithAccount2.deployDAO(
    nftAddress,
    minProposalCreationTokens,
    minVotesToApprove,
    minTokensToApprove
  );
  
  const receipt = await deployDAOTx.wait();
  console.log("✅ Transacción de creación de DAO confirmada!");
  console.log("📄 Hash de la transacción:", deployDAOTx.hash);
  
  // Obtener la dirección de la nueva DAO desde el evento
  const event = receipt?.logs.find(log => {
    try {
      const parsed = daoFactory.interface.parseLog(log);
      return parsed?.name === "DAOCreated";
    } catch {
      return false;
    }
  });
  
  let newDAOAddress: string;
  if (event) {
    const parsed = daoFactory.interface.parseLog(event);
    newDAOAddress = parsed?.args.daoAddress;
  } else {
    // Fallback: obtener la última DAO creada
    const totalDAOs = await daoFactory.getTotalDAOs();
    newDAOAddress = await daoFactory.getDAOByIndex(totalDAOs - 1n);
  }
  
  console.log("🎉 Nueva DAO creada exitosamente!");
  console.log("📍 Dirección de la nueva DAO:", newDAOAddress);
  console.log("👤 Creador de la DAO:", account2.address);

  // Paso 4: Verificar la nueva DAO
  console.log("\n🔍 Paso 4: Verificando la nueva DAO...");
  
  // Conectar a la nueva DAO
  const DAO = await ethers.getContractFactory("DAO");
  const newDAO = DAO.attach(newDAOAddress);
  
  // Verificar que la cuenta 2 es el propietario de la DAO
  const daoOwner = await newDAO.owner();
  console.log("👑 Propietario de la DAO:", daoOwner);
  console.log("✅ ¿La cuenta 2 es propietaria?", daoOwner === account2.address ? "SÍ" : "NO");
  
  // Obtener parámetros de la DAO
  const nftContract = await newDAO.nftContract();
  const minProposalTokens = await newDAO.MIN_PROPOSAL_CREATION_TOKENS();
  const minVotes = await newDAO.MIN_VOTES_TO_APPROVE();
  const minTokens = await newDAO.MIN_TOKENS_TO_APPROVE();
  
  console.log("📊 Parámetros de la DAO verificados:");
  console.log("   - Contrato NFT:", nftContract);
  console.log("   - Mínimo NFTs para propuestas:", minProposalTokens.toString());
  console.log("   - Mínimo votantes para aprobar:", minVotes.toString());
  console.log("   - Mínimo poder de votación:", minTokens.toString());

  // Paso 5: Estadísticas finales
  console.log("\n📈 Paso 5: Estadísticas finales...");
  
  const factoryStats = await daoFactory.getFactoryStats();
  console.log("🏭 Estadísticas del DAOFactory:");
  console.log("   - Total de DAOs desplegados:", factoryStats.totalDAOs.toString());
  console.log("   - Propietario del Factory:", factoryStats.factoryOwner);
  
  const nftStats = {
    totalSupply: await simpleNFT.totalSupply(),
    nextTokenId: await simpleNFT.nextTokenId(),
    mintPrice: await simpleNFT.getMintPrice()
  };
  
  console.log("🎨 Estadísticas del SimpleNFT:");
  console.log("   - Total supply:", nftStats.totalSupply.toString());
  console.log("   - Siguiente token ID:", nftStats.nextTokenId.toString());
  console.log("   - Precio de mint:", ethers.formatEther(nftStats.mintPrice), "ETH");

  console.log("\n🎉 ¡Despliegue completo exitoso!");
  console.log("📋 Resumen:");
  console.log("   - DAOFactory:", factoryAddress);
  console.log("   - SimpleNFT:", nftAddress);
  console.log("   - Nueva DAO:", newDAOAddress);
  console.log("   - Propietario de la DAO:", account2.address);
  
  return {
    daoFactory,
    factoryAddress,
    simpleNFT,
    nftAddress,
    newDAO,
    newDAOAddress,
    deployer: deployer.address,
    daoCreator: account2.address
  };
}

// Ejecutar el script si se llama directamente
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error durante el despliegue:", error);
    process.exit(1);
  });

export default main;
