// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";

import {DNft}            from "./DNft.sol";
import {Dyad}            from "./Dyad.sol";
import {VaultLicenser}   from "./VaultLicenser.sol";
import {Vault}           from "./Vault.sol";
import {IVaultManager}   from "../interfaces/IVaultManager.sol";

import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {ERC20}             from "@solmate/src/tokens/ERC20.sol";
import {SafeTransferLib}   from "@solmate/src/utils/SafeTransferLib.sol";
import {EnumerableSet}     from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VaultManagerV2 is IVaultManager {
  using EnumerableSet     for EnumerableSet.AddressSet;
  using FixedPointMathLib for uint;
  using SafeTransferLib   for ERC20;

  uint public constant MAX_VAULTS         = 6;
  uint public constant MIN_COLLAT_RATIO   = 1.5e18; // 150% // Collaterization
  uint public constant LIQUIDATION_REWARD = 0.2e18; //  20%

  DNft          public immutable dNft;
  Dyad          public immutable dyad;
  VaultLicenser public immutable vaultLicenser;

  mapping (uint => EnumerableSet.AddressSet) internal vaults; 
  mapping (uint/* id */ => uint/* block */)  public   lastDeposit;

  modifier isDNftOwner(uint id) {
    if (dNft.ownerOf(id) != msg.sender) revert NotOwner();    _;
  }
  modifier isValidDNft(uint id) {
    if (dNft.ownerOf(id) == address(0)) revert InvalidDNft(); _;
  }

  constructor(
    DNft          _dNft,
    Dyad          _dyad,
    VaultLicenser _vaultLicenser
  ) {
    dNft          = _dNft;
    dyad          = _dyad;
    vaultLicenser = _vaultLicenser;
  }

  /// @inheritdoc IVaultManager
  function add(
      uint    id,
      address vault
  ) 
    external
      isDNftOwner(id)
  {
    if (!vaultLicenser.isLicensed(vault))   revert VaultNotLicensed();
    if ( vaults[id].length() >= MAX_VAULTS) revert TooManyVaults();
    if (!vaults[id].add(vault))             revert VaultAlreadyAdded();
    emit Added(id, vault);
  }

  /// @inheritdoc IVaultManager
  function remove(
      uint    id,
      address vault
  ) 
    external
      isDNftOwner(id)
  {
    if (Vault(vault).id2asset(id) > 0) revert VaultHasAssets();
    if (!vaults[id].remove(vault))     revert VaultNotAdded();
    emit Removed(id, vault);
  }

  /// @inheritdoc IVaultManager
  function deposit(
    uint    id,
    address vault,
    uint    amount
  ) 
    external 
      isDNftOwner(id)
  {
    lastDeposit[id] = block.number;
    Vault _vault = Vault(vault);
    _vault.asset().safeTransferFrom(msg.sender, address(vault), amount);
    _vault.deposit(id, amount);
  }

  /// @inheritdoc IVaultManager
  function withdraw(
    uint    id,
    address vault,
    uint    amount,
    address to
  ) 
    public
      isDNftOwner(id)
  {
    if (lastDeposit[id] == block.number) revert CanNotWithdrawInSameBlock();
    Vault _vault = Vault(vault);
    _vault.withdraw(id, to, amount); // changes `exo` or `kero` value and `cr`
    (uint exoValue, uint keroValue) = getVaultsValues(id);
    uint mintedDyad = dyad.mintedDyad(address(this), id);
    if (exoValue < mintedDyad) revert NotEnoughExoCollat();
    uint cr = _collatRatio(mintedDyad, exoValue+keroValue);
    if (cr < MIN_COLLAT_RATIO) revert CrTooLow(); 
    console.log("post withdraw --- cr: ", cr/1e15, "exo: ", exoValue/1e18);
  }

  /// @inheritdoc IVaultManager
  function mintDyad(
    uint    id,
    uint    amount,
    address to
  )
    external 
      isDNftOwner(id)
  {
    dyad.mint(id, to, amount); // changes `mintedDyad` and `cr`
    (uint exoValue, uint keroValue) = getVaultsValues(id);
    uint mintedDyad = dyad.mintedDyad(address(this), id);
    if (exoValue < mintedDyad) revert NotEnoughExoCollat();
    uint cr = _collatRatio(mintedDyad, exoValue+keroValue);
    if (cr < MIN_COLLAT_RATIO) revert CrTooLow(); 
    console.log("post mint --- cr: ", cr/1e15, "exo: ", exoValue/1e18);
    emit MintDyad(id, amount, to);
  }

  /// @inheritdoc IVaultManager
  function burnDyad(
    uint id,
    uint amount
  ) 
    external 
      isValidDNft(id)
  {
    dyad.burn(id, msg.sender, amount);
    emit BurnDyad(id, amount, msg.sender);
  }

  /// @inheritdoc IVaultManager
  function redeemDyad(
    uint    id,
    address vault,
    uint    amount,
    address to
  )
    external 
      isDNftOwner(id)
    returns (uint) { 
      dyad.burn(id, msg.sender, amount);
      Vault _vault = Vault(vault);
      uint asset = amount 
                    * (10**(_vault.oracle().decimals() + _vault.asset().decimals())) 
                    / _vault.assetPrice() 
                    / 1e18;
      withdraw(id, vault, asset, to);
      emit RedeemDyad(id, vault, amount, to);
      return asset;
  }

  /// @inheritdoc IVaultManager
  function liquidate(
    uint id,
    uint to
  ) 
    external 
      isValidDNft(id)
      isValidDNft(to)
    {
      uint cr = collatRatio(id);
      if (cr >= MIN_COLLAT_RATIO) revert CrTooHigh();
      dyad.burn(id, msg.sender, dyad.mintedDyad(address(this), id));

      uint cappedCr               = cr < 1e18 ? 1e18 : cr;
      uint liquidationEquityShare = (cappedCr - 1e18).mulWadDown(LIQUIDATION_REWARD);
      uint liquidationAssetShare  = (liquidationEquityShare + 1e18).divWadDown(cappedCr);

      uint numberOfVaults = vaults[id].length();
      for (uint i = 0; i < numberOfVaults; i++) {
          Vault vault      = Vault(vaults[id].at(i));
          uint  collateral = vault.id2asset(id).mulWadUp(liquidationAssetShare);
          vault.move(id, to, collateral);
      }
      emit Liquidate(id, msg.sender, to);
  }

  function collatRatio(
    uint id
  )
    public 
    view
    returns (uint) {
      uint mintedDyad = dyad.mintedDyad(address(this), id);
      uint totalValue = getTotalValue(id);
      return _collatRatio(mintedDyad, totalValue);
  }

  /// @dev Why do we have the same function with different arguments?
  ///      Sometimes we can re-use the `mintedDyad` and `totalValue` values,
  ///      Calculating them is expensive, so we can re-use the cached values.
  function _collatRatio(
    uint mintedDyad, 
    uint totalValue // in USD
  )
    internal 
    pure
    returns (uint) {
      if (mintedDyad == 0) return type(uint).max;
      return totalValue.divWadDown(mintedDyad);
  }

  function getTotalValue( // in USD
    uint id
  ) 
    public 
    view
    returns (uint) {
      (uint exoValue, uint keroValue) = getVaultsValues(id);
      return exoValue + keroValue;
  }

  function getVaultsValues( // in USD
    uint id
  ) 
    public 
    view
    returns (
      uint exoValue, // exo := exogenous (non-kerosene)
      uint keroValue
    ) {
      uint numberOfVaults = vaults[id].length(); 

      for (uint i = 0; i < numberOfVaults; i++) {
        Vault vault = Vault(vaults[id].at(i));
        if (vaultLicenser.isLicensed(address(vault))) {
          if (vaultLicenser.isKerosene(address(vault))) {
            keroValue += vault.getUsdValue(id);
          } else {
            exoValue  += vault.getUsdValue(id);
          }
        }
      }
  }

  // ----------------- MISC ----------------- //

  function getVaults(
    uint id
  ) 
    external 
    view 
    returns (address[] memory) {
      return vaults[id].values();
  }

  function hasVault(
    uint    id,
    address vault
  ) 
    external 
    view 
    returns (bool) {
      return vaults[id].contains(vault);
  }
}
