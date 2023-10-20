-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

coverage :; forge coverage > coverage.txt

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

UMATimeCard:
	@forge script script/DeployUMATimeCard.s.sol:DeployUMATimeCard --rpc-url $(GOERLI_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(GOERLI_ETHERSCAN_API_KEY) -vvvv

MantleEntrance:
	@forge script script/DeployUMATimeCardEntrance.s.sol:DeployUMATimeCardEntrance --legacy --rpc-url $(MANTLE_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv

ScrollEntrance:
	@forge script script/DeployUMATimeCardEntrance.s.sol:DeployUMATimeCardEntrance --legacy --rpc-url $(SCROLL_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv

# ScrollVerify:
#  	@forge verify-contract \
#     --num-of-optimizations 200 \
#     --watch \
#     --constructor-args  $(cast abi-encode "constructor(uint256,address)" 10121 0x6098e96a28E02f27B1e6BD381f870F1C8Bd169d3) \
#     --verifier etherscan \
#     --verifier-url https://api-sepolia.scrollscan.dev/api \
#     --etherscan-api-key $(SCROLL_ETHERSCAN_API_KEY) \
#     --compiler-version "v0.8.16+commit.07a7930e" \
#     0xf61B64f3d25f399208D347cd8061c5056c336aB1 src/UMATimeCardEntrance.sol:UMATimeCardEntrance

# MantleVerify:
# 	@forge verify-contract --verifier blockscout --watch \
#    --verifier-url "https://explorer.testnet.mantle.xyz/api?module=contract&action=verify" \
#    --compiler-version "v0.8.16+commit.07a7930e" \
#    --num-of-optimizations 200 \
#    --constructor-args $(cast abi-encode "constructor(uint256,address)" 10121 0x2cA20802fd1Fd9649bA8Aa7E50F0C82b479f35fe) \
#    --chain-id 5001 \
#    0xe1Ac6d4752cFBEFC7F3438c4fA5E684889Bba5C1 src/UMATimeCardEntrance.sol:UMATimeCardEntrance
