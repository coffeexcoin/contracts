// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {VaultManager} from "./VaultManager.sol";
import {IDNft} from "../interfaces/IDNft.sol";
import {IVault} from "../interfaces/IVault.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";

abstract contract Vault is IVault {
    using SafeTransferLib for ERC20;
    using SafeCast for int256;
    using FixedPointMathLib for uint256;

    uint256 public constant STALE_DATA_TIMEOUT = 90 minutes;

    VaultManager public immutable vaultManager;
    ERC20 public immutable asset;

    mapping(uint256 => uint256) public id2asset;

    modifier onlyVaultManager() {
        if (msg.sender != address(vaultManager)) revert NotVaultManager();
        _;
    }

    constructor(VaultManager _vaultManager, ERC20 _asset) {
        vaultManager = _vaultManager;
        asset = _asset;
    }

    function deposit(uint256 id, uint256 amount) external virtual onlyVaultManager {
        id2asset[id] += amount;
        emit Deposit(id, amount);
    }

    function withdraw(uint256 id, address to, uint256 amount) external virtual onlyVaultManager {
        id2asset[id] -= amount;
        asset.safeTransfer(to, amount);
        emit Withdraw(id, to, amount);
    }

    function move(uint256 from, uint256 to, uint256 amount) external onlyVaultManager {
        id2asset[from] -= amount;
        id2asset[to] += amount;
        emit Move(from, to, amount);
    }

    function getUsdValue(uint256 id) external view virtual returns (uint256);
}
