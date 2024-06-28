# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
install:; forge install
update:; forge update

# Build & test
build  :; forge build
test   :; forge test -vv --fork-url ${MAINNET_RPC_URL} --fork-block-number ${BLOCK_NUMBER}
trace   :; forge test -vvv --fork-url ${MAINNET_RPC_URL} --fork-block-number ${BLOCK_NUMBER}
clean  :; forge clean
snapshot :; forge snapshot
fmt    :; forge fmt && forge fmt test/


# Deploy SEPOLIA
# deployer and registry
deploy-sepolia:; forge script -vv script/SepoliaEth/Deployer.s.sol:DeployerScript --rpc-url ${SEPOLIA_RPC_URL} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --verify --etherscan-api-key ${ETHERSCAN_KEY} --slow --broadcast
# deploy-sepolia-registry:; forge script -vv script/SepoliaEth/Deployer.s.sol:RegistryScript --rpc-url ${SEPOLIA_RPC_URL} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --verify --etherscan-api-key ${ETHERSCAN_KEY} --slow --broadcast

# price router setup
deploy-sepolia-price-router:; forge script -vv script/SepoliaEth/DeployPriceRouter.s.sol:DeployPriceRouterScript --rpc-url ${SEPOLIA_RPC_URL} --private-key ${DEPLOY_KEY} —optimize —optimizer-runs 200 --with-gas-price 70000000000 --verify --etherscan-api-key ${ETHERSCAN_KEY} --slow --broadcast
