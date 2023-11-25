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
echo -e "\e[1;33m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1;33m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl tar wget clang pkg-config protobuf-compiler libssl-dev jq build-essential protobuf-compiler bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

#variable gen secretkey
NEW_SEED=$(date | sha256sum | base64 | head -c 32)

# install rust
if ! command -v rustup &> /dev/null
then
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	source ~/.cargo/env
	rustup default stable
	rustup update
	rustup update nightly
	rustup target add wasm32-unknown-unknown --toolchain nightly
	sleep 1
fi

echo -e "\e[1;33m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
git clone https://github.com/availproject/avail-light.git
cd avail-light
wget -O avail-config.yaml https://raw.githubusercontent.com/hiephtdev/huong-dan-chay-full-node-avail/main/avail-config.yaml
# change secretkey
sed -i.bak -e "s/seed={seed}/seed=$NEW_SEED/g" ./avail-config.yaml
echo $NEW_SEED > secretkey.txt

git checkout v1.7.4
cargo build --release
sudo cp $HOME/avail-light/target/release/avail-light /usr/local/bin
# create service
sudo tee /etc/systemd/system/availightd.service > /dev/null <<EOF
[Unit]
Description=Avail Light Client
After=network-online.target

[Service]
User=$USER
ExecStart=$(which avail-light) --config $HOME/avail-light/config.yaml --network goldberg
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
echo -e "\e[1;33mView the logs from the running service, use: journalctl -f -u availightd\e[0m"
echo -e "\e[1;33mCheck if the node is running, enter: sudo systemctl status availightd\e[0m"
echo -e "\e[1;33mStop your Avail node, use: sudo systemctl stop availightd\e[0m"
echo -e "\e[1;33mStart your Avail node, enter: sudo systemctl start availightd\e[0m"
echo -e "\e[1;33mAfter modifying the availd.service file, reload the service using: sudo systemctl daemon-reload\e[0m"
echo -e "\e[1;33mRestart the service, use: sudo systemctl restart availightd\e[0m"