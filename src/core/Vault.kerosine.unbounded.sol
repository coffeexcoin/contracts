// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {KerosineVault} from "./Vault.kerosine.sol";
import {VaultManager} from "./VaultManager.sol";
import {Vault} from "./Vault.sol";
import {Dyad} from "./Dyad.sol";
import {KerosineManager} from "./KerosineManager.sol";
import {BoundedKerosineVault} from "./Vault.kerosine.bounded.sol";
import {KerosineDenominator} from "../staking/KerosineDenominator.sol";

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

contract UnboundedKerosineVault is KerosineVault {
    using SafeTransferLib for ERC20;

    KerosineDenominator public kerosineDenominator;

    constructor(VaultManager _vaultManager, ERC20 _asset, Dyad _dyad, KerosineManager _kerosineManager)
        KerosineVault(_vaultManager, _asset, _dyad, _kerosineManager)
    {}

    function withdraw(uint256 id, address to, uint256 amount) external onlyVaultManager {
        id2asset[id] -= amount;
        asset.safeTransfer(to, amount);
        emit Withdraw(id, to, amount);
    }

    function setDenominator(KerosineDenominator _kerosineDenominator) external onlyOwner {
        kerosineDenominator = _kerosineDenominator;
    }

    function assetPrice() public view override returns (uint256) {
        uint256 tvl;
        address[] memory vaults = kerosineManager.getVaults();
        uint256 numberOfVaults = vaults.length;
        for (uint256 i = 0; i < numberOfVaults; i++) {
            Vault vault = Vault(vaults[i]);
            tvl += vault.asset().balanceOf(address(vault)) * vault.assetPrice() * 1e18
                / (10 ** vault.asset().decimals()) / (10 ** vault.oracle().decimals());
        }
        uint256 numerator = tvl - dyad.totalSupply();
        uint256 denominator = kerosineDenominator.denominator();
        return numerator * 1e8 / denominator;
    }
}
