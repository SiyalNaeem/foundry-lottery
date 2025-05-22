-include .env

.PHONY: all test deploy

build :; forge build

test :; forge test

install :; forge install cyfrin/foundry-devops@0.2.2 --no-git && forge install smartcontractkit/chainlink-brownie-contract@1.1.1 --no-git && forge install foundry-rs/forge-std@1.8.2 --no-git && forge install transmissions11/solmate@v6 --no-git

deploy-sepolia :
	@forge script scripts/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account default --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
	 