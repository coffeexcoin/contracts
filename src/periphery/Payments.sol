// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VaultManager} from "../core/VaultManager.sol";
import {Vault}        from "../core/Vault.sol";
import {IWETH}        from "../interfaces/IWETH.sol";
import {DNft}         from "../core/DNft.sol";

import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib}   from "@solmate/src/utils/SafeTransferLib.sol";
import {Owned}             from "@solmate/src/auth/Owned.sol";
import {ERC20}             from "@solmate/src/tokens/ERC20.sol";

contract Payments is Owned(msg.sender) {
  using FixedPointMathLib for uint;
  using SafeTransferLib   for ERC20;
  using SafeTransferLib   for address;

  error NotDnftOwner();

  DNft         public immutable dnft;
  VaultManager public immutable vaultManager;
  IWETH        public immutable weth;

  uint256    public depositFee;
  uint256    public mintFee;
  
  modifier onlyDnftOwner(uint id) {
    if (dnft.ownerOf(id) != msg.sender) {
      revert NotDnftOwner();
    }
    _;
  }

  constructor(
    VaultManager _vaultManager,
    IWETH        _weth,
    DNft         _dnft
  ) { 
    vaultManager = _vaultManager;
    weth         = _weth;
    dnft         = _dnft;
  }

  function setDepositFee(
    uint256 _fee
  ) 
    external 
    onlyOwner 
  {
    depositFee = _fee;
  }

  function setMintFee(
    uint256 _fee
  ) 
    external 
    onlyOwner 
  {
    mintFee = _fee;
  }

  // Calls the Vault Manager `deposit` function, but takes a fee.
  function deposit(
    uint    id,
    address vault,
    uint    amount
  ) 
    external 
    onlyDnftOwner(id)
  {
    ERC20 asset = Vault(vault).asset();
    asset.safeTransferFrom(msg.sender, address(this), amount);

    _deposit(id, vault, amount);
  }

  function depositETH(
    uint    id,
    address vault
  ) 
    external 
    payable
    onlyDnftOwner(id)
  {
    weth.deposit{value: msg.value}();
    _deposit(id, vault, msg.value);
  }

  function mintDyad(
    uint256 id,
    uint256 amount,
    address to
  ) external onlyDnftOwner(id) {
    if (mintFee > 0) {
      uint feeAmount = amount.mulWadDown(mintFee);
      vaultManager.mintDyad(id, feeAmount, address(this));
    }
    vaultManager.mintDyad(id, amount, to);
  }

  function _deposit(
    uint    id,
    address vault,
    uint    amount
  ) 
    internal 
  {
    ERC20 asset = Vault(vault).asset();

    uint feeAmount = amount.mulWadDown(depositFee);
    uint netAmount = amount - feeAmount;
    asset.approve(address(vaultManager), netAmount);
    vaultManager.deposit(id, vault, netAmount);
  }

  function drain(address to)
    external
      onlyOwner
  {
    to.safeTransferETH(address(this).balance);
  }

  function drain(address to, address token) external {
    ERC20(token).safeTransfer(to, ERC20(token).balanceOf(address(this)));
  }
}
