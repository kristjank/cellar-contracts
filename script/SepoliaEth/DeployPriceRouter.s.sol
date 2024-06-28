// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {Deployer} from "src/Deployer.sol";
import {Registry} from "src/Registry.sol";
import {PriceRouter} from "src/modules/price-router/PriceRouter.sol";
import {SepoliaAddresses} from "resources/SepoliaAddresses.sol";
import {SepoliaContractDeploymentNames} from "resources/SepoliaContractDeploymentNames.sol";

import {PositionIds} from "resources/PositionIds.sol";
import {Math} from "src/utils/Math.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

/**
 * @dev Run
 *      `make deploy-sepolia-price-router`  // see Makefile
 *      Optionally can change `--with-gas-price` to something more reasonable
 */
contract DeployPriceRouterScript is Script, SepoliaAddresses, SepoliaContractDeploymentNames {
    using Math for uint256;
    using stdJson for string;

    uint256 public privateKey;
    Deployer public deployer = Deployer(deployerAddress);
    Registry public registry;

    uint8 public constant CHAINLINK_DERIVATIVE = 1;
    uint8 public constant TWAP_DERIVATIVE = 2;
    uint8 public constant EXTENSION_DERIVATIVE = 3;

    function setUp() external {
        privateKey = vm.envUint("PRIVATE_KEY");
        registry = Registry(deployer.getAddress(registryName));
    }

    function run() external {
        bytes memory creationCode;
        bytes memory constructorArgs;
        vm.startBroadcast(privateKey);

        // Deploy Price Router
        PriceRouter priceRouter;

        creationCode = type(PriceRouter).creationCode;
        constructorArgs = abi.encode(vm.envAddress("SOMM_DEVELOPER_ADDRESS"), registry, WETH);
        priceRouter = PriceRouter(deployer.deployContract(priceRouterName, creationCode, constructorArgs, 0));

        // Update price router in registry.
        registry.setAddress(2, address(priceRouter));

        priceRouter.transferOwnership(vm.envAddress("OWNER_ADDRESS"));

        vm.stopBroadcast();
    }
}
