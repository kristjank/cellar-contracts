# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
install:; forge install
update:; forge update

# Build & test
build  :; forge build
test   :; forge test -vv --fork-url ${MAINNET_RPC_URL} --fork-block-number ${BLOCK_NUMBER}
tulipa-test :; forge test -vv --fork-url ${MAINNET_RPC_URL} --fork-block-number ${BLOCK_NUMBER}
trace   :; forge test -vvv --fork-url ${MAINNET_RPC_URL} --fork-block-number ${BLOCK_NUMBER}
clean  :; forge clean
snapshot :; forge snapshot
fmt    :; forge fmt && forge fmt test/
anvil-mainnet-fork:; anvil --fork-url ${MAINNET_RPC_URL}

#####################################
# Deploy SEPOLIA
# deployer and registry
sepolia-deployer-registry:; forge script -vv script/SepoliaEth/Deployer.s.sol:DeployerScript --rpc-url ${SEPOLIA_RPC_URL} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --verify --etherscan-api-key ${ETHERSCAN_KEY} --slow --broadcast
# deploy-sepolia-registry:; forge script -vv script/SepoliaEth/Deployer.s.sol:RegistryScript --rpc-url ${SEPOLIA_RPC_URL} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --verify --etherscan-api-key ${ETHERSCAN_KEY} --slow --broadcast

# price router setup
sepolia-price-router:; forge script -vv script/SepoliaEth/DeployPriceRouter.s.sol:DeployPriceRouterScript --rpc-url ${SEPOLIA_RPC_URL} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --verify --etherscan-api-key ${ETHERSCAN_KEY} --slow --broadcast

# setup architecture
sepolia-setup-architecture:; forge script -vv script/SepoliaEth/SetUpArchitecture.s.sol:SetUpArchitectureScript --rpc-url ${SEPOLIA_RPC_URL} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --verify --etherscan-api-key ${ETHERSCAN_KEY} --slow --broadcast

# setup architecture
sepolia-aavev3:; forge script -vv script/SepoliaEth/SetUpAaveV3Positions.s.sol:SetUpAaveV3PositionsScript --rpc-url ${SEPOLIA_RPC_URL} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --verify --etherscan-api-key ${ETHERSCAN_KEY} --slow --broadcast

#####################################
# DEPLOY ANVIL LOCAL
localhost-deployer-registry:; forge script -vv script/Tulipa/Deployer.s.sol:DeployerScript --rpc-url ${LOCAL_HOST} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --slow --broadcast
# price router setup
localhost-price-router:; forge script -vv script/Tulipa/DeployPriceRouter.s.sol:DeployPriceRouterScript --rpc-url ${LOCAL_HOST} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --slow --broadcast
# base architecture setup
localhost-setup-architecture:; forge script -vv script/Tulipa/SetUpArchitecture.s.sol:SetUpArchitectureScript --rpc-url ${LOCAL_HOST} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --slow --broadcast

# cellar setups
localhost-cellar-with-aavev3-flashloans:; forge script script/Tulipa/SetupCellarWithAaveV3FlashLoans.s.sol:SetupCellarWithAaveV3FlashLoansScript --rpc-url ${LOCAL_HOST} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --slow --broadcast
localhost-cellar-with-native-support:; forge script -vv script/Tulipa/SetupCellarNativeSupport.s.sol:SetupCellarNativeSupportScript --rpc-url ${LOCAL_HOST}  --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --slow --broadcast