#!/bin/bash
set -ex

CHAIN_ID_1=$1
CREDENTIAL_1=$2
CHAIN_ID_2=$3
CREDENTIAL_2=$4

# TODO: /home/hermes/.hermes/keys/near-0
hermes keys add --chain $CHAIN_ID_1 --key-file $CREDENTIAL_1
hermes keys add --chain $CHAIN_ID_2 --key-file $CREDENTIAL_2
