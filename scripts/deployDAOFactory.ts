import { network } from "hardhat";

/**
 * Script para desplegar el contrato DAOFactory
 * Este factory permite a los usuarios crear instancias de DAO donde ellos serán los propietarios
 */
async function main() {
  console.log("🚀 Iniciando despliegue del DAOFactory...");
  
  // Conectar a la red y obtener ethers
  const { ethers } = await network.connect();
  
  // Obtener el deployer
  const [deployer] = await ethers.getSigners();
  console.log("📝 Desplegando con la cuenta:", deployer.address);
  console.log("💰 Balance de la cuenta:", ethers.formatEther(await deployer.provider!.getBalance(deployer.address)), "ETH");

  // Desplegar DAOFactory
  console.log("🏭 Desplegando DAOFactory...");
  const DAOFactory = await ethers.getContractFactory("DAOFactory");
  const daoFactory = await DAOFactory.deploy(deployer.address);
  
  await daoFactory.waitForDeployment();
  const factoryAddress = await daoFactory.getAddress();
  
  console.log("✅ DAOFactory desplegado exitosamente!");
  console.log("📍 Dirección del DAOFactory:", factoryAddress);
  console.log("👑 Propietario del Factory:", deployer.address);
  
  // Verificar el despliegue
  const totalDAOs = await daoFactory.getTotalDAOs();
  const factoryOwner = await daoFactory.owner();
  
  console.log("📊 Estadísticas del Factory:");
  console.log("   - Total de DAOs desplegados:", totalDAOs.toString());
  console.log("   - Propietario del Factory:", factoryOwner);
  
  // Ejemplo de cómo usar el factory (opcional)
  console.log("\n📋 Para usar el DAOFactory:");
  console.log("1. Conecta el contrato DAOFactory a la dirección:", factoryAddress);
  console.log("2. Llama a deployDAO() con los parámetros necesarios:");
  console.log("   - nftContract: dirección del contrato NFT");
  console.log("   - minProposalCreationTokens: mínimo NFTs para crear propuestas");
  console.log("   - minVotesToApprove: mínimo votantes únicos para aprobar");
  console.log("   - minTokensToApprove: mínimo poder de votación para aprobar");
  console.log("3. El usuario que llame deployDAO() será el propietario del nuevo DAO");
  
  console.log("\n🎉 Despliegue completado!");
  
  return {
    daoFactory,
    factoryAddress,
    deployer: deployer.address
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
