//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title EMB Token
/// @author kadro
/// @notice A simple ERC20 token that will be distributed by the protocol
contract EMBToken is ERC20 {
    address public owner;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
