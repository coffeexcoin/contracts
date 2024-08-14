// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import {Parameters}   from "../../src/params/Parameters.sol";
import {IWETH}        from "../../src/interfaces/IWETH.sol";
import {DNft}         from "../../src/core/DNft.sol";
import {VaultManager} from "../../src/core/VaultManager.sol";
import {Payments}     from "../../src/periphery/Payments.sol";

contract DeployPayments is Script, Parameters {
  function run() public {
    vm.startBroadcast();  // ----------------------

    Payments payments = new Payments(
      VaultManager(0xfaa785c041181a54c700fD993CDdC61dbBfb420f), 
      IWETH(MAINNET_WETH),
      DNft(MAINNET_DNFT)
    );

    //
    payments.setDepositFee(MAINNET_FEE);
    payments.transferOwnership(MAINNET_OWNER);

    vm.stopBroadcast();  // ----------------------------
  }
}
