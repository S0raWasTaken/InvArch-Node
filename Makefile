check:
	cargo check

build:
	cargo build --release

test:
	cargo test

run:
	./target/release/invarch-collator --dev

generate-keys:
	./target/release/invarch-collator key generate --scheme Sr25519 --password-interactive

# generate-derive-keys:
# 	./target/release/invarch-collator key inspect --password-interactive --scheme Ed25519 0xd44687c2ae9c9767027fc2beaf1e7f952bd1f5f1d579430de564245ca2f6ddb8

genesis-state:
	./target/release/invarch-collator export-genesis-state > node/testnet/genesis-state

genesis-wasm:
	./target/release/invarch-collator export-genesis-wasm > node/testnet/genesis-wasm

purge-first-node:
	./target/release/invarch-collator purge-chain --base-path /tmp/node01 --chain local -y

start-collator1:
	./target/release/invarch-collator \
	--collator \
	--alice \
	--force-authoring \
	--tmp \
	--port 40335 \
	--ws-port 9946 \
	-- \
	--execution wasm \
	--chain <relative path local rococo json file> \
	--port 30335

start-collator2:
	./target/release/invarch-collator \
	--collator \
	--bob \
	--force-authoring \
	--tmp \
	--port 40336 \
	--ws-port 9947 \
	-- \
	--execution wasm \
	--chain <relative path local rococo json file> \
	--port 30336

start-parachain-full-node:
	./target/release/invarch-collator \
	--tmp \
	--port 40337 \
	--ws-port 9948 \
	-- \
	--execution wasm \
	--chain <relative path local rococo json file> \
	--port 30337

.PHONY: setup-testing purge-testing download-relay generate-relay-raw-chainspec build generate-both copy-collator-to-testing

generate-genesis-wasm:
	./target/release/invarch-collator export-genesis-wasm > testing/genesis-wasm

generate-genesis-state:
	./target/release/invarch-collator export-genesis-state > testing/genesis-state

generate-both: generate-genesis-state generate-genesis-wasm

download-relay:
	wget -O testing/polkadot "https://github.com/paritytech/polkadot/releases/download/v0.9.17-rc4/polkadot" && \
	chmod +x testing/polkadot

generate-relay-raw-chainspec:
	./testing/polkadot build-spec --chain rococo-local --disable-default-bootnode --raw > ./testing/rococo-chainspec-raw.json

run-relay-alice:
	./testing/polkadot --chain ./testing/rococo-chainspec-raw.json --alice --tmp

run-relay-bob:
	./testing/polkadot --chain ./testing/rococo-chainspec-raw.json --bob --tmp --port 30334

copy-collator-to-testing:
	cp ./target/release/invarch-collator ./testing/

# Safely purge testing directory by only removing the files we use
purge-testing:
	mkdir -p ./testing && \
	rm -f ./testing/rococo-chainspec-raw.json \
				./testing/polkadot \
				./testing/invarch-collator \
				./testing/genesis-state \
				./testing/genesis-wasm

run-parachain-collator:
	./testing/invarch-collator \
		--collator \
		--alice \
		--force-authoring \
		--tmp \
		--port 40335 \
		--ws-port 8844 \
		-- \
		--execution wasm \
		--chain ./testing/rococo-chainspec-raw.json \
		--port 30335

setup-testing: | purge-testing download-relay generate-relay-raw-chainspec build generate-both copy-collator-to-testing
	$(info Setup finished, here's how to proceed with testing:)
	$(info Open 3 terminals, all on $(CURDIR))
	$(info Terminal 1: make run-relay-alice)
	$(info Terminal 2: make run-relay-bob)
	$(info Terminal 3: make run-parachain-collator)
