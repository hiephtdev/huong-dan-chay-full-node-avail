#!/bin/bash

echo -e "\e[1;33m"
echo "    __    __  __   __    _____   _______  _____    _____  __          __ _    _    ____  "
echo "   |  \  /  |\  \ /  /  / ____| |__   __||_   _|  / ____| \ \        / /| |  | |  / __ \ "
echo "   |   \/   | \  V  /  | (___      | |     | |   | |       \ \  /\  / / | |__| | | |  | |"
echo "   | |\  /| |  \   /    \___ \     | |     | |   | |        \ \/  \/ /  |  __  | | |  | |"
echo "   | | \/ | |   | |     ____) |    | |    _| |_  | |____     \  /\  /   | |  | | | |__| |"
echo "   |_|    |_|   |_|    |_____/     |_|   |_____|  \_____|     \/  \/    |_|  |_|  \____/ "
echo -e "\e[0m"
sleep 2;
# set vars
AVAIL_P2P_PORT=30333
AVAIL_RPC_PORT=9944
AVAIL_PROMETHEUS_PORT=9615
AVAIL_TAG="v1.8.0.2"
if [ ! $AVAIL_NODE_NAME ]; then
	read -p "Enter node name: " AVAIL_NODE_NAME
	echo 'export AVAIL_NODE_NAME='$AVAIL_NODE_NAME >> $HOME/.bash_profile
fi
source $HOME/.bash_profile
echo "export AVAIL_P2P_PORT=${AVAIL_P2P_PORT}" >> $HOME/.bash_profile
echo "export AVAIL_RPC_PORT=${AVAIL_RPC_PORT}" >> $HOME/.bash_profile
echo "export AVAIL_PROMETHEUS_PORT=${AVAIL_PROMETHEUS_PORT}" >> $HOME/.bash_profile
echo '================================================='
echo -e "Your node name: \e[1;33m$AVAIL_NODE_NAME\e[0m"
echo -e "Your p2p port: \e[1;33m$AVAIL_P2P_PORT\e[0m"
echo -e "Your rpc port: \e[1;33m$AVAIL_RPC_PORT\e[0m"
echo -e "Your prometheus port: \e[1;33m$AVAIL_PROMETHEUS_PORT\e[0m"
echo '================================================='
sleep 2;
echo -e "\e[1;33m1. Updating packages... \e[0m" && sleep 1;
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1;33m2. Installing dependencies... \e[0m" && sleep 1;
# packages
sudo apt install build-essential --assume-yes git clang curl libssl-dev protobuf-compiler -y

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup default stable
rustup update
rustup update nightly
rustup target add wasm32-unknown-unknown --toolchain nightly
sleep 1;
echo -e "\e[1;33m3. Download and build binaries... \e[0m" && sleep 1;
# download binary
git clone https://github.com/availproject/avail.git
cd avail
mkdir -p data
git checkout $AVAIL_TAG
cargo build --release -p data-avail
. $HOME/.bash_profile
sudo cp $HOME/avail/target/release/data-avail /usr/local/bin
# create service
sudo tee /etc/systemd/system/availd.service > /dev/null <<EOF
[Unit]
Description=Avail Validator
After=network-online.target

[Service]
User=$USER
ExecStart=$(which data-avail) -d `pwd`/data --chain goldberg --port $AVAIL_P2P_PORT --rpc-port $AVAIL_RPC_PORT --rpc-cors=all --rpc-external --rpc-methods=unsafe --prometheus-port $AVAIL_PROMETHEUS_PORT --prometheus-external --validator --name $AVAIL_NODE_NAME
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

echo -e "\e[1;33m4. Starting service... \e[0m" && sleep 1;
# start service
sudo systemctl daemon-reload
sudo systemctl enable availd
sudo systemctl restart availd

echo -e "\e[1;33m=============== SETUP FINISHED ===================\e[0m"
echo -e "\e[1;33mView the logs from the running service, use: journalctl -f -u availd.service\e[0m"
echo -e "\e[1;33mCheck if the node is running, enter: sudo systemctl status availd.service\e[0m"
echo -e "\e[1;33mStop your Avail node, use: sudo systemctl stop availd.service\e[0m"
echo -e "\e[1;33mStart your Avail node, enter: sudo systemctl start availd.service\e[0m"
echo -e "\e[1;33mAfter modifying the availd.service file, reload the service using: sudo systemctl daemon-reload\e[0m"
echo -e "\e[1;33mRestart the service, use: sudo systemctl restart availd.service\e[0m"