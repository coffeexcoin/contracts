// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {VaultManager} from "./VaultManager.sol";
import {Dyad} from "./Dyad.sol";
import {KerosineManager} from "./KerosineManager.sol";
import {IDNft} from "../interfaces/IDNft.sol";
import {IVault} from "../interfaces/IVault.sol";

import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {Owned} from "@solmate/src/auth/Owned.sol";

abstract contract KerosineVault is IVault, Owned(msg.sender) {
    using SafeTransferLib for ERC20;

    VaultManager public immutable vaultManager;
    ERC20 public immutable asset;
    Dyad public immutable dyad;
    KerosineManager public immutable kerosineManager;

    mapping(uint256 => uint256) public id2asset;

    modifier onlyVaultManager() {
        if (msg.sender != address(vaultManager)) revert NotVaultManager();
        _;
    }

    constructor(VaultManager _vaultManager, ERC20 _asset, Dyad _dyad, KerosineManager _kerosineManager) {
        vaultManager = _vaultManager;
        asset = _asset;
        dyad = _dyad;
        kerosineManager = _kerosineManager;
    }

    function deposit(uint256 id, uint256 amount) public virtual onlyVaultManager {
        id2asset[id] += amount;
        emit Deposit(id, amount);
    }

    function move(uint256 from, uint256 to, uint256 amount) external onlyVaultManager {
        id2asset[from] -= amount;
        id2asset[to] += amount;
        emit Move(from, to, amount);
    }

    function getUsdValue(uint256 id) public view returns (uint256) {
        return id2asset[id] * assetPrice() / 1e8;
    }

    function assetPrice() public view virtual returns (uint256);
}
