# A simple script to get some funds for cellar deployments

export WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
export USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

# address of the deployer account that will deploy also the cellar
export deployer=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720

# unlucky addresses on mainnet that we will impersonate
export UNLUCKY2=0xaB8925d944223c0C403e2AF8366ac2995701fa90
export UNLUCKY=0x6F17CeBEa98d247afEC682aEE781D23059236E3a


echo "---------------------------------------"
echo "USDC balance for $deployer" 
cast call $USDC "balanceOf(address)(uint256)" $deployer

echo "WETH Balance WETH for $deployer"
cast call $WETH "balanceOf(address)(uint256)" $deployer
echo "---------------------------------------"


# moving funds
cast rpc anvil_impersonateAccount $UNLUCKY
cast send $USDC --from $UNLUCKY "transfer(address,uint256)(bool)" $deployer 317314957000000 --unlocked

cast rpc anvil_impersonateAccount $UNLUCKY2
cast send $WETH --from $UNLUCKY2 "transfer(address,uint256)(bool)" $deployer 1697214163577939626000 --unlocked

echo "---------------------------------------"
echo "New USDC balance for $deployer" 
cast call $USDC "balanceOf(address)(uint256)" $deployer

echo "New WETH Balance WETH for $deployer"
cast call $WETH "balanceOf(address)(uint256)" $deployer
echo "---------------------------------------"

