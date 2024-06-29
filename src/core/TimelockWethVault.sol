// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IVaultManager} from "../interfaces/IVaultManager.sol";
import {IDNft} from "../interfaces/IDNft.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";
import {IWETH} from "../interfaces/IWETH.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";

/*
Use odd sized variables here to pack into a single storage slot
uint88 max amount is 309,485,009.821345068724781055 ETH which is almost 3x the entire
ETH supply. This should be enough for any vesting contract.
*/
struct LinearVest {
    uint40 start;
    uint40 lastUpdate;
    uint88 unvestedAmount; 
    uint88 vestedAmount;
}

contract TimelockWethVault is IVault {
    using SafeTransferLib for ERC20;
    using SafeCast for int;
    using FixedPointMathLib for uint;

    error InsufficientFunds();

    uint public constant STALE_DATA_TIMEOUT = 90 minutes;

    uint public constant VEST_TIME = 180 days;

    IVaultManager public immutable vaultManager;
    ERC20 public immutable asset;
    IAggregatorV3 public immutable oracle;

    mapping(uint256 noteId => LinearVest vesting) private vesting;

    modifier onlyVaultManager() {
        if (msg.sender != address(vaultManager)) revert NotVaultManager();
        _;
    }

    constructor(
        IVaultManager _vaultManager,
        ERC20 _asset,
        IAggregatorV3 _oracle
    ) {
        vaultManager = _vaultManager;
        asset = _asset;
        oracle = _oracle;
    }

    function deposit(uint id, uint amount) external onlyVaultManager {
        _computeAndUpdateVested(noteId);
        vesting[noteId].unvestedAmount += amount;
        vesting[noteId].start = block.timestamp;
        // TODO: UPDATE VESTING
        emit Deposit(id, amount);
    }

    function withdraw(
        uint id,
        address to,
        uint amount
    ) external onlyVaultManager {
        _computeAndUpdateVested(noteId);
        if (amount > vesting[noteId].vestedAmount) {
            revert InsufficientFunds(); 
        }
        
        asset.safeTransfer(to, amount);
        emit Withdraw(id, to, amount);
    }

    function move(uint from, uint to, uint amount) external onlyVaultManager {
        id2asset[from] -= amount;
        id2asset[to] += amount;
        emit Move(from, to, amount);
    }

    function getUsdValue(uint id) external view returns (uint) {
        return
            (id2asset(id) * assetPrice() * 1e18) /
            10 ** oracle.decimals() /
            10 ** asset.decimals();
    }

    function assetPrice() public view returns (uint) {
        (, int256 answer, , uint256 updatedAt, ) = oracle.latestRoundData();
        if (block.timestamp > updatedAt + STALE_DATA_TIMEOUT)
            revert StaleData();
        return answer.toUint256();
    }

    function _computeAndUpdateVested(uint256 noteId) internal {

    }

    function id2asset(uint256 noteId) public view returns (uint256) {
        LinearVest memory vest = vesting[noteId];
        if (vest.start + VEST_TIME < block.timestamp) {
            return vest.unvestedAmount + vest.vestedAmount;
        }
        // compute the vested amount as the sum of the stored vested amount and the amount that has vested since the last update
        uint256 vestedAmount = vest.vestedAmount + ((block.timestamp - vest.lastUpdate) * vest.unvestedAmount / VEST_TIME);
        return vestedAmount;
    }
}
