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
import {UniswapV3Adaptor} from "src/modules/adaptors/Uniswap/UniswapV3Adaptor.sol";
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
    UniswapV3Adaptor public uniswapV3Adaptor;

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
        uniswapV3Adaptor = UniswapV3Adaptor(deployer.getAddress(UNISWAPV3_ADAPTOR_NAME));
        swapWithUniswapAdaptor = SwapWithUniswapAdaptor(deployer.getAddress(SWAP_WITH_UNISWAP_ADAPTOR_NAME));
    }

    function run() external {
        vm.startBroadcast(privateKey);

        uint256 initialDeposit = 0.1e6;
        uint64 platformCut = 0.8e18;

        cellar = _createCellarWithNativeSupport(
            CELLAR_NAME_NATIVE, WETH, ERC20_WETH_POSITION, abi.encode(true), initialDeposit, platformCut
        );

        cellar.addAdaptorToCatalogue(address(nativeAdaptor));
        cellar.addAdaptorToCatalogue(address(erc20Adaptor));
        cellar.addAdaptorToCatalogue(address(swapWithUniswapAdaptor));
        cellar.addAdaptorToCatalogue(address(uniswapV3Adaptor));

        cellar.addPositionToCatalogue(ERC20_WETH_POSITION);
        cellar.addPositionToCatalogue(ERC20_USDC_POSITION);
        cellar.addPositionToCatalogue(ERC20_DAI_POSITION);
        cellar.addPositionToCatalogue(UNISWAP_V3_USDC_DAI_POSITION);

        //cellar.addPosition(1, NATIVE_POSITION, abi.encode(0), false);

        WETH.safeApprove(address(cellar), type(uint256).max);

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
