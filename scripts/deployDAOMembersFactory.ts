import { network } from "hardhat";

/**
 * Script para desplegar el contrato DAOMembersFactory
 * Este factory permite a los usuarios registrados con suficientes NFTs crear DAOs personalizados
 * Requiere las direcciones de SimpleUserManager y SimpleNFT como dependencias
 */
async function main() {
  console.log("🚀 Iniciando despliegue del DAOMembersFactory...");
  
  const { ethers } = await network.connect();
  
  const [deployer] = await ethers.getSigners();
  console.log("📝 Desplegando con la cuenta:", deployer.address);
  console.log("💰 Balance de la cuenta:", ethers.formatEther(await deployer.provider!.getBalance(deployer.address)), "ETH");

  // Direcciones de los contratos dependientes
  // NOTA: Estas direcciones deben ser actualizadas con las direcciones reales de los contratos desplegados
  const USER_MANAGER_ADDRESS = process.env.USER_MANAGER_ADDRESS || "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  const NFT_CONTRACT_ADDRESS = process.env.NFT_CONTRACT_ADDRESS || "0x5FbDB2315678afecb367f032d93F642f64180aa3";

  console.log("🔗 Direcciones de dependencias:");
  console.log("   - SimpleUserManager:", USER_MANAGER_ADDRESS);
  console.log("   - SimpleNFT:", NFT_CONTRACT_ADDRESS);

  console.log("🏭 Desplegando DAOMembersFactory...");
  const DAOMembersFactory = await ethers.getContractFactory("DAOMembersFactory");
  const daoMembersFactory = await DAOMembersFactory.deploy(
    USER_MANAGER_ADDRESS,
    NFT_CONTRACT_ADDRESS,
    deployer.address // initialOwner
  );
  
  await daoMembersFactory.waitForDeployment();
  const factoryAddress = await daoMembersFactory.getAddress();
  
  console.log("✅ DAOMembersFactory desplegado exitosamente!");
  console.log("📍 Dirección del DAOMembersFactory:", factoryAddress);
  console.log("🔗 Explorer (Polkadot Hub Testnet):", `https://polkadot-hub-testnet.subscan.io/account/${factoryAddress}`);
  
  // Verificar el despliegue y obtener información del contrato
  const totalDAOs = await daoMembersFactory.getTotalDAOs();
  const daoCreationFee = await daoMembersFactory.getDAOCreationFee();
  const minNFTsRequired = await daoMembersFactory.getMinNFTsRequired();
  const userManagerAddress = await daoMembersFactory.getUserManagerAddress();
  const nftContractAddress = await daoMembersFactory.getNFTContractAddress();
  const factoryOwner = await daoMembersFactory.owner();
  
  console.log("\n📊 Estadísticas del DAOMembersFactory:");
  console.log("   - Total de DAOs creados:", totalDAOs.toString());
  console.log("   - Tarifa de creación de DAOs:", ethers.formatEther(daoCreationFee), "ETH");
  console.log("   - NFTs mínimos requeridos:", minNFTsRequired.toString());
  console.log("   - Dirección del UserManager:", userManagerAddress);
  console.log("   - Dirección del contrato NFT:", nftContractAddress);
  console.log("   - Propietario del factory:", factoryOwner);
  
  const deploymentInfo = {
    contractName: "DAOMembersFactory",
    contractAddress: factoryAddress,
    deployer: deployer.address,
    network: "polkadotHubTestnet",
    timestamp: new Date().toISOString(),
    constructorArgs: {
      userManagerAddress: USER_MANAGER_ADDRESS,
      nftContractAddress: NFT_CONTRACT_ADDRESS,
      initialOwner: deployer.address
    },
    contractConfig: {
      daoCreationFee: ethers.formatEther(daoCreationFee),
      minNFTsRequired: minNFTsRequired.toString(),
      totalDAOs: totalDAOs.toString()
    },
    features: {
      daoCreation: "Permite a usuarios registrados con suficientes NFTs crear DAOs personalizados",
      userValidation: "Valida que el usuario esté registrado en SimpleUserManager",
      nftRequirement: "Requiere que el usuario tenga al menos 5 NFTs para crear DAOs",
      feeSystem: "Sistema de tarifas para la creación de DAOs",
      daoTracking: "Rastrea todos los DAOs creados y sus creadores",
      ownershipTransfer: "Permite transferir la propiedad del factory",
      configurableParameters: "Permite al owner ajustar tarifas y requisitos mínimos"
    }
  };

  console.log("\n💾 Información del despliegue guardada:");
  console.log(JSON.stringify(deploymentInfo, null, 2));
  
  console.log("\n📋 Para usar el DAOMembersFactory:");
  console.log("1. Conecta el contrato DAOMembersFactory a la dirección:", factoryAddress);
  console.log("2. Los usuarios deben cumplir los siguientes requisitos:");
  console.log("   - Estar registrados en SimpleUserManager");
  console.log("   - Tener al menos", minNFTsRequired.toString(), "NFTs en su wallet");
  console.log("   - Pagar la tarifa de creación:", ethers.formatEther(daoCreationFee), "ETH");
  console.log("3. Para crear un DAO, llama a deployDAO() con:");
  console.log("   - nftContractAddress: dirección del contrato NFT a usar para el DAO");
  console.log("   - minProposalCreationTokens: mínimo de tokens para crear propuestas");
  console.log("   - minVotesToApprove: mínimo de votos para aprobar propuestas");
  console.log("   - minTokensToApprove: mínimo de tokens para aprobar propuestas");
  console.log("4. El DAO se creará automáticamente y se registrará en el factory");
  console.log("5. El creador del DAO será el propietario del nuevo contrato DAO");
  
  console.log("\n🔧 Funciones administrativas (solo owner):");
  console.log("   - setDAOCreationFee(): ajustar la tarifa de creación de DAOs");
  console.log("   - setMinNFTsRequired(): ajustar el mínimo de NFTs requeridos");
  console.log("   - transferFactoryOwnership(): transferir la propiedad del factory");
  
  console.log("\n📊 Funciones de consulta:");
  console.log("   - getAllDAOs(): obtener todos los DAOs creados");
  console.log("   - getDAOByIndex(): obtener un DAO por índice");
  console.log("   - getDAOCreator(): obtener el creador de un DAO específico");
  console.log("   - isDAO(): verificar si una dirección es un DAO válido");
  console.log("   - checkUserRequirements(): verificar si un usuario puede crear DAOs");
  console.log("   - getFactoryStats(): obtener estadísticas del factory");
  
  console.log("\n🎉 ¡Despliegue completado exitosamente!");
  console.log("💡 Próximos pasos:");
  console.log("   1. Verifica el contrato en el explorer");
  console.log("   2. Configura las variables de entorno para futuros despliegues");
  console.log("   3. Integra el DAOMembersFactory con tu frontend");
  console.log("   4. Implementa la lógica de validación de usuarios y NFTs");
  console.log("   5. Prueba la creación de DAOs con usuarios que cumplan los requisitos");
  console.log("   6. Configura las tarifas y requisitos según tus necesidades");
  console.log("   7. Considera implementar un sistema de gobernanza para el factory");
  
  return {
    daoMembersFactory,
    factoryAddress,
    deployer: deployer.address,
    userManagerAddress,
    nftContractAddress
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
