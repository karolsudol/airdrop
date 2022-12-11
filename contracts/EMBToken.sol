//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ERC20 TokenEMB without fixed suply and standart 18 decimals
 *
 * @notice A simple ERC20 token that will be distributed by the protocol
 */
contract EMBToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice token instance constructor
     *
     * @param _name name of the token instance
     * @param _symbol symbol of the token instance
     *
     * @dev owner is granted admin and minter roles
     */
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @notice add token to the supply and address balance
     *
     * @param account account to mint tokens to
     * @param amount amount of token units to mint
     */
    function mint(address account, uint256 amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(account, amount);
    }
}
