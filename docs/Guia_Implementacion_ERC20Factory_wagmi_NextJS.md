# Guía Completa: Implementación de ERC20Factory con wagmi en Next.js

## Análisis del Contrato ERC20Factory

### Funcionalidades Principales

El contrato `ERC20Factory` permite crear tokens ERC20 de forma descentralizada con las siguientes características:

- **Creación de Tokens**: Función `createToken()` que genera nuevos tokens ERC20
- **Gestión de Información**: Almacena metadatos de cada token creado
- **Consultas**: Múltiples funciones para consultar tokens por usuario o globalmente
- **Validaciones**: Verificaciones de seguridad para evitar duplicados

### Estructura de Datos

```solidity
struct TokenInfo {
    address tokenAddress;    // Dirección del token creado
    address creator;         // Dirección del creador
    string name;            // Nombre del token
    string symbol;          // Símbolo del token
    uint256 initialSupply;  // Suministro inicial
    uint256 createdAt;      // Timestamp de creación
}
```

### Funciones del Contrato

1. **createToken(name_, symbol_, initialSupply_)** - Crea un nuevo token ERC20
2. **getUserTokens(user)** - Obtiene todos los tokens de un usuario
3. **getAllTokens()** - Obtiene todos los tokens creados
4. **getUserTokenCount(user)** - Cuenta tokens de un usuario
5. **isTokenFromFactory(tokenAddress)** - Verifica si un token fue creado por esta factory

---

## Implementación con wagmi en Next.js

### Paso 1: Configuración del Proyecto

#### 1.1 Instalación de Dependencias

```bash
npm install wagmi viem @tanstack/react-query
npm install @rainbow-me/rainbowkit  # Opcional: para UI de conexión
```

#### 1.2 Configuración de wagmi

Crea `lib/wagmi.ts`:

```typescript
import { getDefaultConfig } from '@rainbow-me/rainbowkit'
import { mainnet, polygon, arbitrum, base, sepolia } from 'wagmi/chains'

export const config = getDefaultConfig({
  appName: 'ERC20 Factory App',
  projectId: 'YOUR_PROJECT_ID', // Obtén de https://cloud.walletconnect.com
  chains: [mainnet, polygon, arbitrum, base, sepolia],
  ssr: true,
})
```

#### 1.3 Configuración del Provider

En `pages/_app.tsx` o `app/layout.tsx`:

```typescript
import '@rainbow-me/rainbowkit/styles.css'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { WagmiProvider } from 'wagmi'
import { RainbowKitProvider } from '@rainbow-me/rainbowkit'
import { config } from '../lib/wagmi'

const queryClient = new QueryClient()

export default function App({ Component, pageProps }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <Component {...pageProps} />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}
```

### Paso 2: Configuración del Contrato

#### 2.1 ABI del Contrato

Crea `lib/contracts.ts`:

```typescript
export const ERC20FactoryABI = [
  {
    "inputs": [
      {"internalType": "string", "name": "name_", "type": "string"},
      {"internalType": "string", "name": "symbol_", "type": "string"},
      {"internalType": "uint256", "name": "initialSupply_", "type": "uint256"}
    ],
    "name": "createToken",
    "outputs": [{"internalType": "address", "name": "tokenAddress", "type": "address"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "getUserTokens",
    "outputs": [
      {
        "components": [
          {"internalType": "address", "name": "tokenAddress", "type": "address"},
          {"internalType": "address", "name": "creator", "type": "address"},
          {"internalType": "string", "name": "name", "type": "string"},
          {"internalType": "string", "name": "symbol", "type": "string"},
          {"internalType": "uint256", "name": "initialSupply", "type": "uint256"},
          {"internalType": "uint256", "name": "createdAt", "type": "uint256"}
        ],
        "internalType": "struct ERC20Factory.TokenInfo",
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getAllTokens",
    "outputs": [
      {
        "components": [
          {"internalType": "address", "name": "tokenAddress", "type": "address"},
          {"internalType": "address", "name": "creator", "type": "address"},
          {"internalType": "string", "name": "name", "type": "string"},
          {"internalType": "string", "name": "symbol", "type": "string"},
          {"internalType": "uint256", "name": "initialSupply", "type": "uint256"},
          {"internalType": "uint256", "name": "createdAt", "type": "uint256"}
        ],
        "internalType": "struct ERC20Factory.TokenInfo",
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "getUserTokenCount",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "index", "type": "uint256"}],
    "name": "getTokenByIndex",
    "outputs": [
      {
        "components": [
          {"internalType": "address", "name": "tokenAddress", "type": "address"},
          {"internalType": "address", "name": "creator", "type": "address"},
          {"internalType": "string", "name": "name", "type": "string"},
          {"internalType": "string", "name": "symbol", "type": "string"},
          {"internalType": "uint256", "name": "initialSupply", "type": "uint256"},
          {"internalType": "uint256", "name": "createdAt", "type": "uint256"}
        ],
        "internalType": "struct ERC20Factory.TokenInfo",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "tokenAddress", "type": "address"}],
    "name": "isTokenFromFactory",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "tokenAddress", "type": "address"}],
    "name": "getTokenCreator",
    "outputs": [{"internalType": "address", "name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "tokenAddress", "type": "address"},
      {"indexed": true, "internalType": "address", "name": "creator", "type": "address"},
      {"indexed": false, "internalType": "string", "name": "name", "type": "string"},
      {"indexed": false, "internalType": "string", "name": "symbol", "type": "string"},
      {"indexed": false, "internalType": "uint256", "name": "initialSupply", "type": "uint256"}
    ],
    "name": "TokenCreated",
    "type": "event"
  }
] as const

export const ERC20FactoryAddress = '0x...' // Dirección del contrato desplegado
```

### Paso 3: Hooks Personalizados

#### 3.1 Hook para Crear Token

Crea `hooks/useCreateToken.ts`:

```typescript
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { ERC20FactoryABI, ERC20FactoryAddress } from '../lib/contracts'

export function useCreateToken() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  })

  const createToken = async (name: string, symbol: string, initialSupply: string) => {
    try {
      const supply = BigInt(initialSupply) * BigInt(10 ** 18) // Convertir a wei
      
      writeContract({
        address: ERC20FactoryAddress,
        abi: ERC20FactoryABI,
        functionName: 'createToken',
        args: [name, symbol, supply],
      })
    } catch (err) {
      console.error('Error creating token:', err)
    }
  }

  return {
    createToken,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  }
}
```

#### 3.2 Hook para Obtener Tokens

Crea `hooks/useTokens.ts`:

```typescript
import { useReadContract } from 'wagmi'
import { useAccount } from 'wagmi'
import { ERC20FactoryABI, ERC20FactoryAddress } from '../lib/contracts'

export function useUserTokens() {
  const { address } = useAccount()
  
  const { data: userTokens, isLoading, error, refetch } = useReadContract({
    address: ERC20FactoryAddress,
    abi: ERC20FactoryABI,
    functionName: 'getUserTokens',
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  })

  return {
    userTokens: userTokens as TokenInfo[] | undefined,
    isLoading,
    error,
    refetch,
  }
}

export function useAllTokens() {
  const { data: allTokens, isLoading, error, refetch } = useReadContract({
    address: ERC20FactoryAddress,
    abi: ERC20FactoryABI,
    functionName: 'getAllTokens',
  })

  return {
    allTokens: allTokens as TokenInfo[] | undefined,
    isLoading,
    error,
    refetch,
  }
}

export interface TokenInfo {
  tokenAddress: string
  creator: string
  name: string
  symbol: string
  initialSupply: bigint
  createdAt: bigint
}
```

### Paso 4: Componentes de UI

#### 4.1 Componente para Crear Token

Crea `components/CreateTokenForm.tsx`:

```typescript
'use client'

import { useState } from 'react'
import { useCreateToken } from '../hooks/useCreateToken'
import { ConnectButton } from '@rainbow-me/rainbowkit'

export default function CreateTokenForm() {
  const [formData, setFormData] = useState({
    name: '',
    symbol: '',
    initialSupply: '',
  })

  const { createToken, isPending, isConfirming, isSuccess, error } = useCreateToken()

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.name || !formData.symbol || !formData.initialSupply) {
      alert('Por favor completa todos los campos')
      return
    }

    createToken(formData.name, formData.symbol, formData.initialSupply)
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    })
  }

  return (
    <div className="max-w-md mx-auto bg-white rounded-xl shadow-md p-6">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Crear Token ERC20</h2>
      
      <ConnectButton />
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="name" className="block text-sm font-medium text-gray-700">
            Nombre del Token
          </label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleChange}
            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
            placeholder="Mi Token"
            required
          />
        </div>

        <div>
          <label htmlFor="symbol" className="block text-sm font-medium text-gray-700">
            Símbolo del Token
          </label>
          <input
            type="text"
            id="symbol"
            name="symbol"
            value={formData.symbol}
            onChange={handleChange}
            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
            placeholder="MTK"
            required
          />
        </div>

        <div>
          <label htmlFor="initialSupply" className="block text-sm font-medium text-gray-700">
            Suministro Inicial
          </label>
          <input
            type="number"
            id="initialSupply"
            name="initialSupply"
            value={formData.initialSupply}
            onChange={handleChange}
            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
            placeholder="1000000"
            min="1"
            required
          />
          <p className="mt-1 text-sm text-gray-500">
            El suministro se multiplicará por 10^18 (decimals)
          </p>
        </div>

        <button
          type="submit"
          disabled={isPending || isConfirming}
          className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
        >
          {isPending ? 'Enviando...' : isConfirming ? 'Confirmando...' : 'Crear Token'}
        </button>

        {error && (
          <div className="text-red-600 text-sm">
            Error: {error.message}
          </div>
        )}

        {isSuccess && (
          <div className="text-green-600 text-sm">
            ¡Token creado exitosamente!
          </div>
        )}
      </form>
    </div>
  )
}
```

#### 4.2 Componente para Mostrar Tokens

Crea `components/TokenList.tsx`:

```typescript
'use client'

import { useUserTokens, useAllTokens, TokenInfo } from '../hooks/useTokens'
import { useAccount } from 'wagmi'

interface TokenListProps {
  showAll?: boolean
}

export default function TokenList({ showAll = false }: TokenListProps) {
  const { address } = useAccount()
  const { userTokens, isLoading: userLoading } = useUserTokens()
  const { allTokens, isLoading: allLoading } = useAllTokens()

  const tokens = showAll ? allTokens : userTokens
  const isLoading = showAll ? allLoading : userLoading

  const formatDate = (timestamp: bigint) => {
    return new Date(Number(timestamp) * 1000).toLocaleDateString()
  }

  const formatSupply = (supply: bigint) => {
    return (Number(supply) / 10 ** 18).toLocaleString()
  }

  if (isLoading) {
    return (
      <div className="flex justify-center items-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    )
  }

  if (!tokens || tokens.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        {showAll ? 'No hay tokens creados' : 'No has creado ningún token'}
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900">
        {showAll ? 'Todos los Tokens' : 'Mis Tokens'}
      </h3>
      
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {tokens.map((token: TokenInfo, index: number) => (
          <div key={index} className="bg-white rounded-lg shadow-md p-6 border">
            <div className="flex items-center justify-between mb-4">
              <h4 className="text-lg font-semibold text-gray-900">{token.name}</h4>
              <span className="text-sm font-medium text-indigo-600 bg-indigo-100 px-2 py-1 rounded">
                {token.symbol}
              </span>
            </div>
            
            <div className="space-y-2 text-sm text-gray-600">
              <p>
                <span className="font-medium">Dirección:</span>
                <span className="ml-2 font-mono text-xs break-all">
                  {token.tokenAddress}
                </span>
              </p>
              
              <p>
                <span className="font-medium">Suministro:</span>
                <span className="ml-2">{formatSupply(token.initialSupply)}</span>
              </p>
              
              <p>
                <span className="font-medium">Creado:</span>
                <span className="ml-2">{formatDate(token.createdAt)}</span>
              </p>
              
              <p>
                <span className="font-medium">Creador:</span>
                <span className="ml-2 font-mono text-xs break-all">
                  {token.creator}
                </span>
              </p>
            </div>
            
            <div className="mt-4 pt-4 border-t">
              <button
                onClick={() => navigator.clipboard.writeText(token.tokenAddress)}
                className="w-full text-sm text-indigo-600 hover:text-indigo-800 font-medium"
              >
                Copiar Dirección
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
```

### Paso 5: Página Principal

Crea `pages/index.tsx`:

```typescript
import { ConnectButton } from '@rainbow-me/rainbowkit'
import CreateTokenForm from '../components/CreateTokenForm'
import TokenList from '../components/TokenList'

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <h1 className="text-3xl font-bold text-gray-900">
              ERC20 Factory
            </h1>
            <ConnectButton />
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Formulario de Creación */}
            <div>
              <CreateTokenForm />
            </div>
            
            {/* Lista de Tokens */}
            <div>
              <TokenList showAll={false} />
            </div>
          </div>
          
          {/* Lista de Todos los Tokens */}
          <div className="mt-12">
            <TokenList showAll={true} />
          </div>
        </div>
      </main>
    </div>
  )
}
```

### Paso 6: Configuración de Tailwind CSS

Instala y configura Tailwind CSS:

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

Configura `tailwind.config.js`:

```javascript
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

Agrega a `styles/globals.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

---

## Parámetros Requeridos para la Transacción

### Función createToken

La función `createToken` requiere tres parámetros que deben ser proporcionados desde la UI:

1. **name_ (string)**: Nombre del token
   - **Validación**: No puede estar vacío
   - **UI**: Campo de texto requerido
   - **Ejemplo**: "Mi Token Personalizado"

2. **symbol_ (string)**: Símbolo del token
   - **Validación**: No puede estar vacío
   - **UI**: Campo de texto requerido (máximo 5 caracteres recomendado)
   - **Ejemplo**: "MTP"

3. **initialSupply_ (uint256)**: Suministro inicial del token
   - **Validación**: Debe ser mayor a 0
   - **UI**: Campo numérico requerido
   - **Conversión**: Se multiplica por 10^18 (decimals) en el contrato
   - **Ejemplo**: Si el usuario ingresa "1000000", se convierte a "1000000000000000000000000" wei

### Validaciones del Contrato

El contrato incluye las siguientes validaciones:

1. **Nombre no vacío**: `require(bytes(name_).length > 0, "ERC20Factory: Name cannot be empty")`
2. **Símbolo no vacío**: `require(bytes(symbol_).length > 0, "ERC20Factory: Symbol cannot be empty")`
3. **Token creado exitosamente**: `require(tokenAddress != address(0), "ERC20Factory: Token creation failed")`
4. **Token no duplicado**: `require(!isTokenCreated[tokenAddress], "ERC20Factory: Token already exists")`

### Eventos Emitidos

La transacción emite el evento `TokenCreated` con:
- `tokenAddress`: Dirección del token creado
- `creator`: Dirección del creador
- `name`: Nombre del token
- `symbol`: Símbolo del token
- `initialSupply`: Suministro inicial

---

## Consideraciones de Seguridad

1. **Validación en Frontend**: Siempre validar los datos antes de enviar la transacción
2. **Manejo de Errores**: Implementar manejo robusto de errores de transacción
3. **Confirmación de Usuario**: Mostrar un resumen antes de confirmar la transacción
4. **Gas Estimation**: Calcular y mostrar el costo estimado de gas
5. **Rate Limiting**: Considerar implementar límites para evitar spam

---

## Funcionalidades Adicionales Recomendadas

1. **Búsqueda de Tokens**: Implementar búsqueda por nombre o símbolo
2. **Paginación**: Para listas grandes de tokens
3. **Filtros**: Filtrar por fecha de creación, creador, etc.
4. **Exportar Datos**: Permitir exportar información de tokens
5. **Notificaciones**: Sistema de notificaciones para eventos importantes
6. **Historial de Transacciones**: Mostrar historial de transacciones del usuario

---

Esta guía proporciona una implementación completa y funcional del contrato ERC20Factory con wagmi en Next.js, incluyendo todos los componentes de UI necesarios y las validaciones requeridas.
