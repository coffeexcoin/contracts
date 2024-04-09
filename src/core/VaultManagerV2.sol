// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {VaultManager} from "./VaultManager.sol";
import {DNft} from "../../src/core/DNft.sol";
import {Dyad} from "../../src/core/Dyad.sol";
import {Licenser} from "../../src/core/Licenser.sol";

contract VaultManagerV2 is VaultManager {
    // id => (block number => deposited)
    mapping(uint256 => mapping(uint256 => bool)) public deposited;

    constructor(DNft _dNft, Dyad _dyad, Licenser _licenser) VaultManager(_dNft, _dyad, _licenser) {}

    function deposit(uint256 id, address vault, uint256 amount) public override isValidDNft(id) {
        deposited[id][block.number] = true;
        super.deposit(id, vault, amount);
    }

    function withdraw(uint256 id, address vault, uint256 amount, address to) public override isDNftOwner(id) {
        if (!deposited[id][block.number]) revert DepositedInThisBlock();
        super.withdraw(id, vault, amount, to);
    }
}
