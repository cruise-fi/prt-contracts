include .env
export

deploy_localhost:
	NETWORK=localhost forge script script/Deploy.s.sol --fork-url http://127.0.0.1:8545 --broadcast

deploy_goerli:
	NETWORK=goerli forge script script/Deploy.s.sol --fork-url $(GOERLI_RPC_URL) --broadcast
