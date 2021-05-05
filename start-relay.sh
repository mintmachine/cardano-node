#!/bin/bash

 cardano-node run \
 --topology /config/testnet-topology.json \
 --database-path /data/db \
 --socket-path /ipc/node.socket \
 --port 3001 \
 --config /config/testnet-config.json
