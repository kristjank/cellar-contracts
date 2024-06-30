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

import {BaseAdaptor} from "src/modules/adaptors/BaseAdaptor.sol";
import {ERC20Adaptor} from "src/modules/adaptors/ERC20Adaptor.sol";
import {SwapWithUniswapAdaptor} from "src/modules/adaptors/Uniswap/SwapWithUniswapAdaptor.sol";

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
    ERC20Adaptor public erc20Adaptor;
    SwapWithUniswapAdaptor public swapWithUniswapAdaptor;

    uint8 public constant CHAINLINK_DERIVATIVE = 1;
    uint8 public constant TWAP_DERIVATIVE = 2;
    uint8 public constant EXTENSION_DERIVATIVE = 3;

    function setUp() external {
        privateKey = vm.envUint("PRIVATE_KEY");

        deployer = Deployer(vm.envAddress("DEPLOYER_ADDRESS"));
        registry = Registry(deployer.getAddress(REGISTRY_NAME));
        priceRouter = PriceRouter(deployer.getAddress(PRICE_ROUTER_NAME));
        erc20Adaptor = ERC20Adaptor(deployer.getAddress(ERC20_ADAPTOR_NAME));
        nativeAdaptor = NativeAdaptor(deployer.getAddress(NATIVE_ADAPTOR_NAME));
    }

    function run() external {
        bytes memory creationCode;
        bytes memory constructorArgs;

        vm.startBroadcast(privateKey);

        uint256 initialDeposit = 0.01e18;
        uint64 platformCut = 0.75e18;

        cellar = _createCellarWithNativeSupport(
            CELLAR_NAME_NATIVE, WETH, NATIVE_WETH_POSITION, abi.encode(true), initialDeposit, platformCut
        );

        cellar.addPositionToCatalogue(NATIVE_POSITION);
        cellar.addAdaptorToCatalogue(address(nativeAdaptor));

        cellar.addPosition(1, NATIVE_POSITION, abi.encode(0), false);

        // WETH.safeApprove(address(cellar), type(uint256).max);

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
