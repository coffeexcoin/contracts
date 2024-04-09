// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {VaultManager} from "./VaultManager.sol";
import {Vault} from "./Vault.sol";
import {Dyad} from "./Dyad.sol";
import {KerosineManager} from "./KerosineManager.sol";
import {BoundedKerosineVault} from "./Vault.kerosine.bounded.sol";
import {KerosineDenominator} from "../staking/KerosineDenominator.sol";
import {Owned} from "@solmate/src/auth/Owned.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";

contract UnboundedKerosineVault is Vault, Owned {

    Dyad public immutable dyad;
    KerosineManager public immutable kerosineManager;

    KerosineDenominator public kerosineDenominator;

    constructor(
        VaultManager _vaultManager,
        ERC20 _asset,
        Dyad _dyad,
        KerosineManager _kerosineManager
    ) Vault(_vaultManager, _asset) Owned(tx.origin) {
        dyad = _dyad;
        kerosineManager = _kerosineManager;
    } 

    function setDenominator(
        KerosineDenominator _kerosineDenominator
    ) external onlyOwner {
        kerosineDenominator = _kerosineDenominator;
    }

    function getUsdValue(uint256 id) public view override returns (uint256) {
        return id2asset[id] * assetPrice() / 1e8;
    }

    function assetPrice() public view returns (uint256) {
        uint256 tvl;
        address[] memory vaults = kerosineManager.getVaults();
        uint256 numberOfVaults = vaults.length;
        for (uint256 i = 0; i < numberOfVaults; i++) {
            Vault vault = Vault(vaults[i]);
            tvl +=
                (vault.asset().balanceOf(address(vault)) *
                    vault.assetPrice() *
                    1e18) /
                (10 ** vault.asset().decimals()) /
                (10 ** vault.oracle().decimals());
        }
        uint256 numerator = tvl - dyad.totalSupply();
        uint256 denominator = kerosineDenominator.denominator();
        return (numerator * 1e8) / denominator;
    }
}
