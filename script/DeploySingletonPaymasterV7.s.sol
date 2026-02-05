// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script, console } from "forge-std/Script.sol";
import { SingletonPaymasterV7 } from "../src/SingletonPaymasterV7.sol";

contract DeploySingletonPaymasterV7 is Script {
    // Standard EntryPoint V0.7 address
    address constant ENTRY_POINT_V7 = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    // Deposit amount
    uint256 constant DEPOSIT_AMOUNT = 0.01 ether;

    function run() external {
        // Fork the network
        string memory rpcUrl = vm.envString("RPC_URL");
        vm.createSelectFork(rpcUrl);

        // Get private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Derive owner address from private key
        address owner = vm.addr(deployerPrivateKey);

        // Use owner for all roles
        address manager = owner;

        // Use owner as the only signer
        address[] memory signers = new address[](1);
        signers[0] = owner;

        console.log("Deploying SingletonPaymasterV7...");
        console.log("EntryPoint:", ENTRY_POINT_V7);
        console.log("Owner (from private key):", owner);
        console.log("Manager:", manager);
        console.log("Signers count:", signers.length);
        console.log("Deposit amount:", DEPOSIT_AMOUNT);

        // Start broadcasting with private key
        vm.startBroadcast(deployerPrivateKey);

        // Deploy paymaster
        SingletonPaymasterV7 paymaster = new SingletonPaymasterV7(ENTRY_POINT_V7, owner, manager, signers);

        console.log("Paymaster deployed at:", address(paymaster));

        // Add deposit
        paymaster.deposit{ value: DEPOSIT_AMOUNT }();
        console.log("Deposit added:", DEPOSIT_AMOUNT);
        console.log("Current deposit:", paymaster.getDeposit());

        vm.stopBroadcast();

        // Verify deployment
        _verifyDeployment(paymaster, ENTRY_POINT_V7, owner, manager, signers);
    }

    function _verifyDeployment(
        SingletonPaymasterV7 paymaster,
        address entryPoint,
        address owner,
        address manager,
        address[] memory signers
    )
        internal
        view
    {
        console.log("\n=== Deployment Verification ===");

        // Verify EntryPoint
        require(address(paymaster.entryPoint()) == entryPoint, "EntryPoint mismatch");
        console.log("EntryPoint verified");

        // Verify roles
        bytes32 DEFAULT_ADMIN_ROLE = 0x00;
        bytes32 MANAGER_ROLE = paymaster.MANAGER_ROLE();

        require(paymaster.hasRole(DEFAULT_ADMIN_ROLE, owner), "Owner role not set");
        console.log("Owner role verified");

        require(paymaster.hasRole(MANAGER_ROLE, manager), "Manager role not set");
        console.log("Manager role verified");

        // Verify signers
        for (uint256 i = 0; i < signers.length; i++) {
            require(paymaster.signers(signers[i]), "Signer not added");
            console.log("Signer verified:", signers[i]);
        }

        console.log("\n=== Deployment Successful ===");
        console.log("Paymaster address:", address(paymaster));
        console.log("Deposit:", paymaster.getDeposit());
    }
}
