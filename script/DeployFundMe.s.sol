// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfigInstance = new HelperConfig();
        address ethUsdPriceFeed = helperConfigInstance.activeNetworkConfig();

        vm.startBroadcast();
        FundMe fundMeInstance = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMeInstance;
    }
}
