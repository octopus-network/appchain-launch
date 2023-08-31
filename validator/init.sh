#!/bin/bash
set -ex

COMMAND=$1
MONIKER=$2
CHAINID=$3
DATA_DIR=$4
KEYNAME=$5
KEYRING=$6
PEERS=$7

MNEMONIC="/keys/${HOSTNAME##*-}-mnemonic"
PRIV_VALIDATOR_KEY="/keys/${HOSTNAME##*-}-priv_validator_key"
NODE_KEY="/keys/${HOSTNAME##*-}-node_key"

if [ ! -f "$DATA_DIR/config/config.toml" ]; then
    # Initialize validators's and node's configuration files.
    $COMMAND init $MONIKER --chain-id $CHAINID --home $DATA_DIR
    
    # Derive a new private key and encrypt to disk.
    cat $MNEMONIC | $COMMAND keys add $KEYNAME --home $DATA_DIR --keyring-backend $KEYRING --no-backup --recover

    # Modify the persistent_peers field of config.toml
    sed -i.bak "s/persistent_peers = \"\"/persistent_peers = \"${PEERS}\"/" $DATA_DIR/config/config.toml

    # Copy priv_validator_key.json
    cp $PRIV_VALIDATOR_KEY $DATA_DIR/config/priv_validator_key.json

    # Copy node_key.json
    cp $NODE_KEY $DATA_DIR/config/node_key.json
fi
