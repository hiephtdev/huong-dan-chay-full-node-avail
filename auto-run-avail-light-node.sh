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
echo "🆙 Starting Availup..."
while [ $# -gt 0 ]; do
    if [[ $1 = "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

# generate folders if missing
for dir in "$HOME/.avail" "$HOME/.avail/bin" "$HOME/.avail/identity" "$HOME/.avail/data" "$HOME/.avail/config"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
done

# check current terminal shell
if [ -z "$BASH_VERSION" ]; then
    if [ -z "$ZSH_VERSION" ]; then
        echo "🚫 Unable to locate a shell. Availup might not work as intended!"
    else
        CURRENT_TERM="zsh"
    fi
else
    CURRENT_TERM="bash"
fi

# find appropriate profile
if [ "$CURRENT_TERM" = "bash" ] || [ "$CURRENT_TERM" = "zsh" ]; then
    for shell_rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.zsh_profile"; do
        if [ -f "$shell_rc" ]; then
            PROFILE="$shell_rc"
            break
        fi
    done
else
    echo "🛑 Unable to locate a compatible shell or rc file, using POSIX default, availup might not work as intended!"
    PROFILE="/etc/profile"
fi

# set default network
if [ -z "$network" ]; then
    echo "🚦 No network selected. Defaulting to goldberg testnet."
    NETWORK="goldberg"
else
    NETWORK="$network"
fi

# configure params
CONFIG_PARAMS="bootstraps=['/dns/bootnode.2.lightclient.goldberg.avail.tools/tcp/37000/p2p/12D3KooWRCgfvaLSnQfkwGehrhSNpY7i5RenWKL2ARst6ZqgdZZd']\nfull_node_ws=['wss://rpc-goldberg.sandbox.avail.tools:443','wss://avail-goldberg.public.blastapi.io:443','wss://lc-rpc-goldberg.avail.tools:443/ws','wss://avail2.polkadotters.com:443/ws','wss://avail-goldberg-rpc.polka.p2p.world:443']\nconfidence=80.0\navail_path='$HOME/.avail/data'\nkad_record_ttl=43200\not_collector_endpoint='http://otelcol.lightclient.goldberg.avail.tools:4317'\ngenesis_hash='6f09966420b2608d1947ccfb0f2a362450d1fc7fd902c29b67c906eaa965a7ae'\nblock_processing_delay=100\noperation_mode='server'\nlog_level='debug'"

# set avail binary path
AVAIL_BIN="$HOME/.avail/bin/avail-light"

# configure network
if [ "$NETWORK" = "goldberg" ]; then
    echo "📒 Goldberg testnet selected."
    VERSION="v1.7.10"
    if [ -z "$config" ]; then
        CONFIG="$HOME/.avail/config/config.yml"
        if [ -f "$CONFIG" ]; then
            echo "🗑️ Wiping old config file at $CONFIG."
            rm "$CONFIG"
        else
            echo "🤷 No configuration file set. This will be automatically generated at startup."
        fi
        touch "$CONFIG"
        echo -e "$CONFIG_PARAMS" >>"$CONFIG"
    else
        CONFIG="$config"
    fi
elif [ "$NETWORK" = "local" ]; then
    echo "📒 Local testnet selected."
    VERSION="v1.7.10"
    if [ -z "$config" ]; then
        echo "🚫 No configuration file was provided for local testnet, exiting."
        exit 1
    fi
else
    echo "🚫 Invalid network selected. Select one of the following: goldberg, local."
    exit 1
fi

# set app ID
if [ -z "$app_id" ]; then
    echo "📱 No app ID specified. Defaulting to light client mode."
    APPID="0"
else
    APPID="$app_id"
fi

# set identity path
if [ -z "$identity" ]; then
    IDENTITY="$HOME/.avail/identity/identity.toml"
    if [ -f "$IDENTITY" ]; then
        echo "🔑 Identity found at $IDENTITY."
    else
        echo "🤷 No identity set. This will be automatically generated at startup."
    fi
else
    IDENTITY="$identity"
fi

# handle WSL systems
if uname -r | grep -qEi "(Microsoft|WSL)"; then
    # force remove IO lock
    if [ -d "$HOME/.avail/data" ]; then
        rm -rf "$HOME/.avail/data"
        mkdir "$HOME/.avail/data"
    fi
    if [ "$force_wsl" != 'y' ] && [ "$force_wsl" != 'yes' ]; then
        echo "👀 WSL detected. This script is not fully compatible with WSL. Please download the Windows runner instead by clicking this link: https://github.com/availproject/avail-light/releases/download/v1.7.10/avail-light-windows-runner.zip Alternatively, rerun the command with --force_wsl y"
        exit 1
    else
        echo "👀 WSL detected. The binary is not fully compatible with WSL but forcing the run anyway."
    fi
fi

# check for upgrades
UPGRADE=0
if [ ! -z "$upgrade" ]; then
    echo "🔃 Checking for updates..."
    if [ -f "$AVAIL_BIN" ]; then
        CURRENT_VERSION="v$("$AVAIL_BIN" --version | cut -d " " -f 2)"
        if [ "$CURRENT_VERSION" != "$VERSION" ]; then
            UPGRADE=1
            echo "⬆️ Avail binary is out of date. Upgrading..."
        elif [ "$upgrade" = "y" ] || [ "$upgrade" = "yes" ]; then
            UPGRADE=1
        fi
    fi
fi

# handle upgrade
if [ "$UPGRADE" = 1 ]; then
    echo "🔃 Resetting configuration and data..."
    if [ -f "$AVAIL_BIN" ]; then
        rm "$AVAIL_BIN"
        if [ -f "$CONFIG" ]; then
            rm "$CONFIG"
            touch "$CONFIG"
            echo -e "$CONFIG_PARAMS" >>"$CONFIG"
        fi
        if [ -d "$HOME/.avail/data" ]; then
            rm -rf "$HOME/.avail/data"
            mkdir "$HOME/.avail/data"
        fi
    else
        echo "🤷 Avail was not installed with availup. Attempting to uninstall with cargo..."
        cargo uninstall avail-light || echo "🚫 Avail was not installed with cargo, upgrade might not be required!"
        if command -v avail-light >/dev/null 2>&1; then
            echo "🚫 Avail was not uninstalled. Please uninstall manually and try again."
            exit 1
        fi
    fi
fi

# check architecture
if [ "$(uname -m)" = "arm64" ] && [ "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="apple-arm64"
elif [ "$(uname -m)" = "x86_64" ] && [ "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="apple-x86_64"
elif [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
    ARCH_STRING="linux-arm64"
elif [ "$(uname -m)" = "x86_64" ]; then
    ARCH_STRING="linux-amd64"
fi

# fetch binary
if [ -z "$ARCH_STRING" ]; then
    echo "📥 No binary available for this architecture, building from source instead. This can take a while..."
    # check for cargo availability
    if command -v cargo >/dev/null 2>&1; then
        echo "📦 Cargo is available. Building from source..."
    else
        echo "🚫 Cargo is not available. Attempting to install with Rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        EXTRAPROMPT="\n⚙️ Cargo env needs to be loaded by running source \$HOME/.cargo/env"
        echo "📦 Cargo is now available. Reattempting to build from source..."
    fi
    # check for avail-light folder existence
    AVAIL_LIGHT_DIR="$HOME/avail-light"
    if [ -d "$AVAIL_LIGHT_DIR" ]; then
        echo "🔄 Updating avail-light repository and building..."
        cd "$AVAIL_LIGHT_DIR"
        git pull -q origin "$VERSION"
        git checkout -q "$VERSION"
        cargo build --release
        cp "$AVAIL_LIGHT_DIR/target/release/avail-light" "$AVAIL_BIN"
    else
        echo "🔄 Cloning avail-light repository and building..."
        git clone -q -c advice.detachedHead=false --depth=1 --single-branch --branch "$VERSION" https://github.com/availproject/avail-light.git "$AVAIL_LIGHT_DIR"
        cd "$AVAIL_LIGHT_DIR"
        cargo build --release
        mv "$AVAIL_LIGHT_DIR/target/release/avail-light" "$AVAIL_BIN"
        rm -rf "$AVAIL_LIGHT_DIR"
    fi
else
    if command -v curl >/dev/null 2>&1; then
        curl -sLO "https://github.com/availproject/avail-light/releases/download/$VERSION/avail-light-$ARCH_STRING.tar.gz"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "https://github.com/availproject/avail-light/releases/download/$VERSION/avail-light-$ARCH_STRING.tar.gz"
    else
        echo "🚫 Neither curl nor wget are available. Please install one of these and try again."
        exit 1
    fi
    # extract and move the binary
    tar -xzf "avail-light-$ARCH_STRING.tar.gz"
    chmod +x "avail-light-$ARCH_STRING"
    mv "avail-light-$ARCH_STRING" "$AVAIL_BIN"
    rm "avail-light-$ARCH_STRING.tar.gz"
fi

echo "✅ Availup exited successfully."
echo "🛠️ Starting Avail."
trap onexit EXIT

# create service
sudo tee /etc/systemd/system/availightd.service > /dev/null <<EOF
[Unit]
Description=Avail Light Client
After=network-online.target

[Service]
User=root
ExecStart="$AVAIL_BIN --config $CONFIG --app-id $APPID --identity $IDENTITY"
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
