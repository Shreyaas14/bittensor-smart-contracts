// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IntersubjectivityToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Intersubjectivity Token", "IST") {
        
        // Mint tokens to the deployer (the subnet?)
        _mint(msg.sender, initialSupply);
    }
}
