// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Vault} from "./Vault.sol";
import {VaultManager} from "./VaultManager.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";

contract ChainlinkOracleVault is Vault {

    IAggregatorV3 public immutable oracle;

    constructor(VaultManager _vaultManager, ERC20 _asset, IAggregatorV3 _oracle) Vault(_vaultManager, _asset) {
        oracle = _oracle;
    }

    function getUsdValue(uint256 id) public view override returns (uint256) {
        return (id2asset[id] * assetPrice() * 1e18) / 10 ** oracle.decimals() / 10 ** asset.decimals();
    }

    function assetPrice() public view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = oracle.latestRoundData();
        if (block.timestamp > updatedAt + STALE_DATA_TIMEOUT) {
            revert StaleData();
        }
        return _applyAssetPriceModifier(answer.toUint256());
    }

    function _applyAssetPriceModifier(uint256 oracleAnswer) internal view virtual returns (uint256) {
        return oracleAnswer;
    }
}
