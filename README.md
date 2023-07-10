# Parametric Wind Farm Insurance

## June 2023 update
The Goerli Accuweather Oracle is no longer in service. An update to an appropriate weather data source is in progress. Until then, the contract is in a non-working state.

### What does it do?

This is a decentralised parametric insurance application. Clients may insure their wind farms against the loss of revenue. Using an Accuweather Oracle via Chainlink, the wind speed of the client's wind farm's geographical location is returned every half hour.
If there is a lack of wind on a given day (according to predefined thresholds), the client receives an instant payout at the end of the 24 hour cycle.

### Technologies

Accuweather Chainlink Oracle on the Goerli testnet supplies the latest wind speed to the contract. Chainlink Keepers/Automation prompts the contract every half hour to fetch a new wind speed reading.

### Check it out

In `script/HelperConfig.s.sol` are the Deployer + Policy example contract addresses deployed on Goerli. Check them out on Etherscan! The policy is pre-loaded with ETH and Link.
