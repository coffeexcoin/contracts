// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {VaultManager} from "./VaultManager.sol";
import {Vault} from "./Vault.sol";
import {IVault} from "../interfaces/IVault.sol";
import {Owned} from "@solmate/src/auth/Owned.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";

contract BoundedKerosineVault is Vault, Owned {
    error NotWithdrawable(uint256 id, address to, uint256 amount);

    IVault public unboundedKerosineVault;
    uint256 public deposits;

    constructor(
        VaultManager _vaultManager,
        ERC20 _asset
    ) Vault(_vaultManager, _asset) Owned(tx.origin) {}

    function setUnboundedKerosineVault(
        IVault _unboundedKerosineVault
    ) external onlyOwner {
        unboundedKerosineVault = _unboundedKerosineVault;
    }

    function deposit(uint256 id, uint256 amount) public override {
        deposits += amount;
        super.deposit(id, amount);
    }

    function withdraw(
        uint256 id,
        address to,
        uint256 amount
    ) external override {
        revert NotWithdrawable(id, to, amount);
    }

    function getUsdValue(uint256 id) public view override returns (uint256) {
        return id2asset[id] * assetPrice() / 1e8;
    }

    function assetPrice() public view returns (uint256) {
        return unboundedKerosineVault.assetPrice() * 2;
    }
}
