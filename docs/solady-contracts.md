# Biblioteca Solady - Contratos Disponibles

Solady es una colección de fragmentos de Solidity optimizados para gas diseñados para mejorar la eficiencia de los contratos inteligentes. Los contratos disponibles están organizados en varias categorías:

## **Cuentas (Accounts)**

### Receiver
- **Descripción**: Mixin para manejar ETH y tokens ERC721/ERC1155 transferidos de forma segura
- **Uso**: Implementa funciones de callback para recibir tokens de forma segura

### ERC1271
- **Descripción**: Implementación del estándar ERC1271 con enfoque EIP-712 anidado
- **Uso**: Permite la validación de firmas para contratos que actúan como cuentas

### ERC4337
- **Descripción**: Implementación simple del estándar de cuenta ERC4337
- **Uso**: Cuentas abstractas con funcionalidad de billetera inteligente

### ERC4337Factory
- **Descripción**: Contrato factory para desplegar cuentas ERC4337
- **Uso**: Creación determinística de cuentas ERC4337

### ERC6551
- **Descripción**: Implementación del estándar de cuenta ERC6551
- **Uso**: Cuentas asociadas a NFTs (Token Bound Accounts)

### ERC6551Proxy
- **Descripción**: Proxy de relay para cuentas ERC6551 actualizables
- **Uso**: Permite actualizaciones de implementación para cuentas ERC6551

## **Autorización (Authorization)**

### Ownable
- **Descripción**: Mixin que proporciona autorización de propietario único
- **Uso**: Control de acceso básico con un solo propietario

### OwnableRoles
- **Descripción**: Mixin que soporta autorización de propietario único y múltiples roles
- **Uso**: Sistema de permisos más granular con roles específicos

## **Tokens**

### WETH
- **Descripción**: Implementación de Wrapped Ether
- **Uso**: Token ERC20 que representa ETH

### ERC20
- **Descripción**: Token ERC20 con funcionalidad permit EIP-2612
- **Uso**: Token fungible estándar con aprobaciones de gas

### ERC4626
- **Descripción**: Implementación de bóveda tokenizada siguiendo el estándar ERC4626
- **Uso**: Vaults que generan yield con tokens de participación

### ERC721
- **Descripción**: Token ERC721 con storage hitchhiking para eficiencia de gas
- **Uso**: NFTs optimizados para gas

### ERC2981
- **Descripción**: Implementación del estándar de regalías NFT ERC2981
- **Uso**: Sistema de regalías para NFTs

### ERC1155
- **Descripción**: Implementación del estándar multi-token
- **Uso**: Tokens que pueden representar múltiples tipos de activos

### ERC6909
- **Descripción**: Implementación mínima multi-token siguiendo EIP-6909
- **Uso**: Sistema de tokens múltiples optimizado

## **Utilidades (Utilities)**

### MerkleProofLib
- **Descripción**: Biblioteca para verificar pruebas Merkle
- **Uso**: Verificación eficiente de membresía en árboles Merkle

### SignatureCheckerLib
- **Descripción**: Biblioteca para verificar firmas ECDSA y ERC1271
- **Uso**: Validación unificada de diferentes tipos de firmas

### ECDSA
- **Descripción**: Biblioteca para verificación de firmas ECDSA
- **Uso**: Operaciones criptográficas de curva elíptica

### EIP712
- **Descripción**: Contrato para hashing y firma de datos estructurados EIP-712
- **Uso**: Firma de mensajes estructurados para mejor UX

### ERC1967Factory
- **Descripción**: Factory para desplegar y gestionar contratos proxy ERC1967
- **Uso**: Creación de proxies para contratos actualizables

### ERC1967FactoryConstants
- **Descripción**: Contiene la dirección y bytecode del ERC1967Factory canónico
- **Uso**: Referencias a la implementación estándar

### JSONParserLib
- **Descripción**: Biblioteca para parsear datos JSON
- **Uso**: Procesamiento de datos JSON en contratos

### LibSort
- **Descripción**: Biblioteca para ordenamiento eficiente de arrays en memoria
- **Uso**: Algoritmos de ordenamiento optimizados para gas

### LibPRNG
- **Descripción**: Biblioteca para generar números pseudoaleatorios
- **Uso**: Generación de aleatoriedad en contratos

### Base64
- **Descripción**: Biblioteca para codificación y decodificación Base64
- **Uso**: Codificación de datos para transmisión

### SSTORE2
- **Descripción**: Biblioteca para operaciones de almacenamiento persistente costo-efectivas
- **Uso**: Almacenamiento optimizado de datos grandes

### CREATE3
- **Descripción**: Desplegar contratos a direcciones determinísticas sin factor initcode
- **Uso**: Despliegue predecible de contratos

### LibRLP
- **Descripción**: Biblioteca para calcular direcciones de contratos desde deployer y nonce
- **Uso**: Cálculo de direcciones de contratos

### LibBit
- **Descripción**: Biblioteca para manipulación de bits y operaciones booleanas
- **Uso**: Operaciones eficientes a nivel de bits

### LibZip
- **Descripción**: Biblioteca para comprimir y descomprimir datos de bytes
- **Uso**: Compresión de datos para ahorrar gas

### Clone
- **Descripción**: Clase con funciones helper para clones con argumentos inmutables
- **Uso**: Creación de contratos clonados con parámetros fijos

### LibClone
- **Descripción**: Biblioteca de proxy mínimal
- **Uso**: Implementación de proxies de delegación

### Initializable
- **Descripción**: Mixin para inicialización de contratos actualizables
- **Uso**: Patrón de inicialización para contratos proxy

### UUPSUpgradeable
- **Descripción**: Mixin para patrón de proxy UUPS
- **Uso**: Actualizaciones de contratos a través del patrón UUPS

### LibString
- **Descripción**: Biblioteca para operaciones de strings, incluyendo conversiones número-a-string
- **Uso**: Manipulación eficiente de strings

### LibBitmap
- **Descripción**: Biblioteca para gestionar almacenamiento booleano empaquetado
- **Uso**: Almacenamiento eficiente de flags booleanos

### LibMap
- **Descripción**: Biblioteca para gestionar almacenamiento de enteros sin signo empaquetados
- **Uso**: Almacenamiento optimizado de mapeos

### MinHeapLib
- **Descripción**: Biblioteca para gestionar un min-heap en storage o memoria
- **Uso**: Estructuras de datos de cola de prioridad

### RedBlackTreeLib
- **Descripción**: Biblioteca para gestionar un árbol rojo-negro en storage
- **Uso**: Estructuras de datos de árbol balanceado

### ReentrancyGuard
- **Descripción**: Mixin para prevenir llamadas reentrantes
- **Uso**: Protección contra ataques de reentrancia

### Multicallable
- **Descripción**: Contrato que permite múltiples llamadas de método en una sola transacción
- **Uso**: Agregación de múltiples operaciones

### GasBurnerLib
- **Descripción**: Biblioteca para quemar gas sin causar reversiones
- **Uso**: Consumo controlado de gas

### SafeTransferLib
- **Descripción**: Biblioteca para transferencias seguras de ETH y tokens ERC20
- **Uso**: Transferencias que manejan valores de retorno faltantes

### DynamicBufferLib
- **Descripción**: Biblioteca para buffers con redimensionamiento automático de capacidad
- **Uso**: Almacenamiento dinámico de datos

### MetadataReaderLib
- **Descripción**: Biblioteca para leer metadatos de contratos de forma robusta
- **Uso**: Lectura segura de metadatos de contratos

### FixedPointMathLib
- **Descripción**: Biblioteca para operaciones aritméticas de punto fijo
- **Uso**: Matemáticas de precisión fija para evitar overflow

### SafeCastLib
- **Descripción**: Biblioteca para casting seguro de enteros, revirtiendo en overflow
- **Uso**: Conversiones seguras entre tipos numéricos

### DateTimeLib
- **Descripción**: Biblioteca para operaciones de fecha y hora
- **Uso**: Manipulación de timestamps y fechas

## **Instalación**

### Con npm (Hardhat/Truffle):
```bash
npm install solady
```

### Con Foundry:
```bash
forge install vectorized/solady
```

## **Ubicación**
Todos estos contratos están ubicados en el directorio `src` del repositorio Solady y están optimizados para minimizar el consumo de gas.

## **Enlaces Útiles**
- [Repositorio GitHub](https://github.com/vectorized/solady)
- [Documentación](https://github.com/vectorized/solady/blob/main/docs/overview.md)
- [NPM Package](https://www.npmjs.com/package/solady)
