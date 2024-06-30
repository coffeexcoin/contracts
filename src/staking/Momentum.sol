// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC721Enumerable} from "forge-std/interfaces/IERC721.sol";
import {IVaultManager} from "./interfaces/IVaultManager.sol";
import {IVault} from "./interfaces/IVault.sol";

struct NoteMomentumData {
    // uint40 supports 34,000 years before overflow
    uint40 lastAction;
    // uint96 max is 79b at 18 decimals which is more than total kero supply
    uint96 keroseneDeposited; 
    // uint120 supports deposit of entire kerosene supply by a single note for ~42 years before overflow
    uint120 lastMomentum; 
}

contract Momentum is IERC20 {
    error TransferNotAllowed();
    error NotVaultManager();

    IERC20 public immutable KEROSENE;
    IVaultManager public immutable VAULT_MANAGER;
    IVault public immutable KEROSENSE_VAULT;
    IERC721Enumerable public immutable DNFT;

    string public constant name = "Kerosene Momentum";
    string public constant symbol = "kMOM";
    uint8 public constant decimals = 18;

    uint40 globalLastUpdate;
    uint192 globalLastKeroseneInVault;

    mapping(uint256 => NoteMomentumData) public noteData;

    constructor(address vaultManager, address keroseneVault, address dnft) {
        VAULT_MANAGER = IVaultManager(vaultManager);
        KEROSENSE_VAULT = IVault(keroseneVault);
        KEROSENE = IERC20(KEROSENSE_VAULT.asset());
        DNFT = IERC721Enumerable(dnft);
    }

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256) {
        uint256 timeElapsed = block.timestamp - globalLastUpdate;
        uint256 keroseneInVault = KEROSENE.balanceOf(address(KEROSENSE_VAULT));
        uint256 momentumAccrued = timeElapsed * keroseneInVault;
        return globalLastKeroseneInVault + momentumAccrued;
    }

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256) {
        uint256 totalMomentum;
        uint256 noteBalance = DNFT.balanceOf(account);

        for (uint256 i = 0; i < noteBalance; i++) {
            uint256 noteId = DNFT.tokenOfOwnerByIndex(account, i);
            totalMomentum += _currentMomentum(noteId);
        }

        return totalMomentum;
    }

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool) {
        revert TransferNotAllowed();
    }

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return 0;
    }

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool) {
        revert TransferNotAllowed();
    }

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        revert TransferNotAllowed();
    }

    function keroseneDeposited(uint256 noteId, uint256 totalKerosene) external {
        if (msg.sender != address(VAULT_MANAGER)) {
            revert NotVaultManager();
        }

        NoteMomentumData memory lastUpdate = noteData[noteId];
        uint256 totalKeroseneInVault = KEROSENE.balanceOf(
            address(KEROSENE_VAULT)
        );

        uint256 newMomentum = _currentMomentum(
            noteId,
            totalKeroseneInVault,
            lastUpdate
        );

        noteData[noteId] = NoteMomentumData({
            lastAction: uint40(block.timestamp),
            keroseneDeposited: uint108(
                KEROSENE.balanceOf(address(KEROSENE_VAULT))
            ),
            lastMomentum: uint108(newMomentum)
        });

        globalLastUpdate = uint40(block.timestamp);
        globalLastKeroseneInVault = uint192(totalKerosene);

        emit Transfer(
            address(0),
            address(noteId),
            newMomentum - lastUpdate.lastMomentum
        );
    }

    function keroseneWithdrawn(uint256 noteId, uint256 totalKerosene) external {
        if (msg.sender != address(VAULT_MANAGER)) {
            revert NotVaultManager();
        }

        // TODO: Implement slashing of momentum on withdraw
        // Slashing amount is calculated by
        // (KEROSENE withdrawal / total Note KEROSENE deposited) * (momentum quantity)
    }

    function _currentMomentum(
        uint256 noteId,
        uint256 totalKeroseneInVault,
        NoteMomentumData memory lastUpdate
    ) internal view returns (uint256) {
        uint256 noteKerosene = KEROSENE_VAULT.id2asset(noteId);
        uint256 userShare = (noteKerosene * 1e18) / totalKeroseneInVault;
        uint256 timePassed = block.timestamp - lastUpdate.lastAction;
        uint256 momentumAccrued = timePassed * userShare;

        return lastUpdate.lastMomentum + momentumAccrued;
    }
}
