include .env
export

deploy_localhost:
	NETWORK=localhost forge script script/Deploy.s.sol --fork-url http://127.0.0.1:8545 --broadcast

deploy_goerli:
	NETWORK=goerli forge script script/Deploy.s.sol --fork-url $(GOERLI_RPC_URL) --broadcast --verifier etherscan --chain-id 5 --verify

deploy_mainnet:
	NETWORK=mainnet forge script script/Deploy.s.sol --fork-url $(MAINNET_RPC_URL) --broadcast --verifier etherscan --chain-id 1 --verify
