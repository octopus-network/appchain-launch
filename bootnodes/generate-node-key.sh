#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: node-key-count target-directory" >&2
  exit 1
fi

if ! [ -d "$2" ]; then
  echo "$2 not a directory" >&2
  exit 1
fi

for i in `seq 1 $1`; do
	peer_id=$(subkey generate-node-key --file node-key 2>&1)
	echo $peer_id >&2
	mv node-key $2/$peer_id
done
