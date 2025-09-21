# Documentación Completa - Contrato DAO

## Introducción

El contrato `DAO` implementa un sistema de gobernanza descentralizada que permite a los poseedores de NFTs participar en la toma de decisiones colectivas a través de propuestas y votaciones. Este sistema está diseñado para funcionar con cualquier colección de NFTs ERC721, donde cada NFT representa un voto en las decisiones de la comunidad.

La implementación utiliza un sistema de votación ponderado donde el poder de voto de cada participante está determinado por la cantidad de NFTs que posee, combinado con mecanismos de validación que aseguran la legitimidad y participación suficiente en cada propuesta.

## Arquitectura del Contrato

### Herencia y Dependencias

El contrato hereda de dos contratos principales de OpenZeppelin:

- **Ownable**: Proporciona control de acceso administrativo, permitiendo que solo el propietario pueda modificar parámetros críticos del sistema de gobernanza.
- **IERC721**: Interfaz para interactuar con contratos de tokens no fungibles, permitiendo verificar la propiedad de NFTs para determinar el poder de voto.

Esta arquitectura modular permite que el contrato se integre con cualquier colección de NFTs existente, proporcionando flexibilidad para diferentes proyectos y comunidades.

### Estructura de Datos

#### Propuesta (Proposal)

```solidity
struct Proposal {
    uint256 id;
    address proposer;
    string username;
    string description;
    string link;
    uint256 votesFor;
    uint256 votesAgainst;
    uint256 startTime;
    uint256 endTime;
    bool cancelled;
}
```

Cada propuesta contiene información completa sobre la iniciativa de gobernanza:

- **id**: Identificador único de la propuesta
- **proposer**: Dirección del creador de la propuesta
- **username**: Nombre de usuario del proposer para identificación
- **description**: Descripción detallada de la propuesta
- **link**: Enlace a recursos adicionales relacionados
- **votesFor/votesAgainst**: Contadores de votos a favor y en contra
- **startTime/endTime**: Ventana temporal para la votación
- **cancelled**: Estado de cancelación de la propuesta

### Variables de Estado

#### Configuración del Sistema

```solidity
IERC721 public nftContract;
uint256 public proposalCount;
uint256 public MIN_PROPOSAL_VOTES = 10;
uint256 public MIN_VOTES_TO_APPROVE = 10;
uint256 public MIN_TOKENS_TO_APPROVE = 50;
```

**nftContract**: Referencia al contrato de NFTs que determina el poder de voto. Esta variable puede ser actualizada por el propietario para migrar a diferentes colecciones.

**proposalCount**: Contador global de propuestas creadas, utilizado para generar IDs únicos.

**MIN_PROPOSAL_VOTES**: Mínimo de 10 NFTs requeridos para crear una propuesta, previniendo spam y asegurando que solo participantes comprometidos puedan proponer.

**MIN_VOTES_TO_APPROVE**: Mínimo de 10 votantes únicos requeridos para aprobar una propuesta, garantizando participación suficiente.

**MIN_TOKENS_TO_APPROVE**: Mínimo de 50 tokens de poder de voto total para aprobar una propuesta, asegurando que la decisión represente una porción significativa de la comunidad.

#### Mapeos de Seguimiento

```solidity
mapping(uint256 => Proposal) public proposals;
mapping(uint256 => mapping(address => bool)) public hasVoted;
mapping(uint256 => uint256) public proposalUniqueVotersCount;
mapping(uint256 => uint256) public proposalTotalVotingPowerSum;
mapping(address => uint256) public lastProposalTime;
```

**proposals**: Almacena todas las propuestas por su ID.

**hasVoted**: Rastrea si una dirección específica ya votó en una propuesta particular, previniendo votos duplicados.

**proposalUniqueVotersCount**: Cuenta el número de votantes únicos por propuesta.

**proposalTotalVotingPowerSum**: Suma el poder de voto total ejercido en cada propuesta.

**lastProposalTime**: Implementa un mecanismo anti-spam, registrando cuándo cada dirección creó su última propuesta.

## Funcionalidades Principales

### Sistema de Creación de Propuestas

La función `createProposal` implementa un sistema robusto de validación que asegura la calidad y legitimidad de las propuestas.

```solidity
function createProposal(string calldata username, string calldata description, string calldata link, uint256 startTime, uint256 endTime) external {
    uint256 nftBalance = nftContract.balanceOf(msg.sender);
    require(nftBalance >= MIN_PROPOSAL_VOTES, "Necesitas al menos 10 NFTs para crear propuesta");
    
    require(
        block.timestamp >= lastProposalTime[msg.sender] + 1 days,
        "Solo puedes crear una propuesta cada 24 horas"
    );
    
    require(startTime >= block.timestamp, "startTime debe ser en el futuro");
    require(endTime > startTime, "endTime debe ser mayor que startTime");
    
    uint256 proposalId = proposalCount++;
    
    proposals[proposalId] = Proposal({
        id: proposalId,
        proposer: msg.sender,
        username: username,
        description: description,
        link: link,
        votesFor: 0,
        votesAgainst: 0,
        startTime: startTime,
        endTime: endTime,
        cancelled: false
    });
    
    lastProposalTime[msg.sender] = block.timestamp;
    
    emit ProposalCreated(proposalId, msg.sender, description, startTime, endTime);
}
```

#### Validaciones Implementadas

1. **Verificación de Poder de Voto**: Confirma que el proposer posee al menos 10 NFTs, asegurando que solo miembros comprometidos puedan crear propuestas.

2. **Prevención de Spam**: Limita a una propuesta por dirección cada 24 horas, previniendo el abuso del sistema.

3. **Validación Temporal**: Verifica que los tiempos de inicio y fin sean lógicos y futuros, previniendo propuestas con ventanas de votación inválidas.

4. **Inicialización Completa**: Establece todos los campos de la propuesta con valores iniciales apropiados.

### Sistema de Votación

La función `vote` implementa un sistema de votación ponderado que respeta la propiedad de NFTs y previene votos duplicados.

```solidity
function vote(uint256 proposalId, bool support) external {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.id == proposalId, "Propuesta no existe");
    require(block.timestamp >= proposal.startTime, "Votacion no ha comenzado");
    require(block.timestamp <= proposal.endTime, "Votacion ha terminado");
    require(!proposal.cancelled, "Propuesta cancelada");
    require(!hasVoted[proposalId][msg.sender], "Ya votaste en esta propuesta");
    
    uint256 nftBalance = nftContract.balanceOf(msg.sender);
    require(nftBalance > 0, "Necesitas al menos 1 NFT para votar");
    
    hasVoted[proposalId][msg.sender] = true;
    proposalUniqueVotersCount[proposalId]++;
    proposalTotalVotingPowerSum[proposalId] += nftBalance;
    
    if (support) {
        proposal.votesFor += nftBalance;
    } else {
        proposal.votesAgainst += nftBalance;
    }
    
    emit VoteCast(proposalId, msg.sender, support, nftBalance);
}
```

#### Características del Sistema de Votación

1. **Votación Ponderada**: El poder de voto es proporcional a la cantidad de NFTs poseídos.

2. **Prevención de Votos Duplicados**: Cada dirección puede votar solo una vez por propuesta.

3. **Validación Temporal**: Solo permite votar durante la ventana de tiempo activa de la propuesta.

4. **Seguimiento de Participación**: Mantiene estadísticas detalladas sobre votantes únicos y poder de voto total.

5. **Transparencia**: Emite eventos para cada voto, facilitando el seguimiento y auditoría.

### Sistema de Cancelación

```solidity
function cancelProposal(uint256 proposalId) external {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.id == proposalId, "Propuesta no existe");
    require(msg.sender == proposal.proposer, "Solo el proposer puede cancelar");
    require(!proposal.cancelled, "Propuesta ya cancelada");
    require(block.timestamp <= proposal.endTime, "Votacion ya termino");
    
    proposal.cancelled = true;
    emit ProposalCancelled(proposalId);
}
```

Solo el creador de la propuesta puede cancelarla, y únicamente antes de que termine el período de votación. Esto proporciona flexibilidad para corregir errores o retirar propuestas que ya no son relevantes.

### Sistema de Evaluación de Propuestas

La función `getProposalStatus` implementa un algoritmo sofisticado para determinar el resultado de una propuesta.

```solidity
function getProposalStatus(uint256 proposalId) external view returns (string memory) {
    Proposal memory proposal = proposals[proposalId];
    
    if (proposal.id != proposalId) return "No existe";
    if (proposal.cancelled) return "Cancelada";
    if (block.timestamp < proposal.startTime) return "Pendiente";
    if (block.timestamp <= proposal.endTime) return "Votando";
    
    if (proposal.votesFor > proposal.votesAgainst && 
        proposalUniqueVotersCount[proposalId] >= MIN_VOTES_TO_APPROVE &&
        proposalTotalVotingPowerSum[proposalId] >= MIN_TOKENS_TO_APPROVE) {
        return "Aprobada";
    }
    return "Rechazada";
}
```

#### Criterios de Aprobación

Una propuesta se aprueba solo si cumple **todos** los siguientes criterios:

1. **Mayoría Simple**: Más votos a favor que en contra
2. **Participación Suficiente**: Al menos 10 votantes únicos
3. **Poder de Voto Representativo**: Al menos 50 tokens de poder de voto total

Este sistema de triple validación asegura que las decisiones representen tanto la voluntad de la mayoría como la participación significativa de la comunidad.

### Funciones de Consulta

#### Información de Propuestas

```solidity
function getProposal(uint256 proposalId) external view returns (Proposal memory) {
    return proposals[proposalId];
}
```

Proporciona acceso completo a todos los datos de una propuesta específica.

#### Poder de Voto

```solidity
function getVotingPower(address voter) external view returns (uint256) {
    return nftContract.balanceOf(voter);
}
```

Calcula el poder de voto actual de una dirección basado en su posesión de NFTs.

#### Estadísticas de Participación

```solidity
function getUniqueVotersCount(uint256 proposalId) external view returns (uint256) {
    require(proposals[proposalId].id == proposalId, "Propuesta no existe");
    return proposalUniqueVotersCount[proposalId];
}

function getProposalTotalVotingPower(uint256 proposalId) external view returns (uint256) {
    require(proposals[proposalId].id == proposalId, "Propuesta no existe");
    return proposalTotalVotingPowerSum[proposalId];
}
```

Estas funciones proporcionan métricas detalladas sobre la participación en cada propuesta, facilitando el análisis y la transparencia.

### Funciones Administrativas

#### Actualización del Contrato NFT

```solidity
function updateNFTContract(address _newNftContract) external onlyOwner {
    require(_newNftContract != address(0), "Direccion invalida");
    require(_newNftContract != address(nftContract), "Misma direccion actual");
    
    address oldContract = address(nftContract);
    nftContract = IERC721(_newNftContract);
    
    emit NFTContractUpdated(oldContract, _newNftContract);
}
```

Permite migrar el sistema de gobernanza a una nueva colección de NFTs, proporcionando flexibilidad para la evolución del proyecto.

#### Configuración de Parámetros

```solidity
function updateMinProposalVotes(uint256 _newMinProposalVotes) external onlyOwner {
    require(_newMinProposalVotes > 0, "Valor debe ser mayor a 0");
    
    uint256 oldValue = MIN_PROPOSAL_VOTES;
    MIN_PROPOSAL_VOTES = _newMinProposalVotes;
    
    emit MinProposalVotesUpdated(oldValue, _newMinProposalVotes);
}

function updateMinVotesToApprove(uint256 _newMinVotesToApprove) external onlyOwner {
    require(_newMinVotesToApprove > 0, "Valor debe ser mayor a 0");
    
    uint256 oldValue = MIN_VOTES_TO_APPROVE;
    MIN_VOTES_TO_APPROVE = _newMinVotesToApprove;
    
    emit MinVotesToApproveUpdated(oldValue, _newMinVotesToApprove);
}

function updateMinTokensToApprove(uint256 _newMinTokensToApprove) external onlyOwner {
    require(_newMinTokensToApprove > 0, "Valor debe ser mayor a 0");
    
    uint256 oldValue = MIN_TOKENS_TO_APPROVE;
    MIN_TOKENS_TO_APPROVE = _newMinTokensToApprove;
    
    emit MinTokensToApproveUpdated(oldValue, _newMinTokensToApprove);
}
```

Estas funciones permiten ajustar los parámetros del sistema de gobernanza según las necesidades de la comunidad, con validaciones que aseguran valores sensatos.

## Eventos del Contrato

### ProposalCreated

```solidity
event ProposalCreated(
    uint256 indexed proposalId,
    address indexed proposer,
    string description,
    uint256 startTime,
    uint256 endTime
);
```

Se emite cuando se crea una nueva propuesta, proporcionando información esencial para el seguimiento y notificaciones.

### VoteCast

```solidity
event VoteCast(
    uint256 indexed proposalId,
    address indexed voter,
    bool support,
    uint256 votes
);
```

Registra cada voto individual, facilitando el seguimiento en tiempo real y la auditoría del proceso de votación.

### ProposalCancelled

```solidity
event ProposalCancelled(uint256 indexed proposalId);
```

Se emite cuando una propuesta es cancelada, proporcionando transparencia sobre las decisiones de los proposers.

### Eventos Administrativos

```solidity
event NFTContractUpdated(address indexed oldContract, address indexed newContract);
event MinProposalVotesUpdated(uint256 indexed oldValue, uint256 indexed newValue);
event MinVotesToApproveUpdated(uint256 indexed oldValue, uint256 indexed newValue);
event MinTokensToApproveUpdated(uint256 indexed oldValue, uint256 indexed newValue);
```

Estos eventos proporcionan transparencia completa sobre todos los cambios administrativos realizados en el sistema.

## Consideraciones de Seguridad

### Validaciones Implementadas

1. **Verificación de Existencia**: Todas las funciones que manejan propuestas verifican que la propuesta existe antes de proceder.

2. **Control de Acceso**: Las funciones administrativas están protegidas por el modificador `onlyOwner`.

3. **Prevención de Votos Duplicados**: El mapeo `hasVoted` previene que una dirección vote múltiples veces en la misma propuesta.

4. **Validación Temporal**: Todas las operaciones respetan las ventanas de tiempo de las propuestas.

5. **Validación de Poder de Voto**: Se verifica la posesión de NFTs antes de permitir votar o crear propuestas.

### Prevención de Ataques Comunes

- **Spam de Propuestas**: El límite de 24 horas entre propuestas previene el abuso del sistema.
- **Manipulación de Votos**: El sistema de votación ponderado basado en NFTs reales previene la manipulación artificial.
- **Ataques de Reentrancy**: El contrato no realiza llamadas externas después de cambios de estado críticos.
- **Overflow/Underflow**: Utiliza Solidity 0.8.27 que incluye protecciones automáticas.

### Mecanismos Anti-Gaming

1. **Mínimo de NFTs para Proponer**: Requiere 10 NFTs para crear propuestas, asegurando compromiso.
2. **Triple Validación de Aprobación**: Combina mayoría simple, participación suficiente y poder de voto representativo.
3. **Ventanas de Tiempo Fijas**: Las propuestas tienen períodos de votación predefinidos que no pueden ser manipulados.

## Consideraciones de Gas

### Optimizaciones Implementadas

1. **Uso de `calldata`**: Los parámetros de string se pasan como `calldata` para reducir costos de gas.
2. **Almacenamiento Eficiente**: Las estructuras están optimizadas para minimizar el uso de slots de almacenamiento.
3. **Funciones de Consulta**: Las funciones `view` no consumen gas cuando se llaman externamente.

### Áreas de Alto Consumo de Gas

1. **Creación de Propuestas**: Almacenar toda la información de la propuesta puede ser costoso.
2. **Votación**: Actualizar múltiples mapeos y contadores en cada voto.

## Integración con Aplicaciones Externas

### Flujo de Gobernanza Típico

1. **Creación de Propuesta**: Un usuario con suficientes NFTs crea una propuesta con descripción y enlaces.
2. **Período de Votación**: Los poseedores de NFTs votan durante la ventana de tiempo especificada.
3. **Evaluación**: El sistema evalúa automáticamente si la propuesta cumple todos los criterios de aprobación.
4. **Ejecución**: Las propuestas aprobadas pueden ser implementadas por el equipo o la comunidad.

### APIs de Consulta

El contrato proporciona funciones de consulta completas que permiten a las aplicaciones frontend:
- Mostrar propuestas activas y sus resultados
- Calcular el poder de voto de los usuarios
- Verificar el estado de las propuestas
- Obtener estadísticas de participación

## Despliegue y Configuración

### Parámetros del Constructor

```solidity
constructor(address _nftContract) Ownable(msg.sender) {
    nftContract = IERC721(_nftContract);
}
```

- **nftContract**: Dirección del contrato de NFTs que determinará el poder de voto

### Consideraciones de Despliegue

1. **Contrato NFT**: Asegurar que la dirección del contrato NFT sea correcta y esté desplegada.
2. **Configuración Inicial**: Los parámetros por defecto pueden ser ajustados después del despliegue.
3. **Verificación**: Verificar el contrato en el explorador de bloques para transparencia.

## Conclusión

El contrato `DAO` representa una implementación robusta y bien diseñada de un sistema de gobernanza descentralizada. Su arquitectura flexible, sistema de votación ponderado y mecanismos de validación múltiple lo convierten en una solución confiable para comunidades que desean implementar toma de decisiones colectivas.

La combinación de validaciones de seguridad, prevención de spam y criterios de aprobación sofisticados asegura que las decisiones representen tanto la voluntad de la mayoría como la participación significativa de la comunidad. El sistema de eventos completo y las funciones de consulta detalladas proporcionan la transparencia necesaria para mantener la confianza en el proceso de gobernanza.

La flexibilidad para migrar a diferentes colecciones de NFTs y ajustar parámetros según las necesidades de la comunidad demuestra un enfoque maduro en el diseño de sistemas de gobernanza, asegurando que el contrato pueda evolucionar junto con el proyecto que representa.
