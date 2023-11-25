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

read -p "Do you want to enter seed phrase? (y/n): " answer

# Kiểm tra câu trả lời
if [[ $answer == "y" ]]; then
    # Hỏi người dùng nhập văn bản
    read -p "Enter the text: " text

    # Kiểm tra xem file identity.toml đã tồn tại chưa
    if [[ -f "identity.toml" ]]; then
        echo "identity.toml exists. Creating backup..."
        cp identity.toml identity_backup.toml
        echo "Backup created as identity_backup.toml"
        rm identity.toml
    fi

    # Ghi văn bản vào file identity.toml
    echo "avail_secret_seed_phrase = '$text'" > identity.toml
    echo "Save seed phrase to identity.toml"
elif [[ $answer == "n" ]]; then
    echo "It will create a new key if it doesn't exist on this machine to identity.toml file"
else
    echo "Invalid input. Please enter 'y' or 'n'."
fi

echo -e "\e[1;33m3. Downloading... \e[0m" && sleep 1
# download binary
FOLDER_PATH="$HOME/avail-light"
if [ ! -d "$FOLDER_PATH" ]; then
    mkdir -p "$FOLDER_PATH"
fi
cd $FOLDER_PATH
wget https://github.com/availproject/avail-light/releases/download/v1.7.4/avail-light-linux-amd64.tar.gz
tar -xvzf avail-light-linux-amd64.tar.gz
# create service
sudo tee /etc/systemd/system/availightd.service > /dev/null <<EOF
[Unit]
Description=Avail Light Client
After=network-online.target

[Service]
User=root
ExecStart=$FOLDER_PATH/avail-light-linux-amd64 --network goldberg
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

echo -e "\e[1;33m4. Starting service... \e[0m" && sleep 1;
# start service
sudo systemctl daemon-reload
sudo systemctl enable availightd
sudo systemctl restart availightd

echo -e "\e[1;33m=============== SETUP FINISHED ===================\e[0m"
echo -e "\e[1;33mView the logs from the running service, use: journalctl -f -u availightd\e[0m"
echo -e "\e[1;33mCheck if the node is running, enter: sudo systemctl status availightd\e[0m"
echo -e "\e[1;33mStop your Avail node, use: sudo systemctl stop availightd\e[0m"
echo -e "\e[1;33mStart your Avail node, enter: sudo systemctl start availightd\e[0m"
echo -e "\e[1;33mAfter modifying the availd.service file, reload the service using: sudo systemctl daemon-reload\e[0m"
echo -e "\e[1;33mRestart the service, use: sudo systemctl restart availightd\e[0m"
echo -e "\e[31mPlease download the identity.toml file from the root directory to your computer to back up the seed phrase\e[0m"
