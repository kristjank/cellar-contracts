// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {Deployer} from "src/Deployer.sol";
import {Registry} from "src/Registry.sol";
import {PriceRouter} from "src/modules/price-router/PriceRouter.sol";
import {SequencerPriceRouter} from "src/modules/price-router/permutations/SequencerPriceRouter.sol";
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
import {SepoliaAddresses} from "resources/SepoliaAddresses.sol";
import {SepoliaContractDeploymentNames} from "resources/SepoliaContractDeploymentNames.sol";

import {PositionIds} from "resources/PositionIds.sol";
import {Math} from "src/utils/Math.sol";

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

/**
 * @dev Run
 *      `make sepolia-setup-architecture`  // see Makefile
 */
contract SetUpArchitectureScript is Script, SepoliaAddresses, SepoliaContractDeploymentNames, PositionIds {
    using Math for uint256;
    using stdJson for string;

    uint256 public privateKey;
    Deployer public deployer = Deployer(deployerAddress);
    Registry public registry = Registry(deployer.getAddress(registryName));
    PriceRouter public priceRouter = PriceRouter(priceRouterAddress);
    address public erc20Adaptor;
    address public aaveV3ATokenAdaptor;
    address public aaveV3DebtTokenAdaptor;
    address public uniswapV3Adaptor;

    uint256 public constant AAVE_V3_MIN_HEALTH_FACTOR = 1.01e18;

    uint8 public constant CHAINLINK_DERIVATIVE = 1;
    uint8 public constant TWAP_DERIVATIVE = 2;
    uint8 public constant EXTENSION_DERIVATIVE = 3;

    function setUp() external {
        privateKey = vm.envUint("PRIVATE_KEY");
    }

    function run() external {
        bytes memory creationCode;
        bytes memory constructorArgs;

        vm.startBroadcast(privateKey);

        // Deploy ERC20Adaptor.
        creationCode = type(ERC20Adaptor).creationCode;
        constructorArgs = hex"";
        erc20Adaptor = deployer.deployContract(erc20AdaptorName, creationCode, constructorArgs, 0);

        // Deploy Aave V3 Adaptors.
        creationCode = type(AaveV3ATokenAdaptor).creationCode;
        constructorArgs = abi.encode(aaveV3Pool, aaveV3Oracle, AAVE_V3_MIN_HEALTH_FACTOR);
        aaveV3ATokenAdaptor = deployer.deployContract(aaveV3ATokenAdaptorName, creationCode, constructorArgs, 0);

        creationCode = type(AaveV3DebtTokenAdaptor).creationCode;
        constructorArgs = abi.encode(aaveV3Pool, AAVE_V3_MIN_HEALTH_FACTOR);
        aaveV3DebtTokenAdaptor = deployer.deployContract(aaveV3DebtTokenAdaptorName, creationCode, constructorArgs, 0);

        // Deploy Uniswap V3 Adaptor.
        creationCode = type(UniswapV3PositionTracker).creationCode;
        constructorArgs = abi.encode(uniswapV3PositionManager);
        address tracker = deployer.deployContract(uniswapV3PositionTrackerName, creationCode, constructorArgs, 0);

        creationCode = type(UniswapV3Adaptor).creationCode;
        constructorArgs = abi.encode(uniswapV3PositionManager, tracker);
        uniswapV3Adaptor = deployer.deployContract(uniswapV3AdaptorName, creationCode, constructorArgs, 0);

        // Trust Adaptors in Registry.
        registry.trustAdaptor(erc20Adaptor);
        registry.trustAdaptor(aaveV3ATokenAdaptor);
        registry.trustAdaptor(aaveV3DebtTokenAdaptor);
        registry.trustAdaptor(uniswapV3Adaptor);

        // Add pricing.
        PriceRouter.ChainlinkDerivativeStorage memory stor;
        PriceRouter.AssetSettings memory settings;

        uint256 price = uint256(IChainlinkAggregator(WETH_USD_FEED).latestAnswer());
        settings = PriceRouter.AssetSettings(CHAINLINK_DERIVATIVE, WETH_USD_FEED);
        priceRouter.addAsset(WETH, settings, abi.encode(stor), price);

        price = uint256(IChainlinkAggregator(USDC_USD_FEED).latestAnswer());
        settings = PriceRouter.AssetSettings(CHAINLINK_DERIVATIVE, USDC_USD_FEED);
        priceRouter.addAsset(USDC, settings, abi.encode(stor), price);

        price = uint256(IChainlinkAggregator(DAI_USD_FEED).latestAnswer());
        settings = PriceRouter.AssetSettings(CHAINLINK_DERIVATIVE, DAI_USD_FEED);
        priceRouter.addAsset(DAI, settings, abi.encode(stor), price);

        stor.inETH = true;

        // Add ERC20 positions
        registry.trustPosition(ERC20_USDC_POSITION, address(erc20Adaptor), abi.encode(USDC));
        registry.trustPosition(ERC20_DAI_POSITION, address(erc20Adaptor), abi.encode(DAI));
        registry.trustPosition(ERC20_WETH_POSITION, address(erc20Adaptor), abi.encode(WETH));

        // Add Aave V3 A token positions
        registry.trustPosition(AAVE_V3_LOW_HF_A_USDC_POSITION, address(aaveV3ATokenAdaptor), abi.encode(aV3USDC));
        registry.trustPosition(AAVE_V3_LOW_HF_A_DAI_POSITION, address(aaveV3ATokenAdaptor), abi.encode(aV3DAI));
        registry.trustPosition(AAVE_V3_LOW_HF_A_WETH_POSITION, address(aaveV3ATokenAdaptor), abi.encode(aV3WETH));

        // Add Aave V3 debt token positions
        registry.trustPosition(AAVE_V3_LOW_HF_DEBT_USDC_POSITION, address(aaveV3DebtTokenAdaptor), abi.encode(dV3USDC));
        registry.trustPosition(AAVE_V3_LOW_HF_DEBT_DAI_POSITION, address(aaveV3DebtTokenAdaptor), abi.encode(dV3DAI));
        registry.trustPosition(AAVE_V3_LOW_HF_DEBT_WETH_POSITION, address(aaveV3DebtTokenAdaptor), abi.encode(dV3WETH));

        // Add Uniswap positions
        registry.trustPosition(
            UNISWAP_V3_USDC_DAI_POSITION,
            address(uniswapV3Adaptor),
            abi.encode(address(USDC) < address(DAI) ? [USDC, DAI] : [DAI, USDC])
        );
        _checkTokenOrdering(UNISWAP_V3_USDC_DAI_POSITION);

        vm.stopBroadcast();
    }

    function _checkTokenOrdering(uint32 registryId) internal view {
        (,, bytes memory data,) = registry.getPositionIdToPositionData(registryId);
        (address token0, address token1) = abi.decode(data, (address, address));
        if (token1 < token0) revert("Tokens out of order");
        UniswapV3Pool pool = IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, 100);
        if (address(pool) == address(0)) pool = IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, 500);
        if (address(pool) == address(0)) pool = IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, 3000);
        if (address(pool) != address(0)) {
            if (pool.token0() != token0) revert("Token 0 mismtach");
            if (pool.token1() != token1) revert("Token 1 mismtach");
        }
    }
}

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (UniswapV3Pool pool);
}
