// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract AquilaDemo is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    //Vars
    string public latitude;
    string public longitude;
    bool public active;
    /* Chainlink */
    bytes32 chainlinkJobId;
    uint256 paymentToOracle;
    bytes32 public reqId;

    uint256 public premium;
    uint16 public latestWindSpeed;

    modifier OnlyOracle() {
        if (msg.sender != getOracleAddress()) {
            revert InsureWindFarm__NotOracle();
        }
        _;
    }
    /* Struct returned from AccuWeather Oracle */
    struct CurrentConditionsResult {
        uint256 timestamp;
        uint24 precipitationPast12Hours;
        uint24 precipitationPast24Hours;
        uint24 precipitationPastHour;
        uint24 pressure;
        int16 temperature;
        uint16 windDirectionDegrees;
        uint16 windSpeed;
        uint8 precipitationType;
        uint8 relativeHumidity;
        uint8 uvIndex;
        uint8 weatherIcon;
    }

    // S1
    struct Customer {
        uint custId;
        string customerName; // needed? could be payout address instead
        uint farmId; // what if they have multiple (add struct)
        uint numTurbines; // needed?
        string centerPointLocation; //better to split this in long and lats, save gas on slicing
    }

    // S2
    struct WindFarm {
        uint farmId;
        uint ownerId; //the custId of the owner
        uint numTurbines;
        string centerPointLocation;
        uint mWhAvgThreshold;
    } // Farm center used for weather monitoring, not turbines themselves

    // S3
    struct Turbine {
        uint custId;
        uint farmId;
        uint turbineId;
        string exactLocation; //will split this into long and lats
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
    mapping(uint256 => CurrentWindMeasure) latestWindSpeeds;

    constructor(address _link, address _oracle) payable {
        latitude = "44.166667";
        longitude = "-76.466667";
        policyAmount = _amount;
        premium = (_amount / 1337);
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);
        chainlinkJobId = "7c276986e23b4b1c990d8659bca7a9d0";
        paymentToOracle = 100000000000000000;
        active = true;
    }

    function addCustomer(string memory csvData) public {
        bytes memory data = bytes(csvData);
        uint offset = 0;
        uint custId;
        uint farmId;
        string memory customerName;
        uint numTurbines;
        string memory centerPointLocation;

        while (offset < data.length) {
            (
                custId,
                farmId,
                customerName,
                numTurbines,
                centerPointLocation,
                offset
            ) = parseCustomer(data, offset);
            customers[custId] = Customer(
                custId,
                farmId,
                customerName,
                numTurbines,
                centerPointLocation
            );
        }
    }

    function removeCustomer(uint custId) public {
        delete customers[custId];
    }

    function parseCustomer(
        bytes memory data,
        uint offset
    ) internal pure returns (uint, string memory, uint, string memory, uint) {
        uint custId;
        uint farmId;
        string memory customerName;
        uint numTurbines;
        string memory centerPointLocation;

        (custId, offset) = parseInt(data, offset, ";");
        (farmId, offset) = parseInt(data, offset, ";");
        (customerName, offset) = parseString(data, offset, ";");
        (numTurbines, offset) = parseInt(data, offset, ";");
        (centerPointLocation, offset) = parseString(data, offset, "\n");

        return (custId, customerName, numTurbines, centerPointLocation, offset);
    }

    function parseInt(
        bytes memory data,
        uint256 offset,
        bytes1 delimiter
    ) internal pure returns (uint256, uint256) {
        uint256 result = 0;
        uint256 i = offset;
        while (i < data.length && data[i] != delimiter) {
            result = result * 10 + uint256(data[i]) - 48;
            i++;
        }
        return (result, i + 1);
    }

    function parseString(
        bytes memory data,
        uint256 offset,
        bytes1 delimiter
    ) internal pure returns (string memory, uint256) {
        uint256 start = offset;
        while (offset < data.length && data[offset] != delimiter) {
            offset++;
        }
        string memory result = string(data[start:offset]);
        return (result, offset + 1);
    }

    function getCustomer(uint custId) public view returns (Customer memory) {
        return customers[custId];
    }

    function addWindFarm(
        uint farmId,
        uint ownerId,
        uint numTurbines,
        string memory centerPointLocation,
        uint mWhAvgThreshold
    ) public {
        windFarms[farmId] = WindFarm(
            farmId,
            ownerId,
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

    function pullWindOracleSpeed(uint farmId) public view returns (uint) {
        //Need to slice up the coordinates of the given farmId and feed it to requestLocationCurrentConditions
        latitude = windFarms[farmId].centerPointLocation;
        longitude = windFarms[farmId].centerPointLocation;

        string memory metric = "metric";
        requestLocationCurrentConditions(
            paymentToOracle,
            latitude,
            longitude,
            metric
        );
    }

    function requestLocationCurrentConditions(
        uint256 _payment,
        string memory _latitude,
        string memory _longitude,
        string memory _units
    ) internal {
        Chainlink.Request memory req = buildChainlinkRequest(
            chainlinkJobId,
            address(this),
            this.fulfillLocationCurrentConditions.selector
        );

        req.add("endpoint", "location-current-conditions");
        req.add("lat", _latitude);
        req.add("lon", _longitude);
        req.add("units", _units);

        reqId = sendChainlinkRequest(req, _payment);
    }

    function fulfillLocationCurrentConditions(
        bytes32 _requestId,
        bool _locationFound,
        bytes memory _locationResult,
        bytes memory _currentConditionsResult
    ) public recordChainlinkFulfillment(_requestId) OnlyOracle {
        if (_locationFound) {
            storeCurrentConditionsResult(_requestId, _currentConditionsResult);
        }
    }

    function storeCurrentConditionsResult(
        bytes32 _requestId,
        bytes memory _currentConditionsResult
    ) private {
        CurrentConditionsResult memory result = abi.decode(
            _currentConditionsResult,
            (CurrentConditionsResult)
        );
        latestWindSpeed = result.windSpeed / 10;
        windTimestamp = result.timestamp;
    }

    function recordHourlyWind(uint farmId) internal {
        latestWindSpeeds[farmId] = CurrentWindMeasure(
            farmId,
            currentCreamHour,
            latestWindSpeed
        );
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
