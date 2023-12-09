#!/bin/bash
set -ex

COMMAND=$1
MONIKER=$2
CHAINID=$3
DATA_DIR=$4
PEERS=$5
IBC_TOKEN_DENOM=$6
ENABLE_GAS=$7
NODE_KEY="/keys/${HOSTNAME##*-}-node_key"

if [ ! -f "$DATA_DIR/config/config.toml" ]; then
    # Initialize node's configuration files
    $COMMAND init $MONIKER --chain-id $CHAINID --home $DATA_DIR

    # Modify the pruning field of app.toml
    sed -i.bak "s/pruning = \"default\"/pruning = \"nothing\"/" $DATA_DIR/config/app.toml
    
    # Modify the persistent_peers field of config.toml
    sed -i.bak "s/persistent_peers = \"\"/persistent_peers = \"${PEERS}\"/" $DATA_DIR/config/config.toml

    # Modify the minimum-gas-price field of app.toml
    sed -i.bak "s#minimum-gas-prices = \"0aotto\"#minimum-gas-prices = \"0${IBC_TOKEN_DENOM}\"#" $DATA_DIR/config/app.toml

    # Copy node_key.json
    cp $NODE_KEY $DATA_DIR/config/node_key.json

    # Copy cosmovisor folder to data directory
    cp -R /root/cosmovisor $DATA_DIR/

    # Create a symbolic link for the current version
    ln -s $DATA_DIR/cosmovisor/genesis $DATA_DIR/cosmovisor/current    
fi

if $ENABLE_GAS; then
    # Modify the minimum-gas-price field of app.toml
    sed -i.bak "s#minimum-gas-prices = \"0${IBC_TOKEN_DENOM}\"#minimum-gas-prices = \"20000000000${IBC_TOKEN_DENOM}\"#" $DATA_DIR/config/app.toml
fi

# Copy cosmovisor folder to data directory
cp -R /root/cosmovisor $DATA_DIR/
