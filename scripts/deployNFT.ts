import { network } from "hardhat";

async function main() {
  console.log("🚀 Iniciando despliegue del contrato SimpleNFT...");

  const { ethers } = await network.connect();
  const [deployer] = await ethers.getSigners();
  console.log("📝 Desplegando con la cuenta:", deployer.address);
  console.log("💰 Balance de la cuenta:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");

  const contractName = "SimpleNFT";
  const nftName = "Simple NFT Collection";
  const nftSymbol = "SNFT";
  const baseURI = "https://baeza.me/static/nft/polka/metadata.json";

  console.log("📋 Parámetros del contrato:");
  console.log("   - Nombre:", nftName);
  console.log("   - Símbolo:", nftSymbol);
  console.log("   - URI Base:", baseURI);

  const SimpleNFTFactory = await ethers.getContractFactory(contractName);

  console.log("⏳ Desplegando contrato...");
  const simpleNFT = await SimpleNFTFactory.deploy(nftName, nftSymbol, baseURI);

  await simpleNFT.waitForDeployment();
  const contractAddress = await simpleNFT.getAddress();

  console.log("✅ Contrato desplegado exitosamente!");
  console.log("📍 Dirección del contrato:", contractAddress);
  console.log("🔗 Explorer (Polkadot Hub Testnet):", `https://polkadot-hub-testnet.subscan.io/account/${contractAddress}`);

  console.log("\n📊 Información del contrato desplegado:");
  console.log("   - Nombre:", await simpleNFT.name());
  console.log("   - Símbolo:", await simpleNFT.symbol());
  console.log("   - Precio de mint:", ethers.formatEther(await simpleNFT.MINT_PRICE()), "ETH");
  console.log("   - Total supply actual:", await simpleNFT.totalSupply());
  console.log("   - Siguiente token ID:", await simpleNFT.nextTokenId());

  const deploymentInfo = {
    contractName,
    contractAddress,
    deployer: deployer.address,
    network: "polkadotHubTestnet",
    timestamp: new Date().toISOString(),
    constructorArgs: {
      name: nftName,
      symbol: nftSymbol,
      baseURI: baseURI
    }
  };

  console.log("\n💾 Información del despliegue guardada:");
  console.log(JSON.stringify(deploymentInfo, null, 2));

  console.log("\n🎉 ¡Despliegue completado exitosamente!");
  console.log("💡 Próximos pasos:");
  console.log("   1. Verifica el contrato en el explorer");
  console.log("   2. Configura tu API de metadatos");
  console.log("   3. Actualiza la URI base si es necesario");
  console.log("   4. Prueba las funciones de mint");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error durante el despliegue:", error);
    process.exit(1);
  });
