# Bitcoin + Lightning Node with LndHub & BlueWallet for iOS/Android

This guide explains how to set up and operate a self‑custodied Lightning node
using Docker, LndHub, and BlueWallet. It covers how to configure your node,
fund your Lightning wallet, open payment channels, and interact with the
broader Lightning Network.

---

## Dependencies
- a machine with 0.25-3tb ssd or nvme disk space available (0.25 if you follow
  this exact guide, 2-3tb if you want to run your bitcoind as an archival/full
  node maintaining a full copy of the blockchain (for this guide, will assume
  you have cloned into _/mnt/nvme1/bitcoin_).
- docker on the machine (e.g., on arch: ```sudo pacman -S docker docker-buildx docker-compose```)
- setup docker user, then logout & log back in (```$ sudo usermod -aG docker $USER```) 
  and logout/login to ensure ```docker ps``` works without error.
- we assume this repo/files are in /mnt/nvme1/bitcoin/. and it is the base directory for setup.
- lndhub which is what gives you a URL you will load into bluewallet on your
  phone, so your phone will use your own node. 
  ```git clone https://github.com/BlueWallet/LndHub.git ./LndHub```
- build the lndhub image ```cd LndHub && docker build -t lndhub . && cd ..```
- ```docker compose exec lnd lncli create``` (create (or unlock)) your lnd so
  there's a wallet to work with. lndhub requires this step before it will
  start.
- make /mnt/nvme1/bitcoin/data and /mnt/nvme1/bitcoin/lightning/data directories (mkdir -p)
  /mnt/nvme1/bitcoin/lightning/data (assuming your id is 1000; if you're not sure just finish 
- grant perms so the containers can use them 
  ```sudo chown -R 1000:1000 /mnt/nvme1/bitcoin/lightning/data``` 
  (assuming your id is 1000 (```docker compose exec -it lndhub id``` from the
  running container; you can come back and do this step at the end and restart
  the containers if you need to))
- review the included bitcoind Dockerfile and entrypoint.sh, make sure you are
  comfortable with them and then build bitcoind container 
  ```$ docker build -t my-bitcoin-core .```

The lnd container is provided by the creators of lightning network and
therefore presumed safe/canonical to use as-is for the purposes of this guide.

**Proceeding means you have a working host machine, running docker with docker
images built for bitcoin (my-bitcoin-node) and lndhub.**

## Installation

0. Create a .env file using the .env.example template, replace RPC_USER,
   RPC_PASS, and LND_WALLET_PASS (LND_WALLET_PASS will be the password you also
   manually type in upon creation of your lightning wallet on lnd, as seen in
   that step below.)

1. start only the bitcoin service initially ```docker compose up bitcoin --build -d```

2. create a bitcoin wallet on bitcoin-node, it needs to be legacy type as of
   the writing of this guide, in order to work with this LndHub stack:
   ```docker compose exec bitcoin bitcoin-cli createwallet "default" false false "" false false```
  (use ```docker compose exec bitcoin bitcoin-cli loadwallet "default"``` on subsequent loadups)

3. build and start only the lightning service next ```docker compose up lnd --build -d```

4. create a lightning wallet ```docker compose exec -it lnd lncli create```
  Use a password. Save your password to your .env file (or generally just make
  sure it matches LND_WALLET_PASS in .env)
  (use same command but replace 'create' with 'unlock' on subsequent loadups)

5. start the rest ```docker compose up --build -d```

6. check status (see below for how to do so on each service).
    ```bash
    # bitcoin core (bitcoin-node)
    $ docker compose exec bitcoin-node bitcoin-cli getblockchaininfo

    # lightning network daemon (lnd)
    $ docker compose exec lnd lncli getinfo

    # redis
    $ docker exec -it redis sh
      from within the container:
      $ redis-cli -a $RPC_PASS ping

    # lightning network daemon hub from bluewallet (multi-tenancy)
    $ curl -s http://localhost:3000
    ```

7. visit your LndHub web app at http://<ip-of-host>:3000 

**Proceeding means you have a working lightning stack with your own bitcoin node
and it's fully working!**

## Usage

### 1. Setup BlueWallet to Use Your LndHub
- Open `http://<address-of-lndhub>:3000/` in your browser.
- Launch BlueWallet on your iOS device.
- From the home screen, scan the QR code displayed on your LndHub site. This
  adds your LndHub URL as the default for new Lightning wallets.

### 2. Create Wallets on your phone (within BlueWallet app)
- **Create a BTC Wallet:**
  Set up a standard Bitcoin wallet.
- **Create a Lightning Wallet:**
  This wallet will be used to interact with your LND node.
- **Fund Your BTC Wallet:**
  Send some sats to your BTC wallet.
- **Refill Your Lightning Wallet:**
  In BlueWallet, tap your lightning wallet and use **Manage Funds** >
  **Refill** to transfer sats from your BTC wallet to your Lightning wallet.

  **Special Note:**
  As of Feb 2025, the BlueWallet iOS refill screen defaults to 2 recipients. If
  you don't automatically see the wallet address field populated, try swiping
  right to reveal a recipient that has an address. Remove any extra recipient
  with an empty address so that only one (the correct one) remains.

### 3. Connect With the World

#### How This Lightning Setup Works:
- **Lightning Wallet Funding:**
  Transferring sats into your Lightning wallet makes them available on your LND
  node.
- **Outbound Liquidity via Payment Channels:**
  To send payments externally, you must open a channel with a reputable peer
  (e.g., ACINQ) and lock in sats via an on-chain transaction.
- **Fixed Channel Capacity:**
  The funds locked in a channel (outbound liquidity) remain fixed; additional
  sats in your LND wallet do not automatically increase a channel's capacity.
- **Channel Management:**
  To add liquidity, open additional channels or perform rebalancing. When you
  close channels, any unused sats are returned on‑chain to your LND wallet and
  can then be sent to any Bitcoin wallet.
- **Shared Node Resources:**
  As a node operator, you manage channels. All Lightning transactions draw from
  the channel(s)’ locked funds—not directly from your wallet’s total balance.

#### Finding Reputable Peers:
- Use tools like [Amboss.space](https://amboss.space) to locate reputable LND
  nodes.
- For example, one well‑known node is ACINQ:
  [https://amboss.space/node/03864ef025fde8fb587d989186ce6a4a186895ee44a926bfc370e2c366597a3f8f](https://amboss.space/node/03864ef025fde8fb587d989186ce6a4a186895ee44a926bfc370e2c366597a3f8f) (working as of Feb 2025)

---

### 4. Connect With the World – Example

Below is an example workflow to connect your LND node to ACINQ and open a
payment channel:

#### 4.1 Connect to ACINQ

1. **Obtain ACINQ’s Node Information:**
   From Amboss, note the public key and one of the advertised addresses. For example:
   - **Public Key:** `03864ef025fde8fb587d989186ce6a4a186895ee44a926bfc370e2c366597a3f8f`
   - **Address:** `3.33.236.230:9735` *(replace with the current address as needed)*

2. **Connect via CLI:**
   Execute:
   ```bash
   docker exec -it lnd lncli connect 03864ef025fde8fb587d989186ce6a4a186895ee44a926bfc370e2c366597a3f8f@3.33.236.230:9735

    An empty JSON response ({}) indicates a successful connection.

#### 4.2 Open a Payment Channel

1. **Ensure Sufficient Balance:**
    Verify that your LND wallet has enough sats. For ACINQ, the minimum funding
    amount is typically around 400,000 satoshis. (For example, 0.004 BTC.)

2. **Open the Channel:**
    Open a channel with, say, 450,000 satoshis:
    ```docker exec -it lnd lncli openchannel --node_key=03864ef025fde8fb587d989186ce6a4a186895ee44a926bfc370e2c366597a3f8f --local_amt=450000```

    This command creates an on‑chain funding transaction. Use:
    ```docker exec -it lnd lncli listchannels```
    to monitor when the channel becomes active.

#### 4.3 Pay an External Invoice

 - With the channel open, use BlueWallet to scan and pay an invoice from an
   external service or another user.
 - The payment will be routed using the outbound liquidity locked in your
   channel with ACINQ.

#### 4.4 Managing Channel Liquidity
 - **Adding Liquidity:**
 To increase your outbound capacity, open additional channels with ACINQ or
 other reputable peers.

 - **Closing Channels:**
    When you no longer need a channel, close it to retrieve the remaining funds
    on-chain. For a cooperative close, run:
    ```docker exec -it lnd lncli closechannel --funding_txid=<txid> --output_index=<index>```
    Replace _<txid>_ and _<index>_ with the values from your channel info.
 - After closing, the funds will return to your LND wallet, from which you can
   then send them to any Bitcoin wallet.

That's it. Enjoy experimenting and learning all about it.
