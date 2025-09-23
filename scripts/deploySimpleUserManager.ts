import { network } from "hardhat";

/**
 * Script para desplegar el contrato SimpleUserManager
 * Este contrato permite gestionar usuarios con información personal y enlaces sociales
 */
async function main() {
  console.log("🚀 Iniciando despliegue del SimpleUserManager...");
  
  const { ethers } = await network.connect();
  
  const [deployer] = await ethers.getSigners();
  console.log("📝 Desplegando con la cuenta:", deployer.address);
  console.log("💰 Balance de la cuenta:", ethers.formatEther(await deployer.provider!.getBalance(deployer.address)), "ETH");

  console.log("👥 Desplegando SimpleUserManager...");
  const SimpleUserManager = await ethers.getContractFactory("SimpleUserManager");
  const userManager = await SimpleUserManager.deploy();
  
  await userManager.waitForDeployment();
  const userManagerAddress = await userManager.getAddress();
  
  console.log("✅ SimpleUserManager desplegado exitosamente!");
  console.log("📍 Dirección del SimpleUserManager:", userManagerAddress);
  
  const totalMembers = await userManager.getTotalMembers();
  const allUsers = await userManager.getAllUsers();
  
  console.log("\n📊 Estadísticas del UserManager:");
  console.log("   - Total de miembros registrados:", totalMembers.toString());
  console.log("   - Usuarios en el array:", allUsers.length.toString());
  
  const deploymentInfo = {
    contractName: "SimpleUserManager",
    contractAddress: userManagerAddress,
    deployer: deployer.address,
    network: "polkadotHubTestnet",
    timestamp: new Date().toISOString(),
    constructorArgs: {},
    features: {
      userRegistration: "Permite a los usuarios registrarse con información personal",
      userManagement: "Gestión completa de perfiles de usuario",
      socialLinks: "Soporte para enlaces de Twitter, GitHub y Telegram",
      avatarSupport: "Soporte para avatares e imágenes de portada",
      userRemoval: "Los usuarios pueden eliminar su cuenta"
    }
  };

  console.log("\n💾 Información del despliegue guardada:");
  console.log(JSON.stringify(deploymentInfo, null, 2));
  
  console.log("\n📋 Para usar el SimpleUserManager:");
  console.log("1. Conecta el contrato SimpleUserManager a la dirección:", userManagerAddress);
  console.log("2. Los usuarios pueden registrarse llamando a registerUser() con:");
  console.log("   - username: nombre de usuario");
  console.log("   - email: correo electrónico");
  console.log("   - twitterLink: enlace de Twitter");
  console.log("   - githubLink: enlace de GitHub");
  console.log("   - telegramLink: enlace de Telegram");
  console.log("   - avatarLink: enlace del avatar");
  console.log("   - coverImageLink: enlace de la imagen de portada");
  console.log("3. Los usuarios pueden actualizar su información con updateUserInfo()");
  console.log("4. Los usuarios pueden eliminar su cuenta con removeUser()");
  console.log("5. Consultar información con getUserInfo() y getAllUsers()");
  
  console.log("\n🎉 ¡Despliegue completado exitosamente!");
  console.log("💡 Próximos pasos:");
  console.log("   1. Verifica el contrato en el explorer");
  console.log("   2. Integra el UserManager con tu frontend");
  console.log("   3. Implementa formularios de registro y perfil");
  console.log("   4. Conecta con otros contratos del ecosistema");
  console.log("   5. Prueba todas las funcionalidades de gestión de usuarios");
  
  return {
    userManager,
    userManagerAddress,
    deployer: deployer.address
  };
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error durante el despliegue:", error);
    process.exit(1);
  });

export default main;
