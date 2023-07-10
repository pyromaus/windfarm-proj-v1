// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {WindPolicyDeployer} from "../src/WindPolicyDeployer.sol";
import {WindFarmPolicy} from "../src/WindFarmPolicy.sol";
import {DeployDeployerAndPolicy} from "./DeployDeployer.s.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";


contract UpdateStateGetWindSpeed is Script {

    function run() public {

        vm.startBroadcast();
        WindPolicyDeployer policyDeployer = WindPolicyDeployer(0x5e6fe7CF80C48e777b8a79C09bcCFE660fD11519);
        policyDeployer.updatePolicyStates();

        WindFarmPolicy policy = WindFarmPolicy(payable(0x0e982EF3d1068717f8556fca4945C82e6F87f1Cc));
        uint latestWindSpeed = policy.getLatestWindSpeed();
        vm.stopBroadcast();

        console.log("Wind speed in Lausanne: ", latestWindSpeed);
    }
}

contract FundPolicyWithLink is Script {

    function run() public {

        WindFarmPolicy policy = WindFarmPolicy(payable(0x0e982EF3d1068717f8556fca4945C82e6F87f1Cc));
        HelperConfig helperConfig = new HelperConfig();

        (address linkTokenAddress,,,,) = helperConfig.activeNetworkConfig();
        LinkTokenInterface linkToken = LinkTokenInterface(linkTokenAddress);
        vm.broadcast();
        require(linkToken.transfer(address(policy), 1 ether), "Link transfer failed");
    }
}

contract WithdrawLinkFromPolicy is Script {

    function run() public {

        WindFarmPolicy policy = WindFarmPolicy(payable(0x0C35A0df3054ea121A6B9D81a3c34EcC67CC1E5B));
        vm.broadcast();
        policy.withdrawLink();
    }
}

