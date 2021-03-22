#!/bin/bash
set -e

if [[ "$1" = "generate-node-key" ]]; then
    echo $1 $2
    for i in `seq 1 $2`; do
	peer_id=$(subkey $1 --file node-key 2>&1)
	echo $peer_id
	mv node-key $peer_id
    done
else
    eval "$@"
fi

