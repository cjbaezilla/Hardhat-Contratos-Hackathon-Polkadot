# Guía Completa: Implementación de DAOFactory con wagmi en Next.js

## Tabla de Contenidos
1. [Análisis del Contrato DAOFactory](#análisis-del-contrato-daofactory)
2. [Configuración del Proyecto Next.js](#configuración-del-proyecto-nextjs)
3. [Instalación de Dependencias](#instalación-de-dependencias)
4. [Configuración de wagmi y viem](#configuración-de-wagmi-y-viem)
5. [Configuración de Redes Blockchain](#configuración-de-redes-blockchain)
6. [Implementación de Hooks Personalizados](#implementación-de-hooks-personalizados)
7. [Componentes de UI](#componentes-de-ui)
8. [Páginas Principales](#páginas-principales)
9. [Funcionalidades de Transacción](#funcionalidades-de-transacción)
10. [Manejo de Estados y Errores](#manejo-de-estados-y-errores)
11. [Testing y Deployment](#testing-y-deployment)

---

## Análisis del Contrato DAOFactory

### Funcionalidades Principales
El contrato `DAOFactory` permite:
- **Crear DAOs**: Desplegar nuevas instancias de contratos DAO
- **Rastrear DAOs**: Mantener un registro de todos los DAOs creados
- **Verificar Propiedad**: Identificar quién creó cada DAO
- **Validar DAOs**: Verificar si una dirección es un DAO válido

### Parámetros para Crear un DAO
```solidity
function deployDAO(
    address nftContract,           // Dirección del contrato NFT
    uint256 minProposalCreationTokens,  // Mínimo NFTs para crear propuestas
    uint256 minVotesToApprove,     // Mínimo votantes únicos para aprobar
    uint256 minTokensToApprove     // Mínimo poder de votación total
) external returns (address daoAddress)
```

### Eventos Importantes
- `DAOCreated`: Se emite cuando se crea un nuevo DAO
- `DAOFactoryOwnershipTransferred`: Transferencia de propiedad del factory

---

## Configuración del Proyecto Next.js

### 1. Crear Proyecto Next.js
```bash
npx create-next-app@latest dao-factory-app --typescript --tailwind --eslint
cd dao-factory-app
```

### 2. Estructura de Carpetas
```
src/
├── components/
│   ├── ui/
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   ├── Modal.tsx
│   │   └── Card.tsx
│   ├── dao/
│   │   ├── CreateDAOForm.tsx
│   │   ├── DAOList.tsx
│   │   ├── DAOCard.tsx
│   │   └── DAODetails.tsx
│   └── layout/
│       ├── Header.tsx
│       └── Footer.tsx
├── hooks/
│   ├── useDAOFactory.ts
│   ├── useDAO.ts
│   └── useNFT.ts
├── lib/
│   ├── contracts.ts
│   ├── config.ts
│   └── utils.ts
├── pages/
│   ├── index.tsx
│   ├── create-dao.tsx
│   ├── dao/[address].tsx
│   └── my-daos.tsx
└── styles/
    └── globals.css
```

---

## Instalación de Dependencias

### Dependencias Principales
```bash
npm install wagmi viem @tanstack/react-query
npm install @rainbow-me/rainbowkit
npm install @headlessui/react @heroicons/react
npm install clsx tailwind-merge
npm install date-fns
```

### Dependencias de Desarrollo
```bash
npm install -D @types/node
```

---

## Configuración de wagmi y viem

### 1. Configuración de Redes (`lib/config.ts`)
```typescript
import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { mainnet, polygon, arbitrum, base, sepolia } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'DAO Factory App',
  projectId: 'YOUR_WALLET_CONNECT_PROJECT_ID',
  chains: [mainnet, polygon, arbitrum, base, sepolia],
  ssr: true,
});

export const DAO_FACTORY_ADDRESS = '0x...'; // Dirección del contrato desplegado
export const SUPPORTED_CHAINS = [mainnet, polygon, arbitrum, base, sepolia];
```

### 2. Configuración de Contratos (`lib/contracts.ts`)
```typescript
import { Address } from 'viem';

export const DAO_FACTORY_ABI = [
  // ABI del contrato DAOFactory
  {
    "inputs": [
      {"internalType": "address", "name": "initialOwner", "type": "address"}
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "nftContract", "type": "address"},
      {"internalType": "uint256", "name": "minProposalCreationTokens", "type": "uint256"},
      {"internalType": "uint256", "name": "minVotesToApprove", "type": "uint256"},
      {"internalType": "uint256", "name": "minTokensToApprove", "type": "uint256"}
    ],
    "name": "deployDAO",
    "outputs": [
      {"internalType": "address", "name": "daoAddress", "type": "address"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getAllDAOs",
    "outputs": [
      {"internalType": "address[]", "name": "", "type": "address[]"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getTotalDAOs",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "daoAddress", "type": "address"}
    ],
    "name": "isDAO",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "daoAddress", "type": "address"}
    ],
    "name": "getDAOCreator",
    "outputs": [
      {"internalType": "address", "name": "", "type": "address"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "daoAddress", "type": "address"},
      {"indexed": true, "internalType": "address", "name": "creator", "type": "address"},
      {"indexed": true, "internalType": "address", "name": "nftContract", "type": "address"},
      {"indexed": false, "internalType": "uint256", "name": "minProposalCreationTokens", "type": "uint256"},
      {"indexed": false, "internalType": "uint256", "name": "minVotesToApprove", "type": "uint256"},
      {"indexed": false, "internalType": "uint256", "name": "minTokensToApprove", "type": "uint256"}
    ],
    "name": "DAOCreated",
    "type": "event"
  }
] as const;

export const DAO_ABI = [
  // ABI del contrato DAO (simplificado)
  {
    "inputs": [
      {"internalType": "address", "name": "_nftContract", "type": "address"},
      {"internalType": "uint256", "name": "_minProposalCreationTokens", "type": "uint256"},
      {"internalType": "uint256", "name": "_minVotesToApprove", "type": "uint256"},
      {"internalType": "uint256", "name": "_minTokensToApprove", "type": "uint256"}
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [],
    "name": "getTotalProposals",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "proposalId", "type": "uint256"}
    ],
    "name": "getProposal",
    "outputs": [
      {
        "components": [
          {"internalType": "uint256", "name": "id", "type": "uint256"},
          {"internalType": "address", "name": "proposer", "type": "address"},
          {"internalType": "string", "name": "description", "type": "string"},
          {"internalType": "string", "name": "link", "type": "string"},
          {"internalType": "uint256", "name": "votesFor", "type": "uint256"},
          {"internalType": "uint256", "name": "votesAgainst", "type": "uint256"},
          {"internalType": "uint256", "name": "startTime", "type": "uint256"},
          {"internalType": "uint256", "name": "endTime", "type": "uint256"},
          {"internalType": "bool", "name": "cancelled", "type": "bool"}
        ],
        "internalType": "struct DAO.Proposal",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const;
```

### 3. Configuración de la App (`pages/_app.tsx`)
```typescript
import '@/styles/globals.css';
import type { AppProps } from 'next/app';
import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { config } from '@/lib/config';

import '@rainbow-me/rainbowkit/styles.css';

const queryClient = new QueryClient();

export default function App({ Component, pageProps }: AppProps) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <Component {...pageProps} />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
```

---

## Implementación de Hooks Personalizados

### 1. Hook para DAOFactory (`hooks/useDAOFactory.ts`)
```typescript
import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { DAO_FACTORY_ABI, DAO_FACTORY_ADDRESS } from '@/lib/contracts';
import { Address } from 'viem';

export function useDAOFactory() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  // Leer todos los DAOs
  const { data: allDAOs, refetch: refetchDAOs } = useReadContract({
    address: DAO_FACTORY_ADDRESS,
    abi: DAO_FACTORY_ABI,
    functionName: 'getAllDAOs',
  });

  // Leer total de DAOs
  const { data: totalDAOs } = useReadContract({
    address: DAO_FACTORY_ADDRESS,
    abi: DAO_FACTORY_ABI,
    functionName: 'getTotalDAOs',
  });

  // Crear nuevo DAO
  const createDAO = async (
    nftContract: Address,
    minProposalCreationTokens: bigint,
    minVotesToApprove: bigint,
    minTokensToApprove: bigint
  ) => {
    try {
      await writeContract({
        address: DAO_FACTORY_ADDRESS,
        abi: DAO_FACTORY_ABI,
        functionName: 'deployDAO',
        args: [nftContract, minProposalCreationTokens, minVotesToApprove, minTokensToApprove],
      });
    } catch (error) {
      console.error('Error creating DAO:', error);
      throw error;
    }
  };

  // Verificar si una dirección es DAO válido
  const isDAO = async (daoAddress: Address) => {
    // Esta función se implementaría con useReadContract
    return false; // Placeholder
  };

  return {
    allDAOs,
    totalDAOs,
    createDAO,
    isDAO,
    refetchDAOs,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}
```

### 2. Hook para DAO Individual (`hooks/useDAO.ts`)
```typescript
import { useReadContract, useWriteContract } from 'wagmi';
import { DAO_ABI } from '@/lib/contracts';
import { Address } from 'viem';

export function useDAO(daoAddress: Address) {
  // Leer total de propuestas
  const { data: totalProposals } = useReadContract({
    address: daoAddress,
    abi: DAO_ABI,
    functionName: 'getTotalProposals',
  });

  // Leer propuesta específica
  const getProposal = (proposalId: bigint) => {
    return useReadContract({
      address: daoAddress,
      abi: DAO_ABI,
      functionName: 'getProposal',
      args: [proposalId],
    });
  };

  return {
    totalProposals,
    getProposal,
  };
}
```

### 3. Hook para NFTs (`hooks/useNFT.ts`)
```typescript
import { useReadContract } from 'wagmi';
import { Address } from 'viem';

const ERC721_ABI = [
  {
    inputs: [{ name: 'owner', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;

export function useNFT(nftContract: Address, owner: Address) {
  const { data: balance } = useReadContract({
    address: nftContract,
    abi: ERC721_ABI,
    functionName: 'balanceOf',
    args: [owner],
  });

  return {
    balance,
  };
}
```

---

## Componentes de UI

### 1. Componente de Creación de DAO (`components/dao/CreateDAOForm.tsx`)
```typescript
'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { useDAOFactory } from '@/hooks/useDAOFactory';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Card } from '@/components/ui/Card';

interface CreateDAOFormProps {
  onSuccess?: (daoAddress: string) => void;
}

export function CreateDAOForm({ onSuccess }: CreateDAOFormProps) {
  const { address } = useAccount();
  const { createDAO, isPending, isConfirming, isSuccess, error } = useDAOFactory();
  
  const [formData, setFormData] = useState({
    nftContract: '',
    minProposalCreationTokens: '',
    minVotesToApprove: '',
    minTokensToApprove: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!address) {
      alert('Por favor conecta tu wallet');
      return;
    }

    try {
      await createDAO(
        formData.nftContract as `0x${string}`,
        BigInt(formData.minProposalCreationTokens),
        BigInt(formData.minVotesToApprove),
        BigInt(formData.minTokensToApprove)
      );
      
      if (onSuccess) {
        onSuccess(''); // Se actualizará cuando se confirme la transacción
      }
    } catch (error) {
      console.error('Error creating DAO:', error);
    }
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  return (
    <Card className="p-6 max-w-2xl mx-auto">
      <h2 className="text-2xl font-bold mb-6 text-center">
        Crear Nueva DAO
      </h2>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-2">
            Dirección del Contrato NFT
          </label>
          <Input
            type="text"
            placeholder="0x..."
            value={formData.nftContract}
            onChange={(e) => handleInputChange('nftContract', e.target.value)}
            required
            className="w-full"
          />
          <p className="text-sm text-gray-500 mt-1">
            Dirección del contrato ERC721 que se usará para votaciones
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">
            Mínimo NFTs para Crear Propuestas
          </label>
          <Input
            type="number"
            placeholder="10"
            value={formData.minProposalCreationTokens}
            onChange={(e) => handleInputChange('minProposalCreationTokens', e.target.value)}
            required
            min="1"
            className="w-full"
          />
          <p className="text-sm text-gray-500 mt-1">
            Cantidad mínima de NFTs necesarios para crear una propuesta
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">
            Mínimo Votantes para Aprobar
          </label>
          <Input
            type="number"
            placeholder="5"
            value={formData.minVotesToApprove}
            onChange={(e) => handleInputChange('minVotesToApprove', e.target.value)}
            required
            min="1"
            className="w-full"
          />
          <p className="text-sm text-gray-500 mt-1">
            Número mínimo de votantes únicos para aprobar una propuesta
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">
            Mínimo Poder de Votación Total
          </label>
          <Input
            type="number"
            placeholder="50"
            value={formData.minTokensToApprove}
            onChange={(e) => handleInputChange('minTokensToApprove', e.target.value)}
            required
            min="1"
            className="w-full"
          />
          <p className="text-sm text-gray-500 mt-1">
            Suma total mínima del poder de votación para aprobar
          </p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-md p-3">
            <p className="text-red-600 text-sm">
              Error: {error.message}
            </p>
          </div>
        )}

        <Button
          type="submit"
          disabled={isPending || isConfirming}
          className="w-full"
        >
          {isPending && 'Preparando transacción...'}
          {isConfirming && 'Confirmando...'}
          {isSuccess && '¡DAO Creado!'}
          {!isPending && !isConfirming && !isSuccess && 'Crear DAO'}
        </Button>
      </form>
    </Card>
  );
}
```

### 2. Lista de DAOs (`components/dao/DAOList.tsx`)
```typescript
'use client';

import { useDAOFactory } from '@/hooks/useDAOFactory';
import { DAOCard } from './DAOCard';
import { Card } from '@/components/ui/Card';

export function DAOList() {
  const { allDAOs, totalDAOs, refetchDAOs } = useDAOFactory();

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">
          DAOs Disponibles ({totalDAOs?.toString() || 0})
        </h2>
        <button
          onClick={() => refetchDAOs()}
          className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600"
        >
          Actualizar
        </button>
      </div>

      {allDAOs && allDAOs.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {allDAOs.map((daoAddress, index) => (
            <DAOCard
              key={daoAddress}
              daoAddress={daoAddress}
              index={index}
            />
          ))}
        </div>
      ) : (
        <Card className="p-8 text-center">
          <p className="text-gray-500 text-lg">
            No hay DAOs creados aún
          </p>
        </Card>
      )}
    </div>
  );
}
```

### 3. Tarjeta de DAO (`components/dao/DAOCard.tsx`)
```typescript
'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { useDAOFactory } from '@/hooks/useDAOFactory';
import { useDAO } from '@/hooks/useDAO';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import Link from 'next/link';

interface DAOCardProps {
  daoAddress: string;
  index: number;
}

export function DAOCard({ daoAddress, index }: DAOCardProps) {
  const { address } = useAccount();
  const { getDAOCreator } = useDAOFactory();
  const { totalProposals } = useDAO(daoAddress as `0x${string}`);
  const [creator, setCreator] = useState<string | null>(null);

  // Obtener creador del DAO
  const { data: creatorAddress } = useReadContract({
    address: DAO_FACTORY_ADDRESS,
    abi: DAO_FACTORY_ABI,
    functionName: 'getDAOCreator',
    args: [daoAddress as `0x${string}`],
  });

  const isOwner = address && creatorAddress && address.toLowerCase() === creatorAddress.toLowerCase();

  return (
    <Card className="p-6 hover:shadow-lg transition-shadow">
      <div className="space-y-4">
        <div>
          <h3 className="text-lg font-semibold">
            DAO #{index + 1}
          </h3>
          <p className="text-sm text-gray-500 font-mono">
            {daoAddress.slice(0, 6)}...{daoAddress.slice(-4)}
          </p>
        </div>

        <div className="space-y-2">
          <div className="flex justify-between">
            <span className="text-sm text-gray-600">Propuestas:</span>
            <span className="font-medium">
              {totalProposals?.toString() || '0'}
            </span>
          </div>
          
          <div className="flex justify-between">
            <span className="text-sm text-gray-600">Creador:</span>
            <span className="text-sm font-mono">
              {creatorAddress ? 
                `${creatorAddress.slice(0, 6)}...${creatorAddress.slice(-4)}` : 
                'Cargando...'
              }
            </span>
          </div>
        </div>

        <div className="flex space-x-2">
          <Link href={`/dao/${daoAddress}`}>
            <Button variant="outline" className="flex-1">
              Ver Detalles
            </Button>
          </Link>
          
          {isOwner && (
            <Button variant="outline" className="flex-1">
              Gestionar
            </Button>
          )}
        </div>
      </div>
    </Card>
  );
}
```

---

## Páginas Principales

### 1. Página Principal (`pages/index.tsx`)
```typescript
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { DAOList } from '@/components/dao/DAOList';
import { CreateDAOForm } from '@/components/dao/CreateDAOForm';
import { useState } from 'react';

export default function Home() {
  const [showCreateForm, setShowCreateForm] = useState(false);

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <h1 className="text-3xl font-bold text-gray-900">
              DAO Factory
            </h1>
            <ConnectButton />
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="text-center mb-8">
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            Crea y Gestiona tu DAO
          </h2>
          <p className="text-xl text-gray-600 mb-8">
            Despliega tu propia organización autónoma descentralizada en minutos
          </p>
          
          <button
            onClick={() => setShowCreateForm(!showCreateForm)}
            className="bg-blue-600 text-white px-6 py-3 rounded-lg text-lg font-medium hover:bg-blue-700 transition-colors"
          >
            {showCreateForm ? 'Ver DAOs Existentes' : 'Crear Nueva DAO'}
          </button>
        </div>

        {showCreateForm ? (
          <CreateDAOForm 
            onSuccess={() => setShowCreateForm(false)}
          />
        ) : (
          <DAOList />
        )}
      </main>
    </div>
  );
}
```

### 2. Página de Creación de DAO (`pages/create-dao.tsx`)
```typescript
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { CreateDAOForm } from '@/components/dao/CreateDAOForm';
import { useRouter } from 'next/router';

export default function CreateDAOPage() {
  const router = useRouter();

  const handleSuccess = (daoAddress: string) => {
    router.push(`/dao/${daoAddress}`);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <h1 className="text-3xl font-bold text-gray-900">
              Crear Nueva DAO
            </h1>
            <ConnectButton />
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <CreateDAOForm onSuccess={handleSuccess} />
      </main>
    </div>
  );
}
```

### 3. Página de Detalles de DAO (`pages/dao/[address].tsx`)
```typescript
import { useRouter } from 'next/router';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { DAODetails } from '@/components/dao/DAODetails';

export default function DAOPage() {
  const router = useRouter();
  const { address } = router.query;

  if (!address || typeof address !== 'string') {
    return <div>Cargando...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <h1 className="text-3xl font-bold text-gray-900">
              DAO Details
            </h1>
            <ConnectButton />
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <DAODetails daoAddress={address as `0x${string}`} />
      </main>
    </div>
  );
}
```

---

## Funcionalidades de Transacción

### 1. Validación de Datos de Entrada
```typescript
// utils/validation.ts
export function validateDAOForm(data: {
  nftContract: string;
  minProposalCreationTokens: string;
  minVotesToApprove: string;
  minTokensToApprove: string;
}) {
  const errors: Record<string, string> = {};

  // Validar dirección del contrato NFT
  if (!data.nftContract || !isAddress(data.nftContract)) {
    errors.nftContract = 'Dirección de contrato NFT inválida';
  }

  // Validar números
  const minProposalTokens = parseInt(data.minProposalCreationTokens);
  const minVotes = parseInt(data.minVotesToApprove);
  const minTokens = parseInt(data.minTokensToApprove);

  if (isNaN(minProposalTokens) || minProposalTokens <= 0) {
    errors.minProposalCreationTokens = 'Debe ser un número mayor a 0';
  }

  if (isNaN(minVotes) || minVotes <= 0) {
    errors.minVotesToApprove = 'Debe ser un número mayor a 0';
  }

  if (isNaN(minTokens) || minTokens <= 0) {
    errors.minTokensToApprove = 'Debe ser un número mayor a 0';
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
}
```

### 2. Manejo de Estados de Transacción
```typescript
// hooks/useTransactionStatus.ts
import { useState, useEffect } from 'react';
import { useWaitForTransactionReceipt } from 'wagmi';

export function useTransactionStatus(hash: `0x${string}` | undefined) {
  const [status, setStatus] = useState<'idle' | 'pending' | 'success' | 'error'>('idle');
  
  const { isLoading, isSuccess, error } = useWaitForTransactionReceipt({
    hash,
  });

  useEffect(() => {
    if (hash && isLoading) {
      setStatus('pending');
    } else if (isSuccess) {
      setStatus('success');
    } else if (error) {
      setStatus('error');
    }
  }, [hash, isLoading, isSuccess, error]);

  return { status, isLoading, isSuccess, error };
}
```

### 3. Notificaciones de Transacción
```typescript
// components/ui/TransactionToast.tsx
import { useEffect } from 'react';
import { toast } from 'react-hot-toast';

interface TransactionToastProps {
  hash: `0x${string}` | undefined;
  isSuccess: boolean;
  isError: boolean;
  onSuccess?: () => void;
}

export function TransactionToast({ 
  hash, 
  isSuccess, 
  isError, 
  onSuccess 
}: TransactionToastProps) {
  useEffect(() => {
    if (hash) {
      toast.loading('Transacción pendiente...', { id: hash });
    }
  }, [hash]);

  useEffect(() => {
    if (isSuccess) {
      toast.success('¡Transacción confirmada!', { id: hash });
      onSuccess?.();
    }
  }, [isSuccess, hash, onSuccess]);

  useEffect(() => {
    if (isError) {
      toast.error('Error en la transacción', { id: hash });
    }
  }, [isError, hash]);

  return null;
}
```

---

## Manejo de Estados y Errores

### 1. Contexto de Estado Global
```typescript
// context/AppContext.tsx
import { createContext, useContext, useReducer, ReactNode } from 'react';

interface AppState {
  selectedDAO: string | null;
  userDAOs: string[];
  isLoading: boolean;
  error: string | null;
}

type AppAction = 
  | { type: 'SET_SELECTED_DAO'; payload: string }
  | { type: 'SET_USER_DAOS'; payload: string[] }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null };

const initialState: AppState = {
  selectedDAO: null,
  userDAOs: [],
  isLoading: false,
  error: null,
};

function appReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_SELECTED_DAO':
      return { ...state, selectedDAO: action.payload };
    case 'SET_USER_DAOS':
      return { ...state, userDAOs: action.payload };
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    case 'SET_ERROR':
      return { ...state, error: action.payload };
    default:
      return state;
  }
}

const AppContext = createContext<{
  state: AppState;
  dispatch: React.Dispatch<AppAction>;
} | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(appReducer, initialState);

  return (
    <AppContext.Provider value={{ state, dispatch }}>
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within AppProvider');
  }
  return context;
}
```

### 2. Manejo de Errores
```typescript
// components/ErrorBoundary.tsx
import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-red-600 mb-4">
              Algo salió mal
            </h2>
            <p className="text-gray-600 mb-4">
              {this.state.error?.message || 'Error desconocido'}
            </p>
            <button
              onClick={() => this.setState({ hasError: false })}
              className="bg-blue-500 text-white px-4 py-2 rounded-md hover:bg-blue-600"
            >
              Intentar de nuevo
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
```

---

## Testing y Deployment

### 1. Scripts de Testing
```typescript
// __tests__/DAOFactory.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { CreateDAOForm } from '@/components/dao/CreateDAOForm';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: false },
    mutations: { retry: false },
  },
});

function TestWrapper({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </WagmiProvider>
  );
}

describe('CreateDAOForm', () => {
  it('renders form fields correctly', () => {
    render(
      <TestWrapper>
        <CreateDAOForm />
      </TestWrapper>
    );

    expect(screen.getByLabelText(/dirección del contrato nft/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/mínimo nfts para crear propuestas/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/mínimo votantes para aprobar/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/mínimo poder de votación total/i)).toBeInTheDocument();
  });

  it('validates form inputs', async () => {
    render(
      <TestWrapper>
        <CreateDAOForm />
      </TestWrapper>
    );

    const submitButton = screen.getByRole('button', { name: /crear dao/i });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/dirección del contrato nft inválida/i)).toBeInTheDocument();
    });
  });
});
```

### 2. Configuración de Deployment
```typescript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['localhost'],
  },
  env: {
    NEXT_PUBLIC_DAO_FACTORY_ADDRESS: process.env.NEXT_PUBLIC_DAO_FACTORY_ADDRESS,
    NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID,
  },
};

module.exports = nextConfig;
```

### 3. Variables de Entorno
```bash
# .env.local
NEXT_PUBLIC_DAO_FACTORY_ADDRESS=0x...
NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=your_project_id
NEXT_PUBLIC_CHAIN_ID=1
```

---

## Resumen de Implementación

### Parámetros Requeridos para Crear DAO
1. **nftContract**: Dirección del contrato ERC721
2. **minProposalCreationTokens**: Mínimo NFTs para crear propuestas
3. **minVotesToApprove**: Mínimo votantes únicos para aprobar
4. **minTokensToApprove**: Mínimo poder de votación total

### Flujo de Transacción
1. Usuario completa el formulario
2. Se validan los datos de entrada
3. Se ejecuta `writeContract` con los parámetros
4. Se muestra estado de transacción pendiente
5. Se espera confirmación con `useWaitForTransactionReceipt`
6. Se actualiza la UI con el resultado

### Componentes de UI Necesarios
- Formulario de creación con validación
- Lista de DAOs existentes
- Tarjetas de DAO individuales
- Manejo de estados de transacción
- Notificaciones de éxito/error

Esta implementación proporciona una interfaz completa para interactuar con el contrato DAOFactory, permitiendo a los usuarios crear y gestionar sus propias DAOs de manera intuitiva.
