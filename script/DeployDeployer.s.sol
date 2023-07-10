// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {WindPolicyDeployer} from "../src/WindPolicyDeployer.sol";
import {WindFarmPolicy} from "../src/WindFarmPolicy.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDeployerAndPolicy is Script {

    uint16 public insuredDays = 30;
    string public lat = "46.508436";
    string public long = "6.657028";

    function run() external returns (WindPolicyDeployer, WindFarmPolicy) {

        HelperConfig helperConfig = new HelperConfig();
        (address link,
        address oracle,
        uint premium,
        uint payout,
        address client) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        WindPolicyDeployer windPolicyDeployer = new WindPolicyDeployer();
        WindFarmPolicy zachsFartFarm = windPolicyDeployer.newWindFarm(
            link,
            oracle,
            premium,
            payout,
            client,
            insuredDays,
            lat,
            long
        );
        vm.stopBroadcast();
        console.log("acid farm: ", address(zachsFartFarm));
        return (windPolicyDeployer, zachsFartFarm);


    }

    function deployDeployer() public returns (WindPolicyDeployer) {
        vm.broadcast();
        WindPolicyDeployer windDeployer = new WindPolicyDeployer();
        return (windDeployer);
    }

    function deployNewFart() public returns (WindFarmPolicy) {
        HelperConfig helperConfig = new HelperConfig();
        (address link,
        address oracle,
        uint premium,
        uint payout,
        address client) = helperConfig.activeNetworkConfig();
        WindPolicyDeployer zachsWindDeployer = deployDeployer();
        vm.broadcast();
        WindFarmPolicy zachsFartFarm = zachsWindDeployer.newWindFarm(
            link,
            oracle,
            premium,
            payout,
            client,
            insuredDays,
            lat,
            long
        );
        console.log("zachs address: ", address(zachsFartFarm));
        return zachsFartFarm;

    }
}