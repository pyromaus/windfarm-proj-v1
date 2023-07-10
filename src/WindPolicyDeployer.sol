// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Parametric Wind Farm Insurance (Deployer)
 * @author Serge Fotiev
 * @notice This is a decentralised parametric insurance
 * contract for clients looking to insure their wind farms
 * against the loss of revenue. See policy contract for 
 * more details.
 * @dev This contract deploys and manages unique insurance 
 * policies.
 * @dev Chainlink Keepers/Automation
 */

import "./WindFarmPolicy.sol";

contract WindPolicyDeployer {
    mapping(address => address[]) public policiesByClient;
    mapping(address => address[]) public policiesByInsurer;

    address[] public deployedPolicies;

    function newWindFarm(
        address _link,
        address _oracle,
        uint _premium,
        uint _payout,
        address _client,
        uint16 _days,
        string memory _latitude,
        string memory _longitude
    ) external payable returns (WindFarmPolicy) {
       WindFarmPolicy newFarm = (new WindFarmPolicy)(
            _link,
            _oracle,
            _premium,
            _payout,
            _client,
            msg.sender,
            address(this),
            _days,
            _latitude,
            _longitude
        );
        address policyAddress = address(newFarm);
        deployedPolicies.push(policyAddress);
        policiesByInsurer[msg.sender].push(policyAddress);
        policiesByClient[_client].push(policyAddress);
        return newFarm;
    }

    /** @dev Called by Chainlink Automation Time-based Upkeep 
     * every 30 minutes to trigger a request for the policy's 
     * location's weather conditions/wind speed.
    */
    function updatePolicyStates() external {
        for (uint256 i = 0; i < deployedPolicies.length; i++) {
            WindFarmPolicy policy = WindFarmPolicy(payable(deployedPolicies[i]));
            policy.updateState();
        }
    }

    function getDeployedPolicies() public view returns (address[] memory) {
        return deployedPolicies;
    }

    function getInsurerPolicies() public view returns (address[] memory) {
        return policiesByInsurer[msg.sender];
    }

    function getClientPolicies() public view returns (address[] memory) {
        return policiesByClient[msg.sender];
    }
}
