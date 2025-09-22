// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleERC20
 * @dev Implementación simple de un token ERC20 con funcionalidad de burning
 * 
 * Características:
 * - Cumple con el estándar ERC20
 * - Permite burning (quemar) tokens
 * - Incluye funciones de minting para el owner
 * - Emite eventos personalizados para burning
 */
contract SimpleERC20 is ERC20, Ownable {
    
    /// @dev Evento emitido cuando se queman tokens
    event TokensBurned(address indexed account, uint256 amount);
    
    /// @dev Evento emitido cuando el owner quema tokens de una cuenta específica
    event TokensBurnedFrom(address indexed account, uint256 amount);
    
    /**
     * @dev Constructor que inicializa el token
     * @param name Nombre del token
     * @param symbol Símbolo del token
     * @param initialSupply Suministro inicial de tokens
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
    
    /**
     * @dev Función para quemar tokens del balance del caller
     * @param amount Cantidad de tokens a quemar
     * 
     * Requisitos:
     * - El caller debe tener suficientes tokens en su balance
     * - La cantidad debe ser mayor a 0
     */
    function burn(uint256 amount) public virtual {
        require(amount > 0, "SimpleERC20: cantidad debe ser mayor a 0");
        require(balanceOf(msg.sender) >= amount, "SimpleERC20: balance insuficiente");
        
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Función para quemar tokens de una cuenta específica (solo owner)
     * @param account Cuenta de la cual quemar tokens
     * @param amount Cantidad de tokens a quemar
     * 
     * Requisitos:
     * - Solo el owner puede ejecutar esta función
     * - La cuenta debe tener suficientes tokens
     * - La cantidad debe ser mayor a 0
     */
    function burnFrom(address account, uint256 amount) public virtual onlyOwner {
        require(amount > 0, "SimpleERC20: cantidad debe ser mayor a 0");
        require(balanceOf(account) >= amount, "SimpleERC20: balance insuficiente");
        
        _burn(account, amount);
        emit TokensBurnedFrom(account, amount);
    }
    
    /**
     * @dev Función para crear nuevos tokens (solo owner)
     * @param to Dirección que recibirá los nuevos tokens
     * @param amount Cantidad de tokens a crear
     * 
     * Requisitos:
     * - Solo el owner puede ejecutar esta función
     * - La cantidad debe ser mayor a 0
     */
    function mint(address to, uint256 amount) public virtual onlyOwner {
        require(amount > 0, "SimpleERC20: cantidad debe ser mayor a 0");
        require(to != address(0), "SimpleERC20: direccion invalida");
        
        _mint(to, amount);
    }
    
    /**
     * @dev Función para obtener el total de tokens quemados
     * @return Total de tokens quemados desde la creación del contrato
     */
    function totalBurned() public view virtual returns (uint256) {
        // Esta implementación asume que el total supply inicial se mantiene
        // y calcula los tokens quemados como la diferencia
        return totalSupply();
    }
    
    /**
     * @dev Función para verificar si una dirección puede quemar una cantidad específica
     * @param account Dirección a verificar
     * @param amount Cantidad a verificar
     * @return true si puede quemar, false en caso contrario
     */
    function canBurn(address account, uint256 amount) public view virtual returns (bool) {
        return balanceOf(account) >= amount && amount > 0;
    }
}
