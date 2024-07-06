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
    uint96 amount;
    uint96 claimed;
}

contract TimelockWethVault is IVault {
    using SafeTransferLib for ERC20;
    using SafeCast for int;
    using FixedPointMathLib for uint;

    error InsufficientFunds();
    error TimelockExists();

    uint public constant STALE_DATA_TIMEOUT = 90 minutes;

    uint public constant VEST_TIME = 180 days;

    IVaultManager public immutable vaultManager;
    ERC20 public immutable asset;
    IAggregatorV3 public immutable oracle;

    mapping(uint256 noteId => LinearVest vesting) private vesting;
    mapping(uint256 => uint256) private stored;

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

    function deposit(uint256 id, uint amount) external onlyVaultManager {
        stored[id] += amount;
        emit Deposit(id, amount);
    }

    function timelock(uint id, uint amount) external onlyVaultManager {
        if (vesting[id].start > 0) {
            revert TimelockExists();
        }

        vesting[id] = LinearVest({
            start: uint40(block.timestamp),
            amount: uint96(amount),
            claimed: 0
        });

        emit Deposit(id, amount);
    }

    function withdraw(
        uint id,
        address to,
        uint amount
    ) external onlyVaultManager {
        uint256 storedAmount = stored[id];
        if (amount > storedAmount) {
            _claimVest(id);
        }
        if (amount > storedAmount) {
            revert InsufficientFunds();
        }

        stored[id] = storedAmount - amount;
        asset.safeTransfer(to, amount);
        emit Withdraw(id, to, amount);
    }

    function move(uint from, uint to, uint amount) external onlyVaultManager {
        if (amount > stored[from]) {
            _claimVest(from);
        }
        stored[from] -= amount;
        stored[to] += amount;
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

    function id2asset(uint256 noteId) public view returns (uint256) {
        LinearVest memory vest = vesting[noteId];
        uint256 storedAmount = stored[noteId];
        return storedAmount + _vestedAmount(vest) - vest.claimed;
    }

    function _claimVest(uint256 noteId) private {
        LinearVest memory vest = vesting[noteId];

        if (vest.claimed < vest.amount) {
            uint256 vestedAmount = _vestedAmount(vest);
            stored[noteId] += vestedAmount - vest.claimed;
            vesting[noteId].claimed = uint72(vestedAmount);
        }
    }

    function _vestedAmount(
        LinearVest memory vest
    ) private view returns (uint256) {
        uint256 elapsed = block.timestamp - vest.start;
        if (elapsed > VEST_TIME) {
            return vest.amount;
        } else {
            return elapsed.mulDivDown(vest.amount, VEST_TIME);
        }
    }
}
