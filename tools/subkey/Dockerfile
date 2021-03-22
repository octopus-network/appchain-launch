FROM paritytech/ci-linux:production AS compile-image
WORKDIR /builds
RUN cargo install --force subkey --git https://github.com/paritytech/substrate --version 2.0.0 --locked


FROM debian:buster-slim AS runtime-image
WORKDIR /tmp/keys
COPY --from=compile-image /usr/local/cargo/bin/subkey /usr/local/bin/subkey
COPY dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]
# CMD ["generate-node-key"]

# docker build --rm -f "Dockerfile" -t octopus/subkey-tool:1.0.0 "."
