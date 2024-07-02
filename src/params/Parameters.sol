// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Parameters {

  // ---------------- Goerli ----------------
  address GOERLI_OWNER           = 0xEd6715D2172BFd50C2DBF608615c2AB497904803;
  address GOERLI_DNFT            = 0x952E31dFeEB29F5398a36602E0E276F2b09B6651;
  address GOERLI_WETH            = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
  address GOERLI_WETH_ORACLE     = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
  uint    GOERLI_FEE             = 0.001e18; // 0.1%
  address GOERLI_FEE_RECIPIENT   = 0xDeD796De6a14E255487191963dEe436c45995813;
  address GOERLI_VAULT_MANAGER   = 0xf3128Ac07005a5591dF997A8fBd6a75993827144;

  // NOTE: There is no stETH on Goerli, so we use the WETH oracle instead.
  address GOERLI_CHAINLINK_STETH = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
  address GOERLI_WSTETH          = 0x6320cD32aA674d2898A68ec82e869385Fc5f7E2f;
  address GOERLI_DYAD            = 0xCf0c2d6aeD80aFD8cB299e7E7F3f311F81C3a766;
  address GOERLI_WETH_DYAD_UNI   = 0x1F79BeD01b0fF658dbb47b4005F1B571Ef06D0FD;

  // ---------------- Mainnet ----------------
  address MAINNET_OWNER           = 0xDeD796De6a14E255487191963dEe436c45995813; 
  address MAINNET_DNFT            = 0xDc400bBe0B8B79C07A962EA99a642F5819e3b712;
  address MAINNET_WETH            = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address MAINNET_WETH_ORACLE     = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
  uint    MAINNET_FEE             = 0.0015e18; // 0.15%
  address MAINNET_FEE_RECIPIENT   = 0xDeD796De6a14E255487191963dEe436c45995813;
  address MAINNET_VAULT_MANAGER   = 0xfaa785c041181a54c700fD993CDdC61dbBfb420f;
  address MAINNET_CHAINLINK_STETH = 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8;
  address MAINNET_WSTETH          = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
  address MAINNET_DYAD            = 0x305B58c5F6B5b6606fb13edD11FbDD5e532d5A26;
  address MAINNET_WETH_DYAD_UNI   = 0x1F79BeD01b0fF658dbb47b4005F1B571Ef06D0FD;
  address MAINNET_KEROSENE        = 0xf3768D6e78E65FC64b8F12ffc824452130BD5394;
  address MAINNET_STAKING         = 0x8e0e695fEC31d5502C2f3E860Fe560Ea80b03E1D;
  address MAINNET_WETH_VAULT      = 0xcF97cEc1907CcF9d4A0DC4F492A3448eFc744F6c;
  address MAINNET_WSTETH_VAULT    = 0x7aE80418051b2897729Cbdf388b07C5158C557A1;
  address MAINNET_VAULT_MANAGER_LICENSER = 0xd8bA5e720Ddc7ccD24528b9BA3784708528d0B85;

  // ---------------- Mainnet V2 ----------------
  address MAINNET_V2_VAULT_MANAGER     = 0xB62bdb1A6AC97A9B70957DD35357311e8859f0d7;
  address MAINNET_V2_DYAD              = 0xFd03723a9A3AbE0562451496a9a394D2C4bad4ab;
  address MAINNET_V2_WETH_VAULT        = 0x4fde0131694Ae08C549118c595923CE0b42f8299;
  address MAINNET_V2_WSTETH_VAULT      = 0x7e5F2b8f089A4Cd27f5B6B846306020800dF45Bd;
  address MAINNET_V2_KEROSENE_V1_VAULT = 0x48600800502a8dc7A2C42f39B21f0326Ad67dc4f;
  address MAINNET_V2_KEROSENE_V2_VAULT = 0x4808e4CC6a2Ba764778A0351E1Be198494aF0b43;
  address MAINNET_V2_VAULT_LICENSER    = 0xFe81952A0a2c6ab603ef1B3cC69E1B6Bffa92697;

  // ---------------- Sepolia ----------------
  address SEPOLIA_OWNER           = 0xEd6715D2172BFd50C2DBF608615c2AB497904803;
  address SEPOLIA_DNFT            = address(0);
  address SEPOLIA_WETH            = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
  address SEPOLIA_WETH_ORACLE     = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
  uint    SEPOLIA_FEE             = 0.001e18; // 0.1%
  address SEPOLIA_FEE_RECIPIENT   = 0xDeD796De6a14E255487191963dEe436c45995813;
  address SEPOLIA_VAULT_MANAGER   = address(0);

  // NOTE: There is no stETH on Sepolia, so we use the WETH oracle instead.
  address SEPOLIA_CHAINLINK_STETH = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
  address SEPOLIA_WSTETH          = 0xB82381A3fBD3FaFA77B3a7bE693342618240067b;
  address SEPOLIA_DYAD            = address(0);
  address SEPOLIA_WETH_DYAD_UNI   = 0x1F79BeD01b0fF658dbb47b4005F1B571Ef06D0FD;
}
