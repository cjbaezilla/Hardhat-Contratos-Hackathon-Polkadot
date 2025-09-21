# Documentación de Pruebas del Contrato SimpleNFT

## Introducción

Este documento proporciona una descripción detallada y exhaustiva de las pruebas implementadas para el contrato `SimpleNFT`. El proyecto incluye dos enfoques de testing complementarios: pruebas en Solidity usando Foundry y pruebas en TypeScript usando Hardhat.

## Estructura General de las Pruebas

### Archivos de Pruebas

| Archivo | Tecnología | Framework | Propósito |
|---------|------------|-----------|-----------|
| `test/SimpleNFT.sol` | Solidity | Foundry | Pruebas unitarias y de integración |
| `test/SimpleNFT.test.ts` | TypeScript | Hardhat + Chai | Pruebas funcionales y de comportamiento |

### Configuración Inicial

#### Variables de Entorno de Prueba

```solidity
string constant NAME = "Test NFT";
string constant SYMBOL = "TNFT"; 
string constant BASE_URI = "https://api.example.com/metadata/";
```

#### Direcciones de Prueba

- **Deployer**: `address(this)` - Contrato de prueba
- **User1**: Dirección generada con `makeAddr("user1")`
- **User2**: Dirección generada con `makeAddr("user2")`

#### Financiamiento Inicial

Cada dirección de prueba recibe **10 ether** para realizar transacciones durante las pruebas.

## Análisis Detallado de Pruebas en Solidity (Foundry)

### 1. Pruebas del Constructor

Las pruebas del constructor verifican la inicialización correcta del contrato:

| Función | Verificación | Valor Esperado |
|---------|--------------|----------------|
| `test_Constructor()` | Nombre del NFT | "Test NFT" |
| | Símbolo del NFT | "TNFT" |
| | Total Supply inicial | 0 |
| | Next Token ID inicial | 1 |
| | Precio de mint | 1 ether |

**Propósito**: Garantizar que el contrato se despliega con los parámetros correctos y en el estado inicial esperado.

### 2. Pruebas de Validación de Pago

#### Mint Individual - Validaciones de Pago

| Caso de Prueba | Descripción | Pago Enviado | Resultado Esperado |
|----------------|-------------|--------------|-------------------|
| `test_MintInsufficientPayment` | Pago insuficiente | 1 ether - 1 wei | Revertir con mensaje específico |
| `test_MintExcessivePayment` | Pago excesivo | 1 ether + 1 wei | Revertir con mensaje específico |
| `test_MintWithoutPayment` | Sin pago | 0 wei | Revertir con mensaje específico |

**Mensaje de Error**: "Debe enviar exactamente 1 PES para mintear"

#### Mint Batch - Validaciones de Pago

| Caso de Prueba | Descripción | Cantidad | Pago Enviado | Resultado Esperado |
|----------------|-------------|----------|--------------|-------------------|
| `test_MintBatchZeroQuantity` | Cantidad cero | 0 | 0 wei | Revertir |
| `test_MintBatchInsufficientPayment` | Pago insuficiente | 3 | 3 ether - 1 wei | Revertir |
| `test_MintBatchExcessivePayment` | Pago excesivo | 2 | 2 ether + 1 wei | Revertir |

**Mensaje de Error**: "Debe enviar el precio correcto para la cantidad"

### 3. Gestión de URIs

#### Funcionalidades de URI

| Función | Propósito | Validaciones |
|---------|-----------|--------------|
| `test_SetEmptyBaseURI` | Establecer URI vacía | Revertir si está vacía |
| `test_SetBaseURI` | Cambiar URI base | Verificar actualización |
| `test_GetBaseURI` | Obtener URI actual | Verificar valor inicial |

#### Comportamiento de TokenURI

| Caso de Prueba | Descripción | Resultado Esperado |
|----------------|-------------|-------------------|
| `test_TokenURIReturnsBaseURI` | URI para token existente | Retornar BASE_URI |
| `test_AllTokensSameURI` | URI para múltiples tokens | Todos retornan BASE_URI |
| `test_TokenURIAfterBaseURIChange` | URI después de cambio | Retornar nueva URI |

### 4. Funciones de Utilidad

#### Estado del Contrato

| Función | Verificación | Estado Inicial | Estado Después |
|---------|--------------|----------------|----------------|
| `test_TotalSupplyInitial` | Total supply inicial | 0 | - |
| `test_NextTokenIdInitial` | Next token ID inicial | 1 | - |
| `test_ExistsNonExistentToken` | Existencia de tokens | false | - |
| `test_MintPriceConstant` | Precio constante | 1 ether | 1 ether |

### 5. Array de Holders (nftHolders)

El array `nftHolders` mantiene un registro de todos los usuarios que han minteado tokens:

#### Casos de Prueba del Array

| Función | Descripción | Estado del Array | Verificaciones |
|---------|-------------|------------------|----------------|
| `test_NFTHoldersArrayInitial` | Array inicial | Vacío | Revertir al acceder |
| `test_NFTHoldersArrayAfterMint` | Después de mint individual | [user1] | user1 en índice 0 |
| `test_NFTHoldersArrayAfterMultipleMints` | Múltiples mints | [user1, user2] | Ambos usuarios registrados |
| `test_NFTHoldersArrayAfterMintBatch` | Después de mint batch | [user1, user1, user1] | Múltiples entradas para mismo usuario |
| `test_NFTHoldersArrayMixedMints` | Mints mixtos | [user1, user2, user2, user1] | Orden correcto |

### 6. Pruebas de Mint Batch

#### Casos Específicos de Batch

| Función | Cantidad | Descripción | Verificaciones |
|---------|----------|-------------|----------------|
| `test_MintBatchSingleToken` | 1 | Mint batch de un token | Mismo comportamiento que mint individual |
| `test_MintBatchLargeQuantity` | 100 | Mint batch grande | Verificar todos los tokens |
| `testFuzz_MintBatchValidation` | 0 (fuzz) | Validación de cantidad cero | Revertir siempre |

### 7. Pruebas de Casos Límite

#### Casos Extremos

| Función | Caso | Descripción | Resultado |
|---------|------|-------------|-----------|
| `test_ExistsWithZeroTokenId` | Token ID 0 | Verificar existencia | false |
| `test_ExistsWithMaxTokenId` | Token ID máximo | Verificar existencia | false |
| `test_TokenURIWithZeroTokenId` | URI de token 0 | Consultar URI | Revertir |
| `test_TokenURIWithMaxTokenId` | URI de token máximo | Consultar URI | Revertir |

#### URIs Especiales

| Función | Tipo de URI | Descripción |
|---------|-------------|-------------|
| `test_SetBaseURIWithLongString` | URI muy larga | Probar límites de longitud |
| `test_SetBaseURIWithSpecialCharacters` | URI con caracteres especiales | Probar URL encoding |

### 8. Pruebas de Integración

#### Flujo Completo

La función `test_CompleteIntegrationFlow` simula un escenario real:

1. **Mint individual** por user1
2. **Mint batch** de 3 tokens por user2  
3. **Cambio de URI** base
4. **Mint adicional** por user1

**Verificaciones Finales**:
- Total supply: 5
- Next token ID: 6
- Ownerships correctos
- URIs actualizadas
- Array nftHolders correcto

### 9. Pruebas de Gas

#### Medición de Consumo

| Función | Operación | Propósito |
|---------|-----------|-----------|
| `test_GasUsageMintIndividual` | Mint individual | Medir gas base |
| `test_GasUsageMintBatch` | Mint batch (5 tokens) | Medir gas por lote |

**Emisión de Logs**: Los tests emiten logs con el gas consumido para análisis de rendimiento.

### 10. Pruebas Fuzz

#### Testing Aleatorio

| Función | Parámetro | Rango | Propósito |
|---------|-----------|-------|-----------|
| `testFuzz_MintBatchValidation` | quantity | 0 | Validar cantidad cero |
| `testFuzz_MintBatchQuantity` | quantity | 1-1000 | Probar cantidades aleatorias |
| `testFuzz_ExistsFunction` | tokenId | 1-50 | Probar existencia aleatoria |

### 11. Pruebas de Eventos

#### Emisión de Eventos

| Función | Evento | Parámetros Verificados |
|---------|--------|----------------------|
| `test_TokenMintedEventParameters` | TokenMinted | to, tokenId, price |
| `test_TokenMintedEventsInBatch` | TokenMinted (múltiples) | Todos los tokens del batch |

## Análisis Detallado de Pruebas en TypeScript (Hardhat)

### 1. Configuración y Setup

#### Configuración Inicial

```typescript
const NAME = "Test NFT";
const SYMBOL = "TNFT";
const BASE_URI = "https://api.example.com/metadata/";
const MINT_PRICE = 1000000000000000000n; // 1 ether
```

#### Hook de Configuración

```typescript
beforeEach(async function () {
  const { ethers } = await network.connect();
  [deployer, user1, user2] = await ethers.getSigners();
  
  const SimpleNFTFactory = await ethers.getContractFactory("SimpleNFT");
  nft = await SimpleNFTFactory.deploy(NAME, SYMBOL, BASE_URI);
  await nft.waitForDeployment();
});
```

### 2. Pruebas del Constructor

#### Verificaciones de Inicialización

| Prueba | Verificación | Valor Esperado |
|--------|--------------|----------------|
| "Debería establecer el nombre correctamente" | `nft.name()` | "Test NFT" |
| "Debería establecer el símbolo correctamente" | `nft.symbol()` | "TNFT" |
| "Debería tener totalSupply inicial de 0" | `nft.totalSupply()` | 0 |
| "Debería tener nextTokenId inicial de 1" | `nft.nextTokenId()` | 1 |
| "Debería tener MINT_PRICE de 1 ether" | `nft.MINT_PRICE()` | 1 ether |

### 3. Pruebas de Mint Individual

#### Casos de Éxito

| Prueba | Descripción | Verificaciones |
|--------|-------------|----------------|
| "Debería permitir mint con pago correcto" | Mint con pago exacto | - Receipt no nulo<br>- Ownership correcto<br>- Total supply = 1<br>- Next token ID = 2<br>- Token existe |
| "Debería emitir evento TokenMinted" | Verificar emisión de evento | - Evento emitido<br>- Parámetros correctos |

#### Casos de Error

| Prueba | Descripción | Pago | Error Esperado |
|--------|-------------|------|----------------|
| "Debería revertir con pago insuficiente" | Pago menor al requerido | MINT_PRICE - 1 | "Debe enviar exactamente 1 PES para mintear" |
| "Debería revertir con pago excesivo" | Pago mayor al requerido | MINT_PRICE + 1 | "Debe enviar exactamente 1 PES para mintear" |
| "Debería revertir sin pago" | Sin pago | 0 | "Debe enviar exactamente 1 PES para mintear" |

### 4. Pruebas de Mint Batch

#### Casos de Éxito

| Prueba | Cantidad | Verificaciones |
|--------|----------|----------------|
| "Debería permitir mint batch con pago correcto" | 5 | - Total supply = 5<br>- Next token ID = 6<br>- Ownerships correctos<br>- Todos existen |

#### Casos de Error

| Prueba | Cantidad | Pago | Error Esperado |
|--------|----------|------|----------------|
| "Debería revertir con cantidad 0" | 0 | 0 | "La cantidad debe ser mayor a 0" |
| "Debería revertir con pago insuficiente" | 3 | 3 ether - 1 | "Debe enviar el precio correcto para la cantidad" |
| "Debería revertir con pago excesivo" | 2 | 2 ether + 1 | "Debe enviar el precio correcto para la cantidad" |

### 5. Pruebas de Múltiples Mints

#### Escenarios Mixtos

| Prueba | Secuencia | Resultado Esperado |
|--------|-----------|-------------------|
| "Debería permitir múltiples mints de diferentes usuarios" | user1 mint → user2 mint | - Token 1: user1<br>- Token 2: user2<br>- Total: 2 |
| "Debería permitir combinación de mint individual y batch" | user1 mint → user2 batch(3) | - Total: 4<br>- Next ID: 5<br>- Ownerships correctos |

### 6. Gestión de URIs

#### Funcionalidades de URI

| Prueba | Descripción | Verificaciones |
|--------|-------------|----------------|
| "Debería retornar URI base para token existente" | Consultar URI de token 1 | BASE_URI |
| "Debería retornar getBaseURI correctamente" | Obtener URI base | BASE_URI |
| "Debería permitir cambiar baseURI y afectar todos los tokens" | Cambiar URI → mint | Nueva URI aplicada |
| "Debería retornar la misma URI para todos los tokens" | Múltiples mints | Todas las URIs iguales |

#### Casos de Error

| Prueba | Descripción | Error Esperado |
|--------|-------------|----------------|
| "Debería revertir al establecer URI vacía" | setBaseURI("") | "La URI base no puede estar vacia" |
| "Debería revertir al consultar URI de token inexistente" | tokenURI(999) | ERC721NonexistentToken |

### 7. Funciones de Utilidad

#### Actualización de Estado

| Prueba | Operación | Verificaciones |
|--------|-----------|----------------|
| "Debería actualizar totalSupply correctamente" | Mints secuenciales | 0 → 1 → 4 |
| "Debería actualizar nextTokenId correctamente" | Mints secuenciales | 1 → 2 → 4 |
| "Debería retornar correctamente si token existe" | Mint → consultas | false → true |

### 8. Pruebas del Array nftHolders

#### Comportamiento del Array

| Prueba | Estado | Verificaciones |
|--------|--------|----------------|
| "Debería tener array vacío inicialmente" | Inicial | Revertir al acceder |
| "Debería agregar holder después de mint individual" | [user1] | user1 en índice 0 |
| "Debería agregar múltiples holders con mints separados" | [user1, user2] | Ambos usuarios registrados |
| "Debería agregar múltiples entradas para mint batch" | [user1, user1, user1] | Múltiples entradas |
| "Debería manejar correctamente mints mixtos" | [user1, user2, user2, user1] | Orden correcto |

### 9. Pruebas de Rendimiento

#### Medición de Gas

| Prueba | Operación | Método de Medición |
|--------|-----------|-------------------|
| "Debería reportar uso de gas para mint individual" | Mint individual | `receipt.gasUsed` |
| "Debería reportar uso de gas para mint batch" | Mint batch (5 tokens) | `receipt.gasUsed` |
| "Debería reportar gas para cambio de URI" | setBaseURI | `receipt.gasUsed` |

### 10. Pruebas de Eventos Detalladas

#### Verificación de Eventos

| Prueba | Evento | Parámetros |
|--------|--------|------------|
| "Debería emitir TokenMinted con parámetros correctos" | TokenMinted | to, tokenId, price |
| "Debería emitir múltiples eventos TokenMinted en batch" | TokenMinted (3x) | Todos los tokens |
| "Debería emitir eventos para diferentes usuarios" | TokenMinted (2x) | Diferentes usuarios |

### 11. Pruebas de Stress

#### Carga de Trabajo

| Prueba | Operación | Cantidad | Verificaciones |
|--------|-----------|----------|----------------|
| "Debería manejar muchos mints individuales secuenciales" | Mints individuales | 20 | Todos correctos |
| "Debería manejar múltiples mints batch grandes" | Mints batch | 5 × 10 tokens | 50 tokens total |

### 12. Casos Límite y Edge Cases

#### Casos Extremos

| Prueba | Caso | Descripción |
|--------|------|-------------|
| "Debería manejar mint batch de un solo token" | Cantidad 1 | Equivalente a mint individual |
| "Debería manejar mint batch de cantidad grande" | Cantidad 50 | Probar límites |
| "Debería retornar false para exists con tokenId 0" | Token ID 0 | Validación de límites |
| "Debería retornar false para exists con tokenId muy grande" | Token ID máximo | Validación de límites |

#### URIs Especiales

| Prueba | Tipo de URI | Propósito |
|--------|-------------|-----------|
| "Debería manejar URI con caracteres especiales" | URL con encoding | Probar caracteres especiales |
| "Debería manejar URI muy larga" | URI extensa | Probar límites de longitud |

### 13. Pruebas de Integración Avanzadas

#### Flujos Complejos

| Prueba | Descripción | Secuencia |
|--------|-------------|-----------|
| "Debería manejar flujo completo de integración" | Escenario completo | Mint → Batch → URI → Mint |
| "Debería manejar múltiples cambios de URI con tokens existentes" | Cambios de URI | Mint → URI1 → URI2 → URI3 → Mint |

## Comparación entre Enfoques de Testing

### Foundry vs Hardhat

| Aspecto | Foundry (Solidity) | Hardhat (TypeScript) |
|---------|-------------------|---------------------|
| **Velocidad** | Muy rápida | Moderada |
| **Gas** | Medición nativa | Medición vía receipt |
| **Fuzzing** | Nativo | Limitado |
| **Debugging** | Trazas detalladas | Logs de consola |
| **Setup** | Más simple | Más configuración |
| **Integración** | Mejor con contratos | Mejor con frontend |

### Cobertura de Pruebas

#### Pruebas Exclusivas de Foundry

- Pruebas fuzz avanzadas
- Medición precisa de gas
- Pruebas de casos límite extremos
- Validaciones de eventos detalladas

#### Pruebas Exclusivas de Hardhat

- Pruebas de integración con signers reales
- Pruebas de stress con cantidades grandes
- Verificación de transferencias de fondos
- Pruebas de comportamiento de usuario

## Métricas y Estadísticas

### Cobertura de Funcionalidades

| Funcionalidad | Foundry | Hardhat | Cobertura |
|---------------|---------|---------|-----------|
| Constructor | ✅ | ✅ | 100% |
| Mint Individual | ✅ | ✅ | 100% |
| Mint Batch | ✅ | ✅ | 100% |
| Validaciones de Pago | ✅ | ✅ | 100% |
| Gestión de URIs | ✅ | ✅ | 100% |
| Array nftHolders | ✅ | ✅ | 100% |
| Funciones de Utilidad | ✅ | ✅ | 100% |
| Casos Límite | ✅ | ✅ | 100% |
| Eventos | ✅ | ✅ | 100% |
| Gas Usage | ✅ | ✅ | 100% |

### Cantidad de Pruebas

| Framework | Pruebas Unitarias | Pruebas de Integración | Pruebas Fuzz | Total |
|-----------|-------------------|----------------------|--------------|-------|
| Foundry | 35 | 5 | 3 | 43 |
| Hardhat | 45 | 8 | 0 | 53 |
| **Total** | **80** | **13** | **3** | **96** |

## Conclusiones y Recomendaciones

### Fortalezas del Sistema de Pruebas

1. **Cobertura Completa**: Todas las funcionalidades están cubiertas por ambos enfoques
2. **Validaciones Exhaustivas**: Casos de éxito, error y límite están cubiertos
3. **Doble Verificación**: Enfoques complementarios proporcionan mayor confianza
4. **Casos de Uso Reales**: Pruebas de integración simulan escenarios reales

### Áreas de Mejora Potencial

1. **Pruebas de Transferencia de Fondos**: Algunas están marcadas como skip
2. **Pruebas de Concurrencia**: No se prueban operaciones simultáneas
3. **Pruebas de Reentrancy**: No se valida protección contra ataques
4. **Pruebas de Límites de Gas**: No se valida comportamiento con gas limitado

### Recomendaciones

1. **Ejecutar Regularmente**: Mantener ambos conjuntos de pruebas actualizados
2. **Monitorear Gas**: Usar las métricas de gas para optimización
3. **Expandir Fuzzing**: Añadir más casos de prueba aleatorios
4. **Documentar Cambios**: Actualizar esta documentación con nuevas pruebas

## Glosario de Términos

| Término | Definición |
|---------|------------|
| **Foundry** | Framework de desarrollo de contratos inteligentes |
| **Hardhat** | Entorno de desarrollo para Ethereum |
| **Fuzzing** | Técnica de testing con entradas aleatorias |
| **Gas** | Unidad de medida para el costo de ejecución |
| **ERC721** | Estándar para tokens no fungibles |
| **Mint** | Proceso de creación de nuevos tokens |
| **URI** | Uniform Resource Identifier para metadatos |
| **Holder** | Poseedor de un token NFT |

---

*Documentación generada para el proyecto SimpleNFT - Última actualización: Diciembre 2024*
