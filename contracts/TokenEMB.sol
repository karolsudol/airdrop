//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC20 TokenEMB without fixed suply and standart 18 decimals 
 *
 * @notice A simple ERC20 token that will be distributed by the protocol
 */
contract TokenEMB is ERC20, Ownable {
    event Minted(address account, uint256 amount, uint256 ts);

    address private _owner;

    /**
     * @notice token instance constructor
     *
     * @param name name of the token instance
     * @param symbol symbol of the token instance
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _owner = msg.sender;
    }

    /**
     * @notice add token to the supply and address balance
     *
     * @param account account to mint tokens to
     * @param amount amount of token units to mint
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
