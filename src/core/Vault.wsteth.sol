// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {VaultManager} from "./VaultManager.sol";
import {ChainlinkOracleVault} from "./ChainlinkOracleVault.sol";
import {IWstETH} from "../interfaces/IWstETH.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";

contract VaultWstEth is ChainlinkOracleVault {

    constructor(
        VaultManager _vaultManager,
        ERC20 _asset,
        IAggregatorV3 _oracle
    ) ChainlinkOracleVault(_vaultManager, _asset, _oracle) {}

    function _applyAssetPriceModifier(
        uint256 oracleAnswer
    ) internal view override returns (uint256) {
        return (oracleAnswer * IWstETH(address(asset)).stEthPerToken()) / 1e18;
    }
}
