# Documents

* [Requirements](#requirements)
* [Installation](#installation)
    * [Setup bsc_full_node](#setup-bscfullnode)
    * [Publish JSON RPC Endpoint](#publish-json-rpc-endpoint)
    * [Sample Nginx Configuration](#sample-nginx-configuration)
* [Maintaince](#maintaince)
* [Development](#development)
    * [Update BSC Binary](#update-bsc-binary)
    * [Testing](#testing)
    * [Packaging](#packaging)

# Requirements

* Platform: Debian-like x86
* Storage: 2TB free, 8K IOPS, 250MB/s throughput, read latency < 1ms.
* CPU: 16 cores
* Memory: 256GB.
* Network: WAN connection, upload/download 5MB/s.

Source: https://docs.binance.org/smart-chain/developer/fullnode.html#fullnode

# Installation

## Setup bsc_full_node

```bash
# Step 1. Dowload package bsc_full_node.
#
# Pick a version from here
# `https://github.com/kevin-leptons/bsc_full_node/releases`
wget "patse download link here"

# Step 2. Install bsc_full_node service.
sudo dpkg -i "path to downloaded file here"

# Step 3. Verify package installation.
#
# It should print status of service. The service is not start by default
# because it requires snapshot data.
systemctl status bsc-full-node

# Step 4. Prepare a directory to store data.
#
# This directory can be anywhere. However it must be in file system that
# has at least 2TB free storage.
#
# The default is `/data/bsc_full_node`. If other path is use then
# configuration file must be update in next step.
mkdir /data/bsc_full_node

# Step 5. Update configuration
#
# Use a text editor and update configuration properly.
cat /etc/bsc_full_node/config

# Step 6. Download data snapshot.
#
# Pick a download link from `https://github.com/binance-chain/bsc-snapshots`.
#
# WARN: The downloading takes 12 hours or more, it should be put into
# background.
wget -O bsc_snapshoot.tar.lz4 "paste download link here"

# Step 7. Uncompress snapshot into data directory.
#
# WARN: The processing takes hours, it should be put into background.
tar -I lz4 zxvf "path to downloaded snapshot file" \
    -C "path to directory at Step 4"

# Step 7. Start service to synchronize data and serve JSON RPC.
sudo systemctl start bsc-full-node

# Step 8. Verify service status.
#
# It should print message that shows service is running.
systemctl status bsc-full-node

# Step 9. Verify synchronization.
#
# It should print message that shows synchronized block number.
sudo bsc_full_node log

# Step 10. Verify JSON RPC.
#
# It should responds status 200. At this time, JSON RPC is only available at
# `http://localhost`. Next section makes accessing to RPC is ready for
# outside requests.
curl -v localhost:8545
```

## Publish JSON RPC Endpoint

```bash
# Step 1. Install packages
sudo install nginx apache2-utils openssl

# Step 2. Make 20 bytes password as base64 encoded.
#
# It should print a string as password. Save the password to safe place.
openssl rand -base64 20

# Step 2. Setup authentication for requests to JSON RPC.
#
# This step create authentication for username `eth`. It should ask
# for password, patse the password at Step 2.
sudo mkdir /etc/nginx/authentication
sudo htpasswd -c /etc/nginx/authentication/bsc_full_node eth

# Step 3. Make a raw nginx configuration from sample.
#
# Copy sample configuration from setcion `Sample Nginx Configuration`
# to `/etc/nginx/sites-avaiable/{DOMAIN_NAME}`. Where `{DOMAIN_NAME}`
# is domain name that serves JSON RPC.

# Step 4. Update nginx configuration.
#
# Use a text editor to update it properly.
vim "path to configuration file at Step 3"

# Step 5. Enable nginx configuration.
ln -sr "path to configuration file at Step 3" /etc/nginx/sites-enabled/

# Step 6. Verify nginx configuration.
#
# If something go wrong then fix configuration until it prints `ok` message.
nginx -t

# Step 7. Restart nginx.
sudo systemctl restart nginx

# Step 8. Verify JSON RPC.
#
# It should responds with status 200.
curl -v https://{DOMAIN_NAME}
```

## Sample Nginx Configuration

```conf
# WARN: This is sample configuration and tt must be update properly.

# Update placeholder:
#
# DOMAIN_NAME: Domain name that serves JSON RPC. It mean that domain name
# should be point to machine that runs service bsc_full_node.
#
# PATH_TO_CERTIFICATE_FILE, PATH_TO_KEY_FILE: Certificates to run secure
# connection over HTTP. It should be work for DOMAIN_NAME.
#
# PATH_TO_PASSOWRD_FILE: Path to file which is made from section
# `Publish JSON RPC Endpoint`, Step 2.

limit_req_zone global zone=rpc_node_01:16m rate=50r/s;

# Serve HTTPS connection.
server {
	listen 443 ssl;
	listen [::]:443 ssl;
	server_name {DOMAIN_NAME};
	ssl_certificate {PATH_TO_CERTIFICATE_FILE};
	ssl_certificate_key {PATH_TO_KEY_FILE};

    limit_req zone=rpc_node_01 burst=128 nodelay;
	auth_basic "Basic Authenticatin is Required";
	auth_basic_user_file {PATH_TO_PASSOWRD_FILE};

	location / {
		proxy_pass http://127.0.0.1:8545/;
	}
}

# Redirect HTTP requests to HTTPS.
server {
	listen 80;
	listen [::]:80;
	server_name {DOMAIN_NAME};

    limit_req zone=rpc_node_01 burst=128 nodelay;

	return 301 https://$host$request_uri;
}
```

# Maintaince

```bash
# Step 1. Stop service.
sudo systemctl stop bsc-full-node

# Step 2. Remove snapshot data.
#
# It takes hours and should be put to background.
bsc-full-node prune-snapshot-data

# Step 3. Start service.
sudo systemctl start bsc-full-node

# Step. Verify service is running.
sudo bsc-full-node log
```

Source: https://docs.binance.org/smart-chain/developer/fullnode.html#node-maintainence.

# Development

## Update BSC Binary

```bash
# Step 1. Change current directory to root of source code.
#
# This step is important because below instruction uses relative file path.
cd bsc_full_node

# Step 2. Read changelog of BSC carefully and consider risks.

# Step 3. Update binary for Linux x86.
# List of binaries here: `https://github.com/binance-chain/bsc/releases`.
wget -O bin/geth_linux "patse download link here"

# Step 4. Update configuration file `config.toml`.
#
# Pick download link of file `mainnet.zip` which is beside binary distribution
# from `Step 3`.
wget -O tmp/mainnet.zip "patse download link here"
unzip tmp/mainnet.zip -d tmp/mainnet
cp tmp/mainnet/config.toml data/geth_config.toml

# Step 5. Update other files.
#
# bin/bsc_full_node: Script to read/validate configuration and start BSC node.
#
# data/sample_config: Sample configuratin for bsc_full_node. It is install to
# `/etc/bsc_full_node` at the first time.
#
# debian/*: Specification and scripts to make Debian package.
#
# systemd/bsc_full_node.service: Define systemd service to manage bsc_full_node
# process.
#
# and so on...
```

References: [Steps to Run a Fullnode](https://docs.binance.org/smart-chain/developer/fullnode.html)

## Testing

```bash
# Step 1. Change current directory to root of source code.
#
# This step is important because below instruction uses relative file path.
cd bsc_full_node

# Step 2. Download snapshot data.
#
# Pick a download link from `https://github.com/binance-chain/bsc-snapshots`.
# It takes hours.
wget -O "path to local download file" "paste download link here"

# Step 3. Uncompress snapshot data.
tar -I lz4 zxvf "path to downloaded snapshot file from Step 2" \
    -C "path to BSC data directory"

# Step 4. Create configuration file.
#
# Copy sample configuration file and update it properly.
# It should point to data directory at Step 3.
cp data/sapmle_config config
vim config

# Step 5. Start servivce.
./bin/bsc_full_node start
```

## Packaging

```bash
sudo apt install make   # install required packages for the first time
make                    # make Debian package.
make clean              # remove build directory
```
