pragma solidity 0.8.21;

import {Deployer} from "src/Deployer.sol";
import {Registry} from "src/Registry.sol";

import "forge-std/Script.sol";

/**
 * @dev Run
 *      `source .env && forge script script/testnet/Deployer.s.sol:DeployerScript --rpc-url $TESTNET_RPC_URL  --private-key $DEPLOYER_DEPLOYER_KEY —optimize —optimizer-runs 200 --with-gas-price 25000000000 --verify --etherscan-api-key $ETHERSCAN_KEY --slow --broadcast`
 *      `source .env && forge script script/testnet/Sepolia.s.sol:DeployerScript --rpc-url $TESTNET_RPC_URL  --private-key $DEPLOYER_KEY —optimize —optimizer-runs 200 --with-gas-price 25000000000 --verify --etherscan-api-key $ETHERSCAN_KEY --slow --broadcast`
 * @dev Optionally can change `--with-gas-price` to something more reasonable
 */
contract DeployerScript is Script {
    Deployer public deployer;
    Registry public registry;
    uint256 deployerPrivateKey;

    //These addresses are can be the same. One it the owner address for the Deployer contract. The other address is permissioned to use the deployer contract for other deployments. They can be the same on testnet.
    address public sommDev;
    address public sommDeployerOwner;

    function setUp() external {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        sommDev = vm.envAddress("SOMM_DEVELOPER_ADDRESS");
        sommDeployerOwner = vm.envAddress("OWNER_ADDRESS");
    }

    function run() external {
        address[] memory deployers = new address[](1);
        deployers[0] = sommDev;

        bytes memory creationCode;
        bytes memory constructorArgs;

        vm.startBroadcast();

        deployer = new Deployer(sommDeployerOwner, deployers);
        deployer.transferOwnership(sommDev);

        creationCode = type(Registry).creationCode;
        constructorArgs = abi.encode(sommDev, sommDev, address(0), address(0));
        registry = Registry(deployer.deployContract("THE-REGISTER", creationCode, constructorArgs, 0));

        vm.stopBroadcast();
    }
}

// contract RegistryScript is Script {
//     Deployer public deployer;
//     Registry public registry;
//     uint256 deployerPrivateKey;

//     //These addresses are can be the same. One it the owner address for the Deployer contract. The other address is permissioned to use the deployer contract for other deployments. They can be the same on testnet.
//     address public sommDev = 0xd1ed25240ecfa47fD2d46D34584c91935c89546c;
//     address public sommDeployerOwner = 0xd1ed25240ecfa47fD2d46D34584c91935c89546c;

//     function setUp() external {
//         deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         deployer = Deployer(0x99E5d7Ff0d6fB4342dd297E073b2eDf137dc93B9);
//     }

//     function run() external {
//         address[] memory deployers = new address[](1);
//         deployers[0] = sommDev;

//         bytes memory creationCode;
//         bytes memory constructorArgs;

//         vm.startBroadcast(deployerPrivateKey);

//         creationCode = type(Registry).creationCode;
//         constructorArgs = abi.encode(sommDev, sommDev, address(0), address(0));
//         registry = Registry(deployer.deployContract("THE-REGISTER", creationCode, constructorArgs, 0));

//         vm.stopBroadcast();
//     }
// }
