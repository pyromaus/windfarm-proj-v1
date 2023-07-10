//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    
    struct NetworkConfig {
        address link;
        address oracle;
        uint premium;
        uint payout;
        address client;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 5) {
            activeNetworkConfig = getGoerliEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getGoerliEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            link: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            oracle: 0xB9756312523826A566e222a34793E414A81c88E1,
            premium: 0.02 ether,
            payout: 0.08 ether,
            client: 0x06cBB83E7c54780DD5DCE6742256A3E1b5A70907
        });
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.link != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        LinkToken mockLink = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            link: address(mockLink),
            oracle: address(0), //to be: Mock ChainlinkClient feeding the weather struct
            premium: 2 ether,
            payout: 8 ether,
            client: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        });
    }
}