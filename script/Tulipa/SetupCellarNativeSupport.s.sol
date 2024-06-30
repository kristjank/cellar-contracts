// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Deployer} from "src/Deployer.sol";
import {Registry} from "src/Registry.sol";
import {PriceRouter} from "src/modules/price-router/PriceRouter.sol";
import {SequencerPriceRouter} from "src/modules/price-router/permutations/SequencerPriceRouter.sol";
import {MainnetAddresses} from "test/resources/MainnetAddresses.sol";
import {TulipaContractDeploymentNames} from "resources/TulipaContractDeploymentNames.sol";

import {NativeAdaptor} from "src/modules/adaptors/NativeAdaptor.sol";
import {CellarWithNativeSupport} from "src/base/permutations/CellarWithNativeSupport.sol";

import {PositionIds} from "resources/PositionIds.sol";
import {Math} from "src/utils/Math.sol";

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

/**
 * @dev Run
 *      see Makefile
 */
contract SetupCellarNativeSupportScript is Script, MainnetAddresses, TulipaContractDeploymentNames, PositionIds {
    using SafeTransferLib for ERC20;
    using Math for uint256;
    using stdJson for string;

    uint256 public privateKey;
    Deployer public deployer;
    Registry public registry;
    PriceRouter public priceRouter;

    CellarWithNativeSupport private cellar;
    NativeAdaptor private nativeAdaptor;

    uint32 private wethPosition = 1;
    uint32 private nativePosition = 2;

    function setUp() external {
        privateKey = vm.envUint("PRIVATE_KEY");

        deployer = Deployer(vm.envAddress("DEPLOYER_ADDRESS"));
        registry = Registry(deployer.getAddress(REGISTRY_NAME));
        priceRouter = PriceRouter(deployer.getAddress(PRICE_ROUTER_NAME));
    }

    function run() external {
        bytes memory creationCode;
        bytes memory constructorArgs;

        vm.startBroadcast(privateKey);

        nativeAdaptor = new NativeAdaptor(address(WETH));

        // Setup Cellar:
        registry.trustAdaptor(address(nativeAdaptor));
        registry.trustPosition(wethPosition, address(nativeAdaptor), abi.encode(WETH));
        registry.trustPosition(nativePosition, address(nativeAdaptor), hex"");

        uint256 initialDeposit = 0.01e18;
        uint64 platformCut = 0.75e18;

        cellar = _createCellarWithNativeSupport(
            CELLAR_NAME_NATIVE, WETH, wethPosition, abi.encode(true), initialDeposit, platformCut
        );

        cellar.addPositionToCatalogue(nativePosition);
        cellar.addAdaptorToCatalogue(address(nativeAdaptor));

        cellar.addPosition(1, nativePosition, abi.encode(0), false);

        cellar.setRebalanceDeviation(0.01e18);

        WETH.safeApprove(address(cellar), type(uint256).max);

        //initialAssets = cellar.totalAssets();

        vm.stopBroadcast();
    }

    function _createCellarWithNativeSupport(
        string memory cellarName,
        ERC20 holdingAsset,
        uint32 holdingPosition,
        bytes memory holdingPositionConfig,
        uint256 initialDeposit,
        uint64 platformCut
    ) internal returns (CellarWithNativeSupport) {
        // Approve new cellar to spend assets.
        address cellarAddress = deployer.getAddress(cellarName);
        //deal(address(holdingAsset), address(this), initialDeposit);
        holdingAsset.approve(cellarAddress, initialDeposit);

        bytes memory creationCode;
        bytes memory constructorArgs;
        creationCode = type(CellarWithNativeSupport).creationCode;
        constructorArgs = abi.encode(
            address(this),
            registry,
            holdingAsset,
            cellarName,
            cellarName,
            holdingPosition,
            holdingPositionConfig,
            initialDeposit,
            platformCut,
            type(uint192).max
        );

        return CellarWithNativeSupport(payable(deployer.deployContract(cellarName, creationCode, constructorArgs, 0)));
    }
}
