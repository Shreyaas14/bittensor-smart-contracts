// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IntersubjectivityToken is ERC20 {

    // stakeholder roles 
    enum Role { Miner, Validator, SubnetOwner }

    // stakeholder details
    struct Stakeholder {
        address user_account;
        Role role;
    }

    // array for all stakeholders
    Stakeholder[] public stakeholders;

    // virtual mapping for token allocation
    mapping(address => uint256) public userBalances;

    // timestamp for rebalancing
    uint256 public lastRebalance;

    // rebalance interval: 21600 seconds
    uint256 public constant REBALANCE_INTERVAL = 21600;

    // allocation percentages 
    // TODO: adjust
    uint256 public constant MINER_PERCENTAGE = 40;
    uint256 public constant VALIDATOR_PERCENTAGE = 40;
    uint256 public constant SUBNET_OWNER_PERCENTAGE = 20;

    // ensures tokens are supplied only once
    bool public tokensSupplied = false;

    constructor() ERC20("Subnet Intersubjectivity Token", "IST") {
        // constructor
    }

    function registerStakeholders(
        address[] calldata _stakeholders, 
        uint8[] calldata _roles
        ) external {
        require(stakeholders.length == 0, "Stakeholders already registered");
        require(_stakeholders.length == _roles.length, "wallet addr doesn't have a role in this subnet");
        require(_stakeholders.length > 0, "at least one stakeholder in subnet");

        _mint(address(this), initialSupply);

        // register each stakeholder
        for (uint256 i = 0; i < _stakeholders.length; i++) {
            require(_stakeholders[i] != address(0), "invalid addr");
            require(_roles[i] < 3, "invalid role val");
            stakeholders.push(Stakeholder({
                account: _stakeholders[i],
                role: Role(_roles[i])
            }));
        }
    }

    function supplyTokens(uint256 initialSupply) external {
        require(!tokensSupplied, "tokens already supplied");
        require(stakeholders.length > 0, "no stakeholders registered");
        tokensSupplied = true;

        // mint supply to contract
        _mint(address(this), initialSupply);

        // perform initial allocation, get last rebalance timestamp
        _rebalance();
        lastRebalance = block.timestamp;
    }

    // @dev override _transfer
    function _transfer(address, address, uint256) internal virtual override {
        revert("transfers are disabled!");
    }

    // rebalancing balances 
    function rebalance() external {
        require(block.timestamp >= lastRebalance + REBALANCE_INTERVAL, "rebalance not allowed");
        _rebalance();
        lastRebalance = block.timestamp;
    }

    // internal to calculate and update token delegation
    function _rebalance() internal {
        uint256 contractBalance = balanceOf(address(this));

        //count number of entities 
        // TODO: see if we can store in a data structure
        uint256 minerCount;
        uint256 validatorCount;
        uint256 subnetOwnerCount;
        for (uint256 i = 0; i < stakeholders.length; i++) {
            if (stakeholders[i].role == Role.Miner) {
                minerCount++;
            } else if (stakeholders[i].role == Role.Validator) {
                validatorCount++;
            } else if (stakeholders[i].role == Role.SubnetOwner) {
                subnetOwnerCount++;
            }
        }

        //token redistribution
        for (uint256 i = 0; i < stakeholders.length; i++) {
            uint256 allocation = 0;
            if (stakeholders[i].role == Role.Miner) {
                require(minerCount > 0, "No miners available");
                allocation = (contractBalance * MINER_PERCENTAGE) / 100 / minerCount;
            } else if (stakeholders[i].role == Role.Validator) {
                require(validatorCount > 0, "No validators available");
                allocation = (contractBalance * VALIDATOR_PERCENTAGE) / 100 / validatorCount;
            } else if (stakeholders[i].role == Role.SubnetOwner) {
                require(subnetOwnerCount > 0, "No subnet owners available");
                allocation = (contractBalance * SUBNET_OWNER_PERCENTAGE) / 100 / subnetOwnerCount;
            }
            userBalances[stakeholders[i].account] = allocation;
        }
    }

    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }
}
