import { network } from "hardhat";

async function main() {
  console.log("🚀 Iniciando despliegue del contrato DAO...");

  const { ethers } = await network.connect();
  const [deployer] = await ethers.getSigners();
  console.log("📝 Desplegando con la cuenta:", deployer.address);
  console.log("💰 Balance de la cuenta:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");

  const contractName = "DAO";
  
  const daoName: string = "Mi DAO Personalizado";
  const nftContractAddress: string = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const minProposalCreationTokens: number = 10;
  const minVotesToApprove: number = 10;
  const minTokensToApprove: number = 50;

  console.log("\n⏳ Desplegando contrato DAO...");
  console.log("📋 Parámetros del contrato DAO:");
  console.log("   - Nombre del DAO:", daoName);
  console.log("   - Contrato NFT:", nftContractAddress);
  console.log("   - Tokens mínimos para crear propuesta:", minProposalCreationTokens);
  console.log("   - Votos mínimos para aprobar:", minVotesToApprove);
  console.log("   - Tokens mínimos para aprobar:", minTokensToApprove);

  const DAOFactory = await ethers.getContractFactory(contractName);
  const dao = await DAOFactory.deploy(
    daoName,
    nftContractAddress,
    minProposalCreationTokens,
    minVotesToApprove,
    minTokensToApprove
  );
  
  await dao.waitForDeployment();
  const daoAddress = await dao.getAddress();

  console.log("\n✅ Contrato DAO desplegado exitosamente!");
  console.log("📍 Dirección del DAO:", daoAddress);
  console.log("🔗 Explorer (Polkadot Hub Testnet):", `https://polkadot-hub-testnet.subscan.io/account/${daoAddress}`);

  console.log("\n📊 Información del contrato DAO desplegado:");
  console.log("   - Nombre del DAO:", await dao.name());
  console.log("   - Propietario:", await dao.owner());
  console.log("   - Contrato NFT:", await dao.nftContract());
  console.log("   - Propuestas totales:", await dao.getTotalProposals());
  console.log("   - Tokens mínimos para crear propuesta:", await dao.MIN_PROPOSAL_CREATION_TOKENS());
  console.log("   - Votos mínimos para aprobar:", await dao.MIN_VOTES_TO_APPROVE());
  console.log("   - Tokens mínimos para aprobar:", await dao.MIN_TOKENS_TO_APPROVE());

  const deploymentInfo = {
    contractName,
    contractAddress: daoAddress,
    deployer: deployer.address,
    network: "polkadotHubTestnet",
    timestamp: new Date().toISOString(),
    constructorArgs: {
      name: daoName,
      nftContract: nftContractAddress,
      minProposalCreationTokens: minProposalCreationTokens,
      minVotesToApprove: minVotesToApprove,
      minTokensToApprove: minTokensToApprove
    },
    nftContract: {
      address: nftContractAddress,
      deployed: false
    }
  };

  console.log("\n💾 Información del despliegue guardada:");
  console.log(JSON.stringify(deploymentInfo, null, 2));

  console.log("\n🎉 ¡Despliegue completado exitosamente!");
  console.log("💡 Próximos pasos:");
  console.log("   1. Verifica el contrato en el explorer");
  console.log("   2. Distribuye NFTs a los miembros del DAO");
  console.log("   3. Configura los parámetros mínimos si es necesario");
  console.log("   4. Crea las primeras propuestas");
  console.log("   5. Prueba el sistema de votación");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error durante el despliegue:", error);
    process.exit(1);
  });
