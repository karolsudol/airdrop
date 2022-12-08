//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title EMB Token
/// @author
/// @notice A simple ERC20 token that will be distributed by the protocol
contract Token is ERC20, Ownable {
    event Minted(address account, uint256 amount, uint256 ts);

    /**
     * @notice token instance constructor
     *
     * @param _name name of the token instance
     * @param _symbol symbol of the token instance
     */
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
