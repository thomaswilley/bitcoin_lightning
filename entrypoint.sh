#!/bin/bash
set -e

# This is setup as a partial node by default. (prune=550)
# to change to a full node (archival) remove prune=550 and add txindex=1

# Construct the expected bitcoin.conf using environment variables,
# with defaults provided for RPC credentials and ZMQ endpoints.

# note rpcbind and rpcallowip. these are open because in compose we don't 
# expose any ports to the host. however, it's straightforward to write in
# some logic or add parameters for those to better lock them down if desired.

EXPECTED_CONF=$(cat <<EOF
rpcuser=${RPC_USER:-defaultuser}
rpcpassword=${RPC_PASS:-defaultpass}
server=1
prune=550
zmqpubrawblock=${ZMQ_BLOCK_URI:-tcp://0.0.0.0:28332}
zmqpubrawtx=${ZMQ_TX_URI:-tcp://0.0.0.0:28333}
rpcbind=0.0.0.0
rpcallowip=0.0.0.0/0
EOF
)

CONF_FILE="/root/.bitcoin/bitcoin.conf"

# Check if bitcoin.conf already exists
if [ -f "$CONF_FILE" ]; then
  CURRENT_CONF=$(cat "$CONF_FILE")
  if [ "$CURRENT_CONF" != "$EXPECTED_CONF" ]; then
    echo "Error: Existing bitcoin.conf does not match expected configuration. Check to confirm you set RPC_USER/RPC_PASS correctly."
    echo "NOTE: This is just a simple sanity check. If you like your new config, just delete the existing one and re-run.\n"
    echo "Expected configuration:"
    echo "$EXPECTED_CONF"
    echo "Found configuration:"
    echo "$CURRENT_CONF"
    exit 1
  fi
  echo "bitcoin.conf exists and matches expected configuration. Continuing..."
else
  echo "Creating bitcoin.conf from environment variables..."
  echo "$EXPECTED_CONF" > "$CONF_FILE"
fi

# Execute bitcoind with any additional command-line parameters.
exec bitcoind -printtoconsole "$@"
