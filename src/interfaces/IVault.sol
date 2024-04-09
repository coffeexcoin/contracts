// SPDX-License-Identifier: MIT
pragma solidity = 0.8.17;

interface IVault {
    event Withdraw(uint256 indexed from, address indexed to, uint256 amount);
    event Deposit(uint256 indexed id, uint256 amount);
    event Move(uint256 indexed from, uint256 indexed to, uint256 amount);

    error StaleData();
    error IncompleteRound();
    error NotVaultManager();

    // A vault must implement these functions
    function deposit(uint256 id, uint256 amount) external;
    function move(uint256 from, uint256 to, uint256 amount) external;
    function withdraw(uint256 id, address to, uint256 amount) external;
    function getUsdValue(uint256 id) external view returns (uint256);
}
