import { network } from "hardhat";

/**
 * Script para desplegar el contrato ERC20MembersFactory
 * Este factory permite a los usuarios registrados con suficientes NFTs crear tokens ERC20 personalizados
 * Requiere las direcciones de SimpleUserManager y SimpleNFT como dependencias
 */
async function main() {
  console.log("🚀 Iniciando despliegue del ERC20MembersFactory...");
  
  const { ethers } = await network.connect();
  
  const [deployer] = await ethers.getSigners();
  console.log("📝 Desplegando con la cuenta:", deployer.address);
  console.log("💰 Balance de la cuenta:", ethers.formatEther(await deployer.provider!.getBalance(deployer.address)), "ETH");

  // Direcciones de los contratos dependientes
  // NOTA: Estas direcciones deben ser actualizadas con las direcciones reales de los contratos desplegados
  const USER_MANAGER_ADDRESS = process.env.USER_MANAGER_ADDRESS || "0xc3e53F4d16Ae77Db1c982e75a937B9f60FE63690";
  const NFT_CONTRACT_ADDRESS = process.env.NFT_CONTRACT_ADDRESS || "0x67d269191c92Caf3cD7723F116c85e6E9bf55933";

  console.log("🔗 Direcciones de dependencias:");
  console.log("   - SimpleUserManager:", USER_MANAGER_ADDRESS);
  console.log("   - SimpleNFT:", NFT_CONTRACT_ADDRESS);

  console.log("🏭 Desplegando ERC20MembersFactory...");
  const ERC20MembersFactory = await ethers.getContractFactory("ERC20MembersFactory");
  const erc20MembersFactory = await ERC20MembersFactory.deploy(
    USER_MANAGER_ADDRESS,
    NFT_CONTRACT_ADDRESS
  );
  
  await erc20MembersFactory.waitForDeployment();
  const factoryAddress = await erc20MembersFactory.getAddress();
  
  console.log("✅ ERC20MembersFactory desplegado exitosamente!");
  console.log("📍 Dirección del ERC20MembersFactory:", factoryAddress);
  console.log("🔗 Explorer (Polkadot Hub Testnet):", `https://polkadot-hub-testnet.subscan.io/account/${factoryAddress}`);
  
  // Verificar el despliegue y obtener información del contrato
  const totalTokensCreated = await erc20MembersFactory.getTotalTokensCreated();
  const tokenCreationFee = await erc20MembersFactory.getTokenCreationFee();
  const minNFTsRequired = await erc20MembersFactory.getMinNFTsRequired();
  const userManagerAddress = await erc20MembersFactory.getUserManagerAddress();
  const nftContractAddress = await erc20MembersFactory.getNFTContractAddress();
  
  console.log("\n📊 Estadísticas del ERC20MembersFactory:");
  console.log("   - Total de tokens creados:", totalTokensCreated.toString());
  console.log("   - Tarifa de creación de tokens:", ethers.formatEther(tokenCreationFee), "ETH");
  console.log("   - NFTs mínimos requeridos:", minNFTsRequired.toString());
  console.log("   - Dirección del UserManager:", userManagerAddress);
  console.log("   - Dirección del contrato NFT:", nftContractAddress);
  
  const deploymentInfo = {
    contractName: "ERC20MembersFactory",
    contractAddress: factoryAddress,
    deployer: deployer.address,
    network: "polkadotHubTestnet",
    timestamp: new Date().toISOString(),
    constructorArgs: {
      userManagerAddress: USER_MANAGER_ADDRESS,
      nftContractAddress: NFT_CONTRACT_ADDRESS
    },
    contractConfig: {
      tokenCreationFee: ethers.formatEther(tokenCreationFee),
      minNFTsRequired: minNFTsRequired.toString(),
      totalTokensCreated: totalTokensCreated.toString()
    },
    features: {
      tokenCreation: "Permite a usuarios registrados con suficientes NFTs crear tokens ERC20",
      userValidation: "Valida que el usuario esté registrado en SimpleUserManager",
      nftRequirement: "Requiere que el usuario tenga al menos 5 NFTs para crear tokens",
      feeSystem: "Sistema de tarifas para la creación de tokens",
      tokenTracking: "Rastrea todos los tokens creados por usuario y globalmente",
      ownerControls: "Permite al owner ajustar tarifas y requisitos mínimos"
    }
  };

  console.log("\n💾 Información del despliegue guardada:");
  console.log(JSON.stringify(deploymentInfo, null, 2));
  
  console.log("\n📋 Para usar el ERC20MembersFactory:");
  console.log("1. Conecta el contrato ERC20MembersFactory a la dirección:", factoryAddress);
  console.log("2. Los usuarios deben cumplir los siguientes requisitos:");
  console.log("   - Estar registrados en SimpleUserManager");
  console.log("   - Tener al menos", minNFTsRequired.toString(), "NFTs en su wallet");
  console.log("   - Pagar la tarifa de creación:", ethers.formatEther(tokenCreationFee), "ETH");
  console.log("3. Para crear un token, llama a createToken() con:");
  console.log("   - name_: nombre del token (ej: 'Mi Token de Miembros')");
  console.log("   - symbol_: símbolo del token (ej: 'MTM')");
  console.log("   - initialSupply_: suministro inicial (ej: 1000000)");
  console.log("4. El token se creará automáticamente y se registrará en el factory");
  console.log("5. El creador del token será el propietario del nuevo token ERC20");
  
  console.log("\n🔧 Funciones administrativas (solo owner):");
  console.log("   - setTokenCreationFee(): ajustar la tarifa de creación");
  console.log("   - setMinNFTsRequired(): ajustar el mínimo de NFTs requeridos");
  
  console.log("\n📊 Funciones de consulta:");
  console.log("   - getUserTokens(): obtener tokens creados por un usuario");
  console.log("   - getAllTokens(): obtener todos los tokens creados");
  console.log("   - checkUserRequirements(): verificar si un usuario puede crear tokens");
  console.log("   - isTokenFromFactory(): verificar si un token fue creado por este factory");
  
  console.log("\n🎉 ¡Despliegue completado exitosamente!");
  console.log("💡 Próximos pasos:");
  console.log("   1. Verifica el contrato en el explorer");
  console.log("   2. Configura las variables de entorno para futuros despliegues");
  console.log("   3. Integra el ERC20MembersFactory con tu frontend");
  console.log("   4. Implementa la lógica de validación de usuarios y NFTs");
  console.log("   5. Prueba la creación de tokens con usuarios que cumplan los requisitos");
  console.log("   6. Configura las tarifas y requisitos según tus necesidades");
  
  return {
    erc20MembersFactory,
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
