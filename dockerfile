FROM ubuntu as builder
RUN apt-get update --fix-missing
RUN apt-get install -y git && apt-get install -y curl
RUN git clone -b development https://github.com/InvArch/InvArch-node
RUN apt-get install -y build-essential && \
    apt-get install -y clang && \
    apt-get install -y jq && \
	curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    export PATH="$PATH:$HOME/.cargo/bin" && \
    cd InvArch-node && \
    rustup toolchain install $(cat rust-toolchain.toml | grep -o -P '(?<=").*(?=")') && \
    rustup default stable && \
    rustup target add wasm32-unknown-unknown --toolchain $(cat rust-toolchain.toml | grep -o -P '(?<=").*(?=")') && \
    cargo build --release

# ↑ Build Stage | Final Stage ↓
FROM docker.io/library/ubuntu:20.04
COPY --from=builder /InvArch-node/target/release/invarch-collator /usr/local/bin
COPY --from=builder /etc/ssl/certs/ /etc/ssl/certs/
COPY --from=builder /InvArch-node/node/res/tinker-spec-raw.json /data/tinker-spec-raw.json
COPY --from=builder /InvArch-node/node/res/rococo.json /data/rococo.json


RUN useradd -m -u 1000 -U -s /bin/sh -d /invarch-collator invarch-collator && \
        mkdir -p /invarch-collator/.local/share && \
        chown -R invarch-collator:invarch-collator /data && \
        ln -s /data /invarch-collator/.local/share/invarch-collator && \
        rm -rf /usr/bin /usr/sbin

USER invarch-collator
EXPOSE 30333 9933 9944
VOLUME ["/data"]

EXPOSE 30333 9933 9944

ENTRYPOINT ["/usr/local/bin/invarch-collator"]
