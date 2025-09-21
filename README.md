# Proyecto Hardhat 3 Beta (`mocha` y `ethers`)

Este proyecto demuestra las capacidades de Hardhat 3 Beta utilizando `mocha` para las pruebas y la librería `ethers` para las interacciones con Ethereum.

Para aprender más sobre Hardhat 3 Beta, visita la [guía de inicio](https://hardhat.org/docs/getting-started#getting-started-with-hardhat-3). Para compartir tu feedback, únete a nuestro [grupo de Telegram de Hardhat 3 Beta](https://hardhat.org/hardhat3-beta-telegram-group) o [abre un issue](https://github.com/NomicFoundation/hardhat/issues/new) en nuestro tracker de GitHub.

## Descripción del Proyecto

Este proyecto de ejemplo incluye:

- Un archivo de configuración de Hardhat simple
- **Contrato SimpleNFT**: Un contrato ERC721 completo con funcionalidades de mint individual y batch
- Pruebas unitarias de Solidity compatibles con Foundry
- Pruebas de integración en TypeScript usando `mocha` y ethers.js
- Ejemplos que demuestran cómo conectarse a diferentes tipos de redes, incluyendo simulación local de OP mainnet

## Comandos Útiles de Hardhat

### Ejecutar un Nodo Local

Para iniciar un nodo local de Hardhat que simula la blockchain de Ethereum:

```shell
npx hardhat node
```

Este comando iniciará un nodo local en `http://127.0.0.1:8545` con 20 cuentas prefinanciadas que puedes usar para desarrollo y pruebas.

### Compilar Contratos

Para compilar todos los contratos del proyecto:

```shell
npx hardhat compile
```

Si quieres forzar una recompilación completa:

```shell
npx hardhat compile --force
```

### Ejecutar Pruebas

Para ejecutar todas las pruebas del proyecto:

```shell
npx hardhat test
```

También puedes ejecutar selectivamente las pruebas de Solidity o las de `mocha`:

```shell
npx hardhat test solidity
npx hardhat test mocha
```

Para ejecutar pruebas con más detalle (verbose):

```shell
npx hardhat test --verbose
```

### Tests del Contrato SimpleNFT

Este proyecto incluye tests completos para el contrato SimpleNFT:

#### Tests en Solidity
```shell
# Ejecutar solo los tests de Solidity
npx hardhat test solidity

# Ejecutar un archivo específico
npx hardhat test test/SimpleNFT.sol
```

Los tests de Solidity incluyen:
- ✅ **15 tests unitarios** que cubren todas las funcionalidades
- ✅ **1 test de fuzz** (256 ejecuciones) para validaciones robustas
- ✅ Validaciones de pago y parámetros
- ✅ Tests de funciones de utilidad
- ✅ Tests de integración

#### Tests en TypeScript
```shell
# Ejecutar solo los tests de TypeScript
npx hardhat test nodejs

# Ejecutar archivo específico
npx hardhat test test/SimpleNFT.test.ts
```

Los tests de TypeScript incluyen:
- ✅ **27 tests de integración** con cobertura completa
- ✅ Tests de eventos y emisiones
- ✅ Tests de múltiples usuarios
- ✅ Reportes de uso de gas
- ✅ Tests de flujos completos

#### Funcionalidades Testadas

**Contrato SimpleNFT:**
- ✅ Mint individual con validación de pago
- ✅ Mint batch con validación de cantidad y pago
- ✅ Gestión de URI base y tokens
- ✅ Funciones de utilidad (totalSupply, nextTokenId, exists)
- ✅ Transferencias de fondos al deployer
- ✅ Eventos TokenMinted
- ✅ Validaciones de seguridad y parámetros

**Comandos específicos para SimpleNFT:**
```shell
# Compilar el contrato
npx hardhat compile

# Ejecutar todos los tests del proyecto
npx hardhat test

# Ejecutar solo tests de Solidity (SimpleNFT incluido)
npx hardhat test solidity

# Ejecutar solo tests de TypeScript
npx hardhat test test/SimpleNFT.test.ts

# Verificar cobertura de tests
npx hardhat test --verbose
```

### Limpiar Artefactos

Para limpiar los archivos de compilación y caché:

```shell
npx hardhat clean
```

### Verificar Contratos

Para verificar contratos en Etherscan (requiere configuración de API key):

```shell
npx hardhat verify --network sepolia <DIRECCIÓN_DEL_CONTRATO>
```

### Consola Interactiva

Para abrir una consola interactiva de Hardhat:

```shell
npx hardhat console --network localhost
```

### Desplegar Contratos

Este proyecto incluye un módulo de Ignition de ejemplo para desplegar contratos. Puedes desplegar este módulo a una cadena simulada localmente o a Sepolia.

Para ejecutar el despliegue en una cadena local:

```shell
npx hardhat ignition deploy ignition/modules/Counter.ts
```

Para desplegar en Sepolia, necesitas una cuenta con fondos para enviar la transacción. La configuración de Hardhat incluye una Variable de Configuración llamada `SEPOLIA_PRIVATE_KEY`, que puedes usar para establecer la clave privada de la cuenta que quieres usar.

Puedes establecer la variable `SEPOLIA_PRIVATE_KEY` usando el plugin `hardhat-keystore` o estableciéndola como variable de entorno.

Para establecer la variable de configuración `SEPOLIA_PRIVATE_KEY` usando `hardhat-keystore`:

```shell
npx hardhat keystore set SEPOLIA_PRIVATE_KEY
```

Después de establecer la variable, puedes ejecutar el despliegue con la red de Sepolia:

```shell
npx hardhat ignition deploy --network sepolia ignition/modules/Counter.ts
```

### Desplegar el Contrato SimpleNFT

Para desplegar el contrato SimpleNFT, puedes crear un script de despliegue personalizado:

```shell
# Crear un script de despliegue
npx hardhat run scripts/deploy-simple-nft.ts --network localhost
```

O usar un módulo de Ignition personalizado para el contrato SimpleNFT. El contrato requiere los siguientes parámetros:
- `name`: Nombre del NFT (ej: "Mi NFT")
- `symbol`: Símbolo del NFT (ej: "MNFT") 
- `baseURI`: URI base para los metadatos (ej: "https://api.ejemplo.com/metadata/")

**Configuración para Polkadot Hub Testnet:**
```shell
# Establecer clave privada para Polkadot Hub
npx hardhat keystore set POLKADOT_HUB_PRIVATE_KEY

# Desplegar en Polkadot Hub Testnet
npx hardhat ignition deploy --network polkadotHubTestnet ignition/modules/SimpleNFT.ts
```

### Comandos de Red

Para ver información sobre las redes configuradas:

```shell
npx hardhat run --help
```

Para ejecutar un script en una red específica:

```shell
npx hardhat run scripts/mi-script.ts --network localhost
```

### Comandos de Ayuda

Para ver todos los comandos disponibles:

```shell
npx hardhat help
```

Para obtener ayuda sobre un comando específico:

```shell
npx hardhat help <comando>
```

## Configuración de Redes

El proyecto está configurado con las siguientes redes:

- **hardhatMainnet**: Simulación local de L1 mainnet
- **hardhatOp**: Simulación local de Optimism
- **sepolia**: Red de prueba de Sepolia (requiere configuración de variables)

## Desarrollo Local

1. Inicia un nodo local: `npx hardhat node`
2. En otra terminal, compila los contratos: `npx hardhat compile`
3. Ejecuta las pruebas: `npx hardhat test`
4. Despliega en local: `npx hardhat ignition deploy ignition/modules/Counter.ts`
