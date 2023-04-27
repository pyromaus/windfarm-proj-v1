// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract AquilaDemo {
    // S1
    struct Customer {
        uint custId;
        string customerName;
        //uint farmId;
        uint numTurbines;
        string centerPointLocation;
    }

    // S2
    struct WindFarm {
        uint farmId;
        string farmName;
        uint numTurbines;
        string centerPointLocation;
        uint mWhAvgThreshold;
    } // Farm center used for weather monitoring, not turbines themselves

    // S3
    struct Turbine {
        uint custId;
        uint farmId;
        uint turbineId;
        string exactLocation;
    }

    // S4
    struct HistoricalWindAvg {
        uint farmId;
        string creamCheeseHour;
        uint AvgWind;
    }

    // S5
    struct CurrentWindMeasure {
        uint farmId;
        string creamCheeseHour;
        uint measuredWind;
    }

    // S6
    struct TurbineOutput {
        uint farmId;
        uint turbineId;
        uint creamCheeseHour;
        uint mWhOutput;
        uint measuredWind;
        string windTag;
        string outputTag;
        string statusTag;
    }
    mapping(uint256 => Customer) customers;
    mapping(uint256 => WindFarm) windFarms;
    mapping(uint256 => Turbine) turbines;
    mapping(uint256 => HistoricalWindAvg) windAverages;

    function addCustomer(
        uint custId,
        string memory customerName,
        uint numTurbines,
        string memory centerPointLocation
    ) public {
        customers[custId] = Customer(
            custId,
            customerName,
            numTurbines,
            centerPointLocation
        );
    }

    function removeCustomer(uint custId) public {
        delete customers[custId];
    }

    function getCustomer(uint custId) public view returns (Customer memory) {
        return customers[custId];
    }

    function addWindFarm(
        uint farmId,
        string memory farmName,
        uint numTurbines,
        string memory centerPointLocation,
        uint mWhAvgThreshold
    ) public {
        windFarms[farmId] = WindFarm(
            farmId,
            farmName,
            numTurbines,
            centerPointLocation,
            mWhAvgThreshold
        );
    }

    function removeWindFarm(uint256 farmId) public {
        delete windFarms[farmId];
    }

    function getWindFarm(uint256 farmId) public view returns (WindFarm memory) {
        return windFarms[farmId];
    }

    function changeMWhThreshold(uint farmId, uint newThreshold) public {
        windFarms[farmId].mWhAvgThreshold = newThreshold;
    }

    function addTurbine(
        uint custId,
        uint farmId,
        uint turbineId,
        string memory exactLocation
    ) public {
        turbines[turbineId] = Turbine(custId, farmId, turbineId, exactLocation);
    }

    function removeTurbine(uint turbineId) public {
        delete turbines[turbineId];
    }

    function getTurbine(uint turbineId) public view returns (Turbine memory) {
        return turbines[turbineId];
    }

    function getHistoricalWindByFarmAndHour(
        uint farmId,
        uint creamCheeseHour
    ) public view returns (uint) {
        return windAverages[farmId].creamCheeseHour;
        // will fix this
    }

    function getCurrentWind(
        uint farmId,
        string memory creamCheeseHour
    ) public view returns (uint) {
        //Will add oracle code
        //return currentwind
    }

    // after S6 is uploaded (needs work)

    function processTurbineOutput(
        uint farmId,
        uint turbineId,
        string memory creamCheeseHour,
        uint output,
        uint measuredWind
    ) public {
        tagRecords(farmId, creamCheeseHour);
    }

    function tagRecords(
        uint farmId,
        string memory creamCheeseHour
    ) public view returns (string memory) {
        // Retrieve wind and output measurements for the specified farm and hour
        uint measuredWind = WINMEASURED[farmId][hour];
        uint measuredOutput = TURBINE[farmId][hour].output;

        // Retrieve the historical (last year) wind average for the specified farm and hour
        uint historicalAvgWind = WINDAVG[farmId][hour];

        // Retrieve the current (real-time) weather average for the specified farm
        uint currentAvgWind = FARM[farmId].currentAvgWind;

        // measured wind is above, below, or equal to history?
        string memory windTag;
        if ((measuredWind / historicalAvgWind) > 1.05) {
            windTag = "TS_OVER";
        } else if ((measuredWind / historicalAvgWind) < 0.95) {
            windTag = "TS_UNDER";
        } else {
            windTag = "TS_EQ";
        }

        // measured output is above, below, or equal to history?
        string memory outputTag;
        if ((measuredOutput / FARM[farmId].avgOutput) > 1.05) {
            outputTag = "TS_OVER";
        } else if ((measuredOutput / FARM[farmId].avgOutput) < 0.95) {
            outputTag = "TS_UNDER";
        } else {
            outputTag = "TS_EQ";
        }

        // Determine whether the wind and output tags match
        string memory statusTag;
        if (keccak256(bytes(windTag)) == keccak256(bytes(outputTag))) {
            statusTag = "PAYABLE";
        } else {
            statusTag = "AUDIT";
        }

        // Return the tag for the record
        return statusTag;
    }
}
