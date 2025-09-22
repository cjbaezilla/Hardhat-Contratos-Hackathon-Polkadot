import { network } from "hardhat";

/**
 * Script para desplegar el contrato ERC20Factory
 * Este factory permite a los usuarios crear tokens ERC20 personalizados
 */
async function main() {
  console.log("🚀 Iniciando despliegue del ERC20Factory...");
  
  // Conectar a la red y obtener ethers
  const { ethers } = await network.connect();
  
  // Obtener el deployer
  const [deployer] = await ethers.getSigners();
  console.log("📝 Desplegando con la cuenta:", deployer.address);
  console.log("💰 Balance de la cuenta:", ethers.formatEther(await deployer.provider!.getBalance(deployer.address)), "ETH");

  // Desplegar ERC20Factory
  console.log("🏭 Desplegando ERC20Factory...");
  const ERC20Factory = await ethers.getContractFactory("ERC20Factory");
  const erc20Factory = await ERC20Factory.deploy();
  
  await erc20Factory.waitForDeployment();
  const factoryAddress = await erc20Factory.getAddress();
  
  console.log("✅ ERC20Factory desplegado exitosamente!");
  console.log("📍 Dirección del ERC20Factory:", factoryAddress);
  
  // Verificar el despliegue
  const totalTokensCreated = await erc20Factory.totalTokensCreated();
  const allTokens = await erc20Factory.getAllTokens();
  
  console.log("📊 Estadísticas del Factory:");
  console.log("   - Total de tokens creados:", totalTokensCreated.toString());
  console.log("   - Tokens en el array:", allTokens.length.toString());
  
  // Ejemplo de cómo usar el factory (opcional)
  console.log("\n📋 Para usar el ERC20Factory:");
  console.log("1. Conecta el contrato ERC20Factory a la dirección:", factoryAddress);
  console.log("2. Llama a createToken() con los parámetros necesarios:");
  console.log("   - name_: nombre del token (ej: 'Mi Token')");
  console.log("   - symbol_: símbolo del token (ej: 'MTK')");
  console.log("   - initialSupply_: suministro inicial (ej: 1000000)");
  console.log("3. El usuario que llame createToken() será el propietario del nuevo token");
  console.log("4. El token se creará automáticamente y se registrará en el factory");
  
  console.log("\n🎉 Despliegue completado!");
  
  return {
    erc20Factory,
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
