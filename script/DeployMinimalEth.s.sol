//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccountEthereum} from "../src/ethereum/MinimalAccountEthereum.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMinimalEth is Script {
    function run() public {
        // deployMinimalAccount();
    }

    function deployMinimalAccount() public returns (HelperConfig, MinimalAccountEthereum) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        MinimalAccountEthereum minimalAccount = new MinimalAccountEthereum(config.entryPoint);
        minimalAccount.transferOwnership(config.account);

        vm.stopBroadcast();
        return (helperConfig, minimalAccount);
    }
}
