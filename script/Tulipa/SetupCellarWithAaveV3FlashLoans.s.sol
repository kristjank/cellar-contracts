// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

import {Deployer} from "src/Deployer.sol";
import {Registry} from "src/Registry.sol";
import {PriceRouter} from "src/modules/price-router/PriceRouter.sol";
import {ERC20Adaptor} from "src/modules/adaptors/ERC20Adaptor.sol";
import {SwapWithUniswapAdaptor} from "src/modules/adaptors/Uniswap/SwapWithUniswapAdaptor.sol";
import {UniswapV3PositionTracker} from "src/modules/adaptors/Uniswap/UniswapV3PositionTracker.sol";
import {UniswapV3Adaptor} from "src/modules/adaptors/Uniswap/UniswapV3Adaptor.sol";
import {AaveV3ATokenAdaptor} from "src/modules/adaptors/Aave/V3/AaveV3ATokenAdaptor.sol";
import {AaveV3DebtTokenAdaptor} from "src/modules/adaptors/Aave/V3/AaveV3DebtTokenAdaptor.sol";
import {ERC4626Adaptor} from "src/modules/adaptors/ERC4626Adaptor.sol";
import {OneInchAdaptor} from "src/modules/adaptors/OneInch/OneInchAdaptor.sol";
import {ZeroXAdaptor} from "src/modules/adaptors/ZeroX/ZeroXAdaptor.sol";
import {IChainlinkAggregator} from "src/interfaces/external/IChainlinkAggregator.sol";
import {UniswapV3Pool} from "src/interfaces/external/UniswapV3Pool.sol";
import {MainnetAddresses} from "test/resources/MainnetAddresses.sol";
import {TulipaContractDeploymentNames} from "resources/TulipaContractDeploymentNames.sol";
import {IPoolV3} from "src/interfaces/external/IPoolV3.sol";

import {CellarWithAaveFlashLoans} from "src/base/permutations/CellarWithAaveFlashLoans.sol";

import {PositionIds} from "resources/PositionIds.sol";
import {Math} from "src/utils/Math.sol";

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

/**
 * @dev Run
 *      see Makefile
 */
contract SetupCellarWithAaveV3FlashLoansScript is
    Script,
    MainnetAddresses,
    TulipaContractDeploymentNames,
    PositionIds
{
    using Math for uint256;
    using stdJson for string;
    using SafeTransferLib for ERC20;

    uint256 public privateKey;
    Deployer public deployer;
    Registry public registry;
    PriceRouter public priceRouter;
    CellarWithAaveFlashLoans private cellar;

    address public erc20AdaptorAddress;
    address public aaveV3ATokenAdaptorAddress;
    address public aaveV3DebtTokenAdaptorAddress;
    address public uniswapV3AdaptorAddress;

    uint256 public constant AAVE_V3_MIN_HEALTH_FACTOR = 1.01e18;

    uint8 public constant CHAINLINK_DERIVATIVE = 1;
    uint8 public constant TWAP_DERIVATIVE = 2;
    uint8 public constant EXTENSION_DERIVATIVE = 3;

    IPoolV3 private pool = IPoolV3(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    address private aaveOracle = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;

    function setUp() external {
        privateKey = vm.envUint("PRIVATE_KEY");

        deployer = Deployer(vm.envAddress("DEPLOYER_ADDRESS"));
        registry = Registry(deployer.getAddress(REGISTRY_NAME));
        priceRouter = PriceRouter(deployer.getAddress(PRICE_ROUTER_NAME));

        aaveV3ATokenAdaptorAddress = deployer.getAddress(AAVEV3_ATOKEN_ADAPTOR_NAME);
        aaveV3DebtTokenAdaptorAddress = deployer.getAddress(AAVEV3_DEBT_TOKEN_ADAPTOR_NAME);
    }

    function run() external {
        bytes memory creationCode;
        bytes memory constructorArgs;

        vm.startBroadcast(privateKey);

        uint256 initialDeposit = 1e6;
        uint64 platformCut = 0.75e18;

        // Approve new cellar to spend assets.
        address cellarAddress = deployer.getAddress(CELLAR_NAME_AAVEV3);
        //deal(address(USDC), address(this), initialDeposit);
        USDC.approve(cellarAddress, initialDeposit);

        creationCode = type(CellarWithAaveFlashLoans).creationCode;
        constructorArgs = abi.encode(
            address(this),
            registry,
            USDC,
            CELLAR_NAME_AAVEV3,
            "TULIP",
            AAVE_V3_LOW_HF_A_USDC_POSITION,
            abi.encode(AAVE_V3_MIN_HEALTH_FACTOR),
            initialDeposit,
            platformCut,
            type(uint192).max,
            address(pool)
        );

        cellar = CellarWithAaveFlashLoans(deployer.deployContract(CELLAR_NAME_AAVEV3, creationCode, constructorArgs, 0));

        cellar.addAdaptorToCatalogue(aaveV3ATokenAdaptorAddress);
        cellar.addAdaptorToCatalogue(aaveV3DebtTokenAdaptorAddress);

        cellar.addPositionToCatalogue(AAVE_V3_LOW_HF_A_USDC_POSITION);
        cellar.addPositionToCatalogue(AAVE_V3_LOW_HF_DEBT_USDC_POSITION);

        cellar.addPosition(1, AAVE_V3_LOW_HF_A_USDC_POSITION, abi.encode(0), false);
        cellar.addPosition(0, AAVE_V3_LOW_HF_DEBT_USDC_POSITION, abi.encode(0), true);

        USDC.safeApprove(address(cellar), type(uint256).max);

        //cellar.setRebalanceDeviation(0.005e18);

        vm.stopBroadcast();
    }
}
