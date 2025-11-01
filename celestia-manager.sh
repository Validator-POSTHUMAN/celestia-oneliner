#!/bin/bash
set -euo pipefail

# PostHuman Validator - Celestia Node Setup Script
# ------------------------------------------------
# This script automates the setup and management of Celestia nodes.
# Visit https://posthuman.digital for more information and support.
# ------------------------------------------------

# Global variables
MIN_CPU_CORES=16
MIN_RAM_MB=32000
MIN_DISK_GB=2000
GO_VERSION="1.24.1"

# Network Type (can be set via environment: export NETWORK_TYPE=testnet)
NETWORK_TYPE="${NETWORK_TYPE:-mainnet}"
CELESTIA_HOME="${CELESTIA_HOME:-$HOME/.celestia-app}"

# Network-specific configuration (set by configure_network function)
APP_VERSION=""
DEFAULT_CHAIN_ID=""
SNAPSHOT_PRUNED=""
GENESIS_URL=""
ADDRBOOK_URL=""
RPC_URL=""
BRIDGE_VERSION="v0.21.5"
SNAPSHOT_ARCHIVE="https://server-9.itrocket.net/mainnet/celestia/celestia_2025-02-28_4224952_snap.tar.lz4"
SNAPSHOT_BRIDGE="https://server-9.itrocket.net/mainnet/celestia/bridge/celestia_2025-02-27_4219600_snap.tar.lz4"

# Network resources
GENESIS_URL="https://snapshots.posthuman.digital/celestia-mainnet/genesis.json"
ADDRBOOK_URL="https://snapshots.posthuman.digital/celestia-mainnet/addrbook.json"

# RPC URL
RPC_URL="https://rpc.celestia-mainnet.posthuman.digital"

# P2P Configuration
SEEDS="12ad7c73c7e1f2460941326937a039139aa78884@celestia-mainnet-seed.itrocket.net:40656"
PEERS="cd9f852141cd6f78e9443cea389911a6f0a5df72@8.52.247.252:26656,d535cbf8d0efd9100649aa3f53cb5cbab33ef2d6@celestia-mainnet-peer.itrocket.net:40656,eda6c9d514615893c77c379f29ce7668b575953d@195.14.6.129:26005,d99aec7727865baeb2f408ac80b120b1e14cffd1@65.109.122.249:11656,d0c4affc656bad26d7a46e4b946c0be71baa4a1f@46.4.51.104:11656,e263dbf2fbd4734a364dac1236bb8cbd83a0c012@157.90.33.62:28656,ff2088fe31a66724589a9bddf84d80981ddcacb3@176.9.10.245:26656,b519fc0c69726b43de28b82f998c8db7faf9741d@5.9.89.67:15670,3666a13ae086942cf6cda89b07b85491b5214669@65.21.227.52:26656,a71a4c58dce5b2268e3c7f229608772327110ee5@65.109.54.91:11056,54fe9521244b0d88da9552224e2c15fd077aa538@57.129.54.6:26656,adc25baad908bc1c84cd5690017fb409afc2400c@46.4.72.249:26630,2ae2d3d0b97c4fcd134decb202ac241cd2f44735@37.252.186.118:2000,9720064ae57d59c0f4a50db963e4b068f0f29594@136.243.21.50:29656,a7705a8dc73cb73abb381294e9136093f6555776@65.21.171.53:1500,423c5758cc785fe04d4e095630856f354c627e51@104.219.237.146:26656,396673f9d0559a2ec8b44016ef591dee96831989@148.251.13.186:11656,acca7837e4eb5f9dc7f5a94ed1d82edda6931ff8@135.181.246.172:26656,a5f01c0afea36df559b8d92e55626c0b5275dfd0@103.219.169.97:43656,3e45091b0cfa3915c2dffcb8a28f2c8fbf319afc@69.67.150.107:29656,711cdf89f5d709587c0b4beb9b67b5979948aac6@139.84.238.188:11656,e1b058e5cfa2b836ddaa496b10911da62dcf182e@164.152.161.199:26656,de0e7c1fc02158a14f6d7dfc40604917ef88b4ea@135.148.169.198:11656,9d4afca92c2d6e681d3605ae25cb1817620a9604@35.195.100.59:26656"


###################
# Core Functions
###################

check_and_install_bbr() {
    echo "Checking BBR congestion control..."

    if grep -q "bbr" /proc/sys/net/ipv4/tcp_congestion_control; then
        echo "✅ BBR is already enabled"
        return 0
    fi

    echo "Installing and enabling BBR..."

    if ! sudo modprobe tcp_bbr; then
        echo "❌ Failed to load BBR module"
        return 1
    fi

    # Add BBR configuration to sysctl
    cat << EOF | sudo tee /etc/sysctl.d/99-bbr.conf > /dev/null
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

    # Apply sysctl settings
    if ! sudo sysctl -p /etc/sysctl.d/99-bbr.conf; then
        echo "❌ Failed to apply BBR settings"
        return 1
    fi

    # Verify BBR is enabled
    if grep -q "bbr" /proc/sys/net/ipv4/tcp_congestion_control; then
        echo "✅ BBR has been successfully enabled"
        return 0
    else
        echo "❌ Failed to enable BBR"
        return 1
    fi
}


# Configure network-specific variables
configure_network() {
    if [[ "$NETWORK_TYPE" == "mainnet" ]]; then
        APP_VERSION="v5.0.11"
        DEFAULT_CHAIN_ID="celestia"
        SNAPSHOT_PRUNED="https://snapshots.posthuman.digital/celestia-mainnet/snapshot-latest.tar.zst"
        GENESIS_URL="https://snapshots.posthuman.digital/celestia-mainnet/genesis.json"
        ADDRBOOK_URL="https://snapshots.posthuman.digital/celestia-mainnet/addrbook.json"
        RPC_URL="https://rpc-celestia-mainnet.posthuman.digital"
        PEERS="2cc7330049bc02e4276668c414222593d52eb718@peer-celestia-mainnet.posthuman.digital:40656"
    elif [[ "$NETWORK_TYPE" == "testnet" ]]; then
        APP_VERSION="v6.2.0-mocha"
        DEFAULT_CHAIN_ID="mocha-4"
        SNAPSHOT_PRUNED="https://snapshots.posthuman.digital/celestia-testnet/snapshot-latest.tar.zst"
        GENESIS_URL="https://snapshots.posthuman.digital/celestia-testnet/genesis.json"
        ADDRBOOK_URL="https://snapshots.posthuman.digital/celestia-testnet/addrbook.json"
        RPC_URL="https://rpc-celestia-testnet.posthuman.digital"
        PEERS=""
    fi
}

# Select network type
select_network() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║     Select Network Type      ║"
    echo "╚══════════════════════════════╝"
    echo "  1. Mainnet (celestia)"
    echo "  2. Testnet (mocha-4)"
    echo ""
    echo "  Current: $NETWORK_TYPE"
    echo ""
    read -rp "Enter your choice [1-2] or press Enter to keep current: " net_choice
    
    case $net_choice in
        1) export NETWORK_TYPE="mainnet" ;;
        2) export NETWORK_TYPE="testnet" ;;
        "") ;;  # Keep current
        *) echo "Invalid choice. Keeping current: $NETWORK_TYPE" ;;
    esac
    
    configure_network
    echo -e "\n✅ Network: $NETWORK_TYPE"
    echo "   Chain ID: $DEFAULT_CHAIN_ID"
    echo "   Version: $APP_VERSION"
}

# Select custom installation directory
select_custom_directory() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║   Installation Directory     ║"
    echo "╚══════════════════════════════╝"
    echo ""
    echo "Default: $CELESTIA_HOME"
    echo "Current: $CELESTIA_HOME"
    echo ""
    read -rp "Use custom directory? (y/N): " use_custom
    
    if [[ "$use_custom" == "y" || "$use_custom" == "Y" ]]; then
        read -rp "Enter directory path (e.g., /mnt/nvme/.celestia-app): " custom_dir
        if [[ -n "$custom_dir" ]]; then
            export CELESTIA_HOME="$custom_dir"
            echo "✅ Will use: $CELESTIA_HOME"
            
            if [[ ! -d "$CELESTIA_HOME" ]]; then
                read -rp "Directory doesn't exist. Create it? (y/N): " create_dir
                if [[ "$create_dir" == "y" || "$create_dir" == "Y" ]]; then
                    mkdir -p "$CELESTIA_HOME" || {
                        echo "❌ Failed to create directory"
                        export CELESTIA_HOME="$CELESTIA_HOME"
                        return 1
                    }
                    echo "✅ Directory created"
                fi
            fi
        fi
    fi
    
    echo "📁 Installation directory: $CELESTIA_HOME"
}

check_system_requirements() {
    echo "Validating system specifications..."
    local cpu_cores=$(nproc --all)
    local ram_mb=$(awk '/MemTotal/ {print int($2 / 1024)}' /proc/meminfo)
    local disk_gb=$(df --output=avail / | tail -1 | awk '{print int($1 / 1024 / 1024)}')

    if (( cpu_cores < MIN_CPU_CORES )); then
        echo "Warning: Available CPU cores (${cpu_cores}) are fewer than required (${MIN_CPU_CORES})."
        read -rp "Do you want to continue anyway? (y/N): " choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            return 1
        fi
    fi

    if (( ram_mb < MIN_RAM_MB )); then
        echo "Warning: Available RAM (${ram_mb}MB) is less than required (${MIN_RAM_MB}MB)."
        read -rp "Do you want to continue anyway? (y/N): " choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            return 1
        fi
    fi

    if (( disk_gb < MIN_DISK_GB )); then
        echo "Warning: Available disk space (${disk_gb}GB) is less than required (${MIN_DISK_GB}GB)."
        read -rp "Do you want to continue anyway? (y/N): " choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            return 1
        fi
    fi

    echo "System requirements check completed."
    return 0
}

###################
# Installation Functions
###################

install_dependencies() {
    echo "Installing dependencies..."
    sudo apt update
#    sudo apt upgrade -y
    sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y
}

install_go() {
    echo "Checking Go installation..."

    # Check if Go is already installed
    if command -v go &> /dev/null; then
        current_version=$(go version | awk '{print $3}' | sed 's/go//')
        if [ "$current_version" = "$GO_VERSION" ]; then
            echo "✅ Go $GO_VERSION is already installed"
            return 0
        else
            echo "ℹ️  Found Go version $current_version, but $GO_VERSION is required"
            read -rp "Do you want to update Go? (y/N): " choice
            if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
                echo "Keeping current Go installation"
                return 0
            fi
        fi
    fi

    echo "Installing Go version $GO_VERSION..."
    cd $HOME
    wget "https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$GO_VERSION.linux-amd64.tar.gz"
    rm "go$GO_VERSION.linux-amd64.tar.gz"

    # Check if PATH already contains Go paths
    if ! grep -q ":/usr/local/go/bin:" ~/.bash_profile && ! grep -q "~/go/bin" ~/.bash_profile; then
        [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
        echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
    fi

    source $HOME/.bash_profile
    [ ! -d ~/go/bin ] && mkdir -p ~/go/bin

    # Verify installation
    if go version &> /dev/null; then
        echo "✅ Go $GO_VERSION installed successfully"
    else
        echo "❌ Error: Go installation failed"
        return 1
    fi
}

set_environment_variables() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║   Environment Variables      ║"
    echo "╚══════════════════════════════╝"

    # Check if variables are already set
    local vars_exist=false
    if grep -q "CELESTIA_" "$HOME/.bash_profile"; then
        echo "Current environment variables:"
        grep "CELESTIA_" "$HOME/.bash_profile"
        read -rp "Do you want to update these variables? (y/N): " update_choice
        if [[ "$update_choice" != "y" && "$update_choice" != "Y" ]]; then
            echo "Keeping existing variables."
            source "$HOME/.bash_profile"
            return 0
        fi
        vars_exist=true
    fi

    # Prompt for custom values
    read -rp "Enter wallet name (default: wallet): " wallet_name
    read -rp "Enter moniker/validator name (default: test): " moniker_name
    read -rp "Enter custom port prefix (default: 40): " port_number

    # Set default values if empty
    WALLET=${wallet_name:-"wallet"}
    MONIKER=${moniker_name:-"test"}
    CELESTIA_PORT=${port_number:-"40"}
    CELESTIA_CHAIN_ID=${CELESTIA_CHAIN_ID:-"$DEFAULT_CHAIN_ID"}

    # Update or add variables to .bash_profile
    if [ "$vars_exist" = true ]; then
        # Remove existing variables
        sed -i '/WALLET=/d' "$HOME/.bash_profile"
        sed -i '/MONIKER=/d' "$HOME/.bash_profile"
        sed -i '/CELESTIA_CHAIN_ID=/d' "$HOME/.bash_profile"
        sed -i '/CELESTIA_PORT=/d' "$HOME/.bash_profile"
    fi

    # Add new variables
    {
        echo "export WALLET=\"$WALLET\""
        echo "export MONIKER=\"$MONIKER\""
        echo "export CELESTIA_CHAIN_ID=\"$CELESTIA_CHAIN_ID\""
        echo "export CELESTIA_PORT=\"$CELESTIA_PORT\""
    } >> "$HOME/.bash_profile"

    # Load new variables into current session
    source "$HOME/.bash_profile"

    echo -e "\nEnvironment variables have been set:"
    echo "WALLET: $WALLET"
    echo "MONIKER: $MONIKER"
    echo "CELESTIA_CHAIN_ID: $CELESTIA_CHAIN_ID"
    echo "CELESTIA_PORT: $CELESTIA_PORT"

    return 0
}

install_node_consensus() {
    local node_type=$1    # "pruned" or "archive"
    local indexer_type=$2 # "on" or "off"

    echo "Installing Celestia consensus node..."
    echo "Node type: $node_type"
    echo "Indexer: $indexer_type"

    # Install dependencies and Go
    check_system_requirements
    check_and_install_bbr
    set_environment_variables
    install_dependencies
    install_go

    # Download and build binary
    echo "Building Celestia binary..."
    cd $HOME
    rm -rf celestia-app
    git clone https://github.com/celestiaorg/celestia-app.git
    cd celestia-app/
    git checkout tags/$APP_VERSION -b $APP_VERSION
    make install
    #mv $HOME/celestia-app/build/celestia-appd $HOME/go/bin/celestia-appd


    # Configure and initialize app
    echo "Configuring Celestia node..."
    celestia-appd config node tcp://localhost:${CELESTIA_PORT}657
    celestia-appd config keyring-backend os
    celestia-appd config chain-id $CELESTIA_CHAIN_ID
    celestia-appd init $MONIKER --chain-id $CELESTIA_CHAIN_ID
    celestia-appd download-genesis $CELESTIA_CHAIN_ID

    # Download genesis and addrbook
    wget -O $CELESTIA_HOME/config/genesis.json "$GENESIS_URL"
    wget -O $CELESTIA_HOME/config/addrbook.json "$ADDRBOOK_URL"

    # Set custom ports first
    sed -i.bak -e "s%:26658%:${CELESTIA_PORT}658%g;
    s%:26657%:${CELESTIA_PORT}657%g;
    s%:6060%:${CELESTIA_PORT}060%g;
    s%:26656%:${CELESTIA_PORT}656%g;
    s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CELESTIA_PORT}656\"%;
    s%:26660%:${CELESTIA_PORT}660%g" $CELESTIA_HOME/config/config.toml

    # Then update the SEEDS and PEERS variables with correct ports
    local updated_seeds=$(echo "$SEEDS" | sed "s/:26656/:${CELESTIA_PORT}656/g")

    # Set seeds and peers after port configuration
    sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$updated_seeds\"/}" \
           -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $CELESTIA_HOME/config/config.toml

    # Configure pruning based on node type
    echo "Configuring pruning settings for $node_type node..."
    if [ "$node_type" = "pruned" ]; then
        sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $CELESTIA_HOME/config/app.toml
        sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $CELESTIA_HOME/config/app.toml
        sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $CELESTIA_HOME/config/app.toml
    else
        sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $CELESTIA_HOME/config/app.toml
    fi

    # Configure indexer
    echo "Setting indexer to ${indexer_type}..."
    if [ "$indexer_type" = "on" ]; then
        sed -i -e "s/^indexer *=.*/indexer = \"kv\"/" $CELESTIA_HOME/config/config.toml
    else
        sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $CELESTIA_HOME/config/config.toml
    fi

    # Set minimum gas price and enable prometheus
    sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.002utia"|g' $CELESTIA_HOME/config/app.toml
    sed -i -e "s/prometheus = false/prometheus = true/" $CELESTIA_HOME/config/config.toml

    # Create service file
    echo "Creating systemd service..."
    sudo tee /etc/systemd/system/celestia-appd.service > /dev/null <<EOF
[Unit]
Description=Celestia node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$CELESTIA_HOME
ExecStart=$(which celestia-appd) start --home $CELESTIA_HOME
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

    # Reset and download snapshot
    echo "Downloading snapshot..."
    celestia-appd tendermint unsafe-reset-all --home $CELESTIA_HOME
    if curl -s --head curl $SNAPSHOT_PRUNED | head -n 1 | grep "200" > /dev/null; then
        curl $SNAPSHOT_PRUNED | zstd -d | tar -xf - -C $CELESTIA_HOME
    else
        echo "No snapshot found"
    fi

    # Enable and start service
    echo "Starting Celestia node..."
    sudo systemctl daemon-reload
    sudo systemctl enable celestia-appd
    sudo systemctl restart celestia-appd

    echo "Installation completed! To check logs, use: sudo journalctl -u celestia-appd -fo cat"
}

install_node_bridge() {
    local sync_type=$1    # "archive" or "snapshot"

    echo -e "\n╔══════════════════════════════╗"
    echo "║   Installing Bridge Node     ║"
    echo "╚══════════════════════════════╝"

    # Add filesystem check before other checks
    check_filesystem_type || return 1

    # Install dependencies and Go
    check_system_requirements
    set_environment_variables
    install_dependencies
    install_go

    # Install Celestia-node
    echo "Installing Celestia node..."
    cd $HOME
    rm -rf celestia-node
    git clone https://github.com/celestiaorg/celestia-node.git
    cd celestia-node/
    git checkout tags/$BRIDGE_VERSION
    make build
    sudo make install
    make cel-key

    # Initialize bridge node
    echo "Initializing bridge node..."
    read -rp "Enter Core RPC node IP: " rpc_node_ip
    celestia bridge init --core.ip "$rpc_node_ip"

    # Show wallet information
    echo -e "\nBridge node wallet information:"
    cd $HOME/celestia-node
    ./cel-key list --node.type bridge --keyring-backend os
    echo -e "\n⚠️  Remember to fund this address with Mainnet tokens for PayForBlob transactions!"

    # Create service file
    echo "Creating systemd service..."
    sudo tee /etc/systemd/system/celestia-bridge.service > /dev/null <<EOF
[Unit]
Description=celestia Bridge
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) bridge start --archival \
--metrics.tls=true --metrics --metrics.endpoint otel.celestia.observer
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    # If snapshot was selected, download and apply it
    if [ "$sync_type" = "snapshot" ]; then
        echo -e "\nDownloading and applying snapshot..."
        echo "⚠️  This process may take several hours. Consider using tmux for the download."
        read -rp "Press Enter to continue..."

        cd $HOME
        aria2c -x 16 -s 16 -o celestia-bridge-snap.tar.lz4 \
            "$SNAPSHOT_BRIDGE"

        sudo systemctl stop celestia-bridge
        rm -rf ~/.celestia-bridge/{blocks,data,index,inverted_index,transients,.lock}
        tar -I lz4 -xvf ~/celestia-bridge-snap.tar.lz4 -C ~/.celestia-bridge/
        rm ~/celestia-bridge-snap.tar.lz4
    fi

    # Enable and start service
    echo "Starting bridge node..."
    sudo systemctl daemon-reload
    sudo systemctl enable celestia-bridge
    sudo systemctl restart celestia-bridge

    # Get peer ID information
    echo -e "\nWaiting for node to start to generate peer ID..."
    sleep 10
    NODE_TYPE=bridge
    AUTH_TOKEN=$(celestia $NODE_TYPE auth admin)
    echo -e "\nYour node's peer ID:"
    curl -X POST \
         -H "Authorization: Bearer $AUTH_TOKEN" \
         -H 'Content-Type: application/json' \
         -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
         http://localhost:26658

    echo -e "\n✅ Bridge node installation completed!"
    echo "To check logs, use: sudo journalctl -u celestia-bridge -fo cat"

    return 0
}

check_filesystem_type() {
    echo "Checking filesystem type..."

    # Get the filesystem type of the directory where .celestia-bridge will be stored
    local target_dir="$HOME/.celestia-bridge"
    local fs_type=$(df -T "$HOME" | awk 'NR==2 {print $2}')

    if [ "$fs_type" = "ext4" ]; then
        echo -e "\n⚠️  WARNING: EXT4 filesystem detected!"
        echo "Running a bridge or full storage node on ext4 may cause errors due to large folder size."
        echo -e "\nRecommended solutions:"
        echo "1. Migrate to XFS/ZFS filesystem (recommended)"
        echo "2. Modify ext4 to support large directories (if using separate partition)"
        echo -e "\nFor ext4 modification:"
        echo "1. Stop the node"
        echo "2. Unmount the drive"
        echo "3. Run: tune2fs -O large_dir /dev/yourpartition"
        echo "4. Run: fsck -f /dev/yourpartition"
        echo "5. Remount the partition"
        echo -e "\nIf running on root/same partition as OS, we strongly recommend:"
        echo "- Redo the node installation with XFS/ZFS"
        echo "- Backup your node ID (files in keys folder) before proceeding"

        read -rp "Do you want to proceed with installation anyway? (y/N): " choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            echo "Installation cancelled."
            return 1
        fi
        echo "Proceeding with installation on ext4..."
    else
        echo "✅ Filesystem type ($fs_type) is suitable for bridge node operation"
    fi

    return 0
}

###################
# Node Operation Functions
###################

check_node_installed() {
    if ! command -v celestia-appd &> /dev/null; then
        echo "❌ Error: celestia-appd is not installed!"
        echo "Please install the node first."
        return 1
    fi
    return 0
}

node_info() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║         Node Info            ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1

    if ! status_output=$(celestia-appd status 2>&1); then
        echo "❌ Error: Unable to get node status. Is the node running?"
        echo "Try starting the service with: sudo systemctl start celestia-appd"
        return 1
    fi

    echo "$status_output" | jq . || {
        echo "❌ Error: Unable to parse node status output."
        echo "Raw output:"
        echo "$status_output"
    }
}

install_cosmovisor() {
    # TODO: Implement cosmovisor installation
    echo "Function not implemented: install_cosmovisor"
}

install_snapshot() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║     Install Snapshot         ║"
    echo "╚══════════════════════════════╝"

    # Check if node is installed
    check_node_installed || return 1

    # Detect node type
    local node_type
    if grep -q "^pruning = \"nothing\"" "$CELESTIA_HOME/config/app.toml"; then
        node_type="archive"
    else
        node_type="pruned"
    fi

    echo "Detected node type: $node_type"
    if [ "$node_type" = "pruned" ]; then
        echo "Will download pruned snapshot"
    else
        echo "Will download archive snapshot"
    fi

    read -rp "Do you want to proceed with snapshot installation? (y/N): " initial_confirm
    if [[ "$initial_confirm" != "y" && "$initial_confirm" != "Y" ]]; then
        echo "Operation cancelled."
        return 1
    fi

    # Install additional dependencies
    sudo apt update && sudo apt install -y tmux aria2

    # Backup validator state
    echo "Stopping node and backing up validator state..."
    sudo systemctl stop celestia-appd
    cp $CELESTIA_HOME/data/priv_validator_state.json $CELESTIA_HOME/priv_validator_state.json.backup 2>/dev/null || true

    if [ "$node_type" = "pruned" ]; then
        echo "Downloading pruned snapshot..."
        rm -rf $CELESTIA_HOME/data
        curl $SNAPSHOT_PRUNED | zstd -d | tar -xf - -C $CELESTIA_HOME
    else
        echo "⚠️  Archive snapshot will take several hours to download."
        echo "It's recommended to use tmux for this operation."

        # Disable statesync to avoid sync issues
        sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" $CELESTIA_HOME/config/config.toml

        echo "Downloading archive snapshot..."
        cd $HOME
        aria2c -x 16 -s 16 -o celestia-archive-snap.tar.lz4 $SNAPSHOT_ARCHIVE

        echo "Extracting archive snapshot..."
        rm -rf $CELESTIA_HOME/data
        tar -I lz4 -xvf ~/celestia-archive-snap.tar.lz4 -C $CELESTIA_HOME
        rm ~/celestia-archive-snap.tar.lz4
    fi

    # Restore validator state if backup exists
    if [ -f "$CELESTIA_HOME/priv_validator_state.json.backup" ]; then
        echo "Restoring validator state..."
        mv $CELESTIA_HOME/priv_validator_state.json.backup $CELESTIA_HOME/data/priv_validator_state.json
    fi

    # Restart node
    echo "Starting node..."
    sudo systemctl restart celestia-appd

    echo -e "\n✅ Snapshot installation completed!"
    echo "Showing logs (press Ctrl+C to exit)..."
    sudo journalctl -u celestia-appd -fo cat
}

update_node() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║       Update Node            ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    source "$HOME/.bash_profile"

    # Show current version
    current_version=$(celestia-appd version 2>/dev/null || echo "unknown")
    echo -e "\n📊 Current version: $current_version"
    echo "📦 Recommended version: v5.0.11"
    echo ""
    
    read -rp "Enter version to update to (press Enter for v5.0.11): " version_input

    # Use recommended version if empty
    if [[ -z "$version_input" ]]; then
        version_input="v5.0.11"
        echo "✅ Using recommended version: $version_input"
    else
        # Add 'v' prefix if not present
        [[ $version_input != v* ]] && version_input="v$version_input"
    fi

    # Confirm update
    echo ""
    read -rp "Update from $current_version to $version_input? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "❌ Update cancelled"
        return 1
    fi

    # Update APP_VERSION in .bash_profile if exists
    if grep -q "APP_VERSION=" "$HOME/.bash_profile" 2>/dev/null; then
        sed -i "/APP_VERSION=/c\export APP_VERSION=$version_input" "$HOME/.bash_profile"
    else
        echo "export APP_VERSION=$version_input" >> "$HOME/.bash_profile"
    fi
    source "$HOME/.bash_profile"

    echo -e "\n⏳ Updating Celestia node to version $version_input..."
    
    # Stop service
    echo "🛑 Stopping celestia-appd service..."
    sudo systemctl stop celestia-appd

    # Download and build
    cd "$HOME"
    rm -rf celestia-app
    git clone https://github.com/celestiaorg/celestia-app.git
    cd celestia-app/
    
    if ! git checkout tags/$version_input -b $version_input 2>/dev/null; then
        echo "❌ Version $version_input not found. Please check available versions."
        sudo systemctl start celestia-appd
        return 1
    fi
    
    echo "🔨 Building binary..."
    if ! make install; then
        echo "❌ Build failed. Restarting old version..."
        sudo systemctl start celestia-appd
        return 1
    fi

    # Verify version
    new_version=$(celestia-appd version 2>/dev/null || echo "unknown")
    echo -e "\n✅ New version installed: $new_version"

    echo "🔄 Restarting celestia-appd service..."
    sudo systemctl restart celestia-appd
    sleep 3

    if sudo systemctl is-active --quiet celestia-appd; then
        echo -e "\n✅ Node updated successfully!"
        echo "   Old version: $current_version"
        echo "   New version: $new_version"
        echo ""
        read -rp "Show logs? (y/N): " show_logs
        if [[ "$show_logs" == "y" || "$show_logs" == "Y" ]]; then
            echo -e "\nShowing logs (press Ctrl+C to exit)..."
            sudo journalctl -u celestia-appd -f --no-hostname -o cat
        fi
    else
        echo "❌ Service failed to start. Check logs:"
        sudo journalctl -u celestia-appd -n 50 --no-pager
        return 1
    fi
}



configure_firewall() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║    Firewall Configuration    ║"
    echo "╚══════════════════════════════╝"

    # Check if environment variables exist and set them if needed
    if ! grep -q "CELESTIA_PORT" "$HOME/.bash_profile"; then
        echo "Required environment variables not found."
        set_environment_variables || return 1
    fi

    # Source environment variables
    source "$HOME/.bash_profile"

    echo "Setting up UFW firewall rules..."
    echo "- Allow outgoing connections"
    echo "- Deny incoming connections by default"
    echo "- Allow SSH access"
    echo "- Allow Celestia P2P port (${CELESTIA_PORT}656)"

    # Configure UFW
    sudo ufw default allow outgoing || { echo "Failed to set default outgoing policy"; return 1; }
    sudo ufw default deny incoming || { echo "Failed to set default incoming policy"; return 1; }
    sudo ufw allow ssh/tcp || { echo "Failed to allow SSH"; return 1; }
    sudo ufw allow "${CELESTIA_PORT}656"/tcp || { echo "Failed to allow Celestia P2P port"; return 1; }

    echo "Enabling UFW..."
    echo "y" | sudo ufw enable || { echo "Failed to enable UFW"; return 1; }

    echo -e "\n✅ Firewall configuration completed!"
    echo "Current UFW status:"
    sudo ufw status numbered
}

toggle_rpc() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║         Toggle RPC           ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    source "$HOME/.bash_profile"
    CELESTIA_PORT=${CELESTIA_PORT:-"40"}

    # Check current RPC status from config.toml
    local rpc_address=$(grep "^laddr = " "$CELESTIA_HOME/config/config.toml" | grep "tcp://" | cut -d'"' -f2)
    local is_enabled=$(echo "$rpc_address" | grep -c "0.0.0.0")

    echo "Current RPC status:"
    echo "Address: $rpc_address"
    echo "Enabled for external access: $([ "$is_enabled" -eq 1 ] && echo "yes" || echo "no")"
    echo ""
    read -rp "Do you want to toggle RPC access? (y/N): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        return 0
    fi

    if [ "$is_enabled" -eq 1 ]; then
        echo "Disabling external RPC access..."
        # Change from 0.0.0.0 to 127.0.0.1
        sed -i 's|^laddr = "tcp://0.0.0.0:'${CELESTIA_PORT}'657"|laddr = "tcp://127.0.0.1:'${CELESTIA_PORT}'657"|' "$CELESTIA_HOME/config/config.toml"
        # Remove firewall rule
        sudo ufw delete allow "${CELESTIA_PORT}657" 2>/dev/null || true
        echo "✅ RPC restricted to localhost and port closed"
    else
        echo "Enabling external RPC access..."
        # Change from 127.0.0.1 to 0.0.0.0
        sed -i 's|^laddr = "tcp://127.0.0.1:'${CELESTIA_PORT}'657"|laddr = "tcp://0.0.0.0:'${CELESTIA_PORT}'657"|' "$CELESTIA_HOME/config/config.toml"
        # Add firewall rule
        sudo ufw allow "${CELESTIA_PORT}657" comment 'Celestia RPC port'
        echo "✅ RPC enabled for external access and port opened"
    fi

    sudo systemctl restart celestia-appd
    echo "Service restarted"
}

toggle_grpc() {
    while true; do
        echo -e "\n╔══════════════════════════════╗"
        echo "║         Toggle gRPC          ║"
        echo "╚══════════════════════════════╝"

        check_node_installed || return 1
        source "$HOME/.bash_profile"
        CELESTIA_PORT=${CELESTIA_PORT:-"40"}

        # Get values using awk for more reliable parsing
        local grpc_enabled=$(awk '/^\[grpc\]/{f=1;next}/^\[/{f=0}f&&/^enable =/{print $3}' "$CELESTIA_HOME/config/app.toml")
        local grpc_address=$(awk '/^\[grpc\]/{f=1;next}/^\[/{f=0}f&&/^address =/{gsub(/"/, "");print $3}' "$CELESTIA_HOME/config/app.toml")
        local grpc_web_enabled=$(awk '/^\[grpc-web\]/{f=1;next}/^\[/{f=0}f&&/^enable =/{print $3}' "$CELESTIA_HOME/config/app.toml")
        local grpc_web_address=$(awk '/^\[grpc-web\]/{f=1;next}/^\[/{f=0}f&&/^address =/{gsub(/"/, "");print $3}' "$CELESTIA_HOME/config/app.toml")

        echo "Current status:"
        echo "gRPC enabled: $grpc_enabled"
        echo "gRPC address: $grpc_address"
        echo "gRPC-web enabled: $grpc_web_enabled"
        echo "gRPC-web address: $grpc_web_address"
        echo ""
        echo "1. Toggle gRPC"
        echo "2. Toggle gRPC-web"
        echo "3. Toggle both"
        echo "0. Back"
        read -rp "Choose an option [0-3]: " subchoice

        case $subchoice in
            1)
                if [ "$grpc_enabled" = "true" ] && [[ "$grpc_address" == *"0.0.0.0"* ]]; then
                    echo "Disabling gRPC..."
                    sed -i '/^\[grpc\]/,/^\[/s/^enable = .*/enable = false/' "$CELESTIA_HOME/config/app.toml"
                    sed -i '/^\[grpc\]/,/^\[/s|^address = .*|address = "127.0.0.1:'${CELESTIA_PORT}'090"|' "$CELESTIA_HOME/config/app.toml"
                    sudo ufw delete allow "${CELESTIA_PORT}090" 2>/dev/null || true
                    echo "✅ gRPC disabled and port closed"
                else
                    echo "Enabling gRPC..."
                    sed -i '/^\[grpc\]/,/^\[/s/^enable = .*/enable = true/' "$CELESTIA_HOME/config/app.toml"
                    sed -i '/^\[grpc\]/,/^\[/s|^address = .*|address = "0.0.0.0:'${CELESTIA_PORT}'090"|' "$CELESTIA_HOME/config/app.toml"
                    sudo ufw allow "${CELESTIA_PORT}090" comment 'Celestia gRPC port'
                    echo "✅ gRPC enabled and port opened"
                fi
                sudo systemctl restart celestia-appd
                echo "Service restarted"
                ;;
            2)
                if [ "$grpc_web_enabled" = "true" ] && [[ "$grpc_web_address" == *"0.0.0.0"* ]]; then
                    echo "Disabling gRPC-web..."
                    sed -i '/^\[grpc-web\]/,/^\[/s/^enable = .*/enable = false/' "$CELESTIA_HOME/config/app.toml"
                    sed -i '/^\[grpc-web\]/,/^\[/s|^address = .*|address = "127.0.0.1:'${CELESTIA_PORT}'091"|' "$CELESTIA_HOME/config/app.toml"
                    sudo ufw delete allow "${CELESTIA_PORT}091" 2>/dev/null || true
                    echo "✅ gRPC-web disabled and port closed"
                else
                    echo "Enabling gRPC-web..."
                    sed -i '/^\[grpc-web\]/,/^\[/s/^enable = .*/enable = true/' "$CELESTIA_HOME/config/app.toml"
                    sed -i '/^\[grpc-web\]/,/^\[/s|^address = .*|address = "0.0.0.0:'${CELESTIA_PORT}'091"|' "$CELESTIA_HOME/config/app.toml"
                    sudo ufw allow "${CELESTIA_PORT}091" comment 'Celestia gRPC-web port'
                    echo "✅ gRPC-web enabled and port opened"
                fi
                sudo systemctl restart celestia-appd
                echo "Service restarted"
                ;;
            3)
                # Handle gRPC
                if [ "$grpc_enabled" = "true" ] && [[ "$grpc_address" == *"0.0.0.0"* ]]; then
                    echo "Disabling gRPC..."
                    sed -i '/^\[grpc\]/,/^\[/s/^enable = .*/enable = false/' "$CELESTIA_HOME/config/app.toml"
                    sed -i '/^\[grpc\]/,/^\[/s|^address = .*|address = "127.0.0.1:'${CELESTIA_PORT}'090"|' "$CELESTIA_HOME/config/app.toml"
                    sudo ufw delete allow "${CELESTIA_PORT}090" 2>/dev/null || true
                    echo "✅ gRPC disabled and port closed"
                else
                    echo "Enabling gRPC..."
                    sed -i '/^\[grpc\]/,/^\[/s/^enable = .*/enable = true/' "$CELESTIA_HOME/config/app.toml"
                    sed -i '/^\[grpc\]/,/^\[/s|^address = .*|address = "0.0.0.0:'${CELESTIA_PORT}'090"|' "$CELESTIA_HOME/config/app.toml"
                    sudo ufw allow "${CELESTIA_PORT}090" comment 'Celestia gRPC port'
                    echo "✅ gRPC enabled and port opened"
                fi

                # Handle gRPC-web
                if [ "$grpc_web_enabled" = "true" ] && [[ "$grpc_web_address" == *"0.0.0.0"* ]]; then
                    echo "Disabling gRPC-web..."
                    sed -i '/^\[grpc-web\]/,/^\[/s/^enable = .*/enable = false/' "$CELESTIA_HOME/config/app.toml"
                    sed -i '/^\[grpc-web\]/,/^\[/s|^address = .*|address = "127.0.0.1:'${CELESTIA_PORT}'091"|' "$CELESTIA_HOME/config/app.toml"
                    sudo ufw delete allow "${CELESTIA_PORT}091" 2>/dev/null || true
                    echo "✅ gRPC-web disabled and port closed"
                else
                    echo "Enabling gRPC-web..."
                    sed -i '/^\[grpc-web\]/,/^\[/s/^enable = .*/enable = true/' "$CELESTIA_HOME/config/app.toml"
                    sed -i '/^\[grpc-web\]/,/^\[/s|^address = .*|address = "0.0.0.0:'${CELESTIA_PORT}'091"|' "$CELESTIA_HOME/config/app.toml"
                    sudo ufw allow "${CELESTIA_PORT}091" comment 'Celestia gRPC-web port'
                    echo "✅ gRPC-web enabled and port opened"
                fi
                sudo systemctl restart celestia-appd
                echo "Service restarted"
                ;;
            0) return ;;
            *) echo "Invalid option" ;;
        esac
    done
}

toggle_api() {
    while true; do
        echo -e "\n╔══════════════════════════════╗"
        echo "║         Toggle API           ║"
        echo "╚══════════════════════════════╝"

        check_node_installed || return 1
        source "$HOME/.bash_profile"
        CELESTIA_PORT=${CELESTIA_PORT:-"40"}
        local config_file="$CELESTIA_HOME/config/app.toml"

        # Get values using awk for more reliable parsing
        local api_enabled=$(awk '/^\[api\]/{f=1;next}/^\[/{f=0}f&&/^enable =/{print $3}' "$config_file")
        local api_address=$(awk '/^\[api\]/{f=1;next}/^\[/{f=0}f&&/^address =/{gsub(/"/, "");print $3}' "$config_file")
        local swagger_enabled=$(awk '/^\[api\]/{f=1;next}/^\[/{f=0}f&&/^swagger =/{print $3}' "$config_file")

        echo "Current status:"
        echo "API enabled: $api_enabled"
        echo "API address: $api_address"
        echo "Swagger enabled: $swagger_enabled"
        echo ""
        echo "1. Toggle API"
        echo "2. Toggle Swagger"
        echo "3. Toggle both"
        echo "0. Back"
        read -rp "Choose an option [0-3]: " choice

        case $choice in
            1)
                if [ "$api_enabled" = "true" ] && [[ "$api_address" == *"0.0.0.0"* ]]; then
                    echo "Disabling API..."
                    sed -i '/^\[api\]/,/^\[/s/^enable = .*/enable = false/' "$config_file"
                    sed -i '/^\[api\]/,/^\[/s|^address = .*|address = "tcp://127.0.0.1:'${CELESTIA_PORT}'317"|' "$config_file"
                    sudo ufw delete allow "${CELESTIA_PORT}317" 2>/dev/null || true
                    echo "✅ API disabled and port closed"
                else
                    echo "Enabling API..."
                    sed -i '/^\[api\]/,/^\[/s/^enable = .*/enable = true/' "$config_file"
                    sed -i '/^\[api\]/,/^\[/s|^address = .*|address = "tcp://0.0.0.0:'${CELESTIA_PORT}'317"|' "$config_file"
                    sudo ufw allow "${CELESTIA_PORT}317" comment 'Celestia API port'
                    echo "✅ API enabled and port opened"
                fi
                sudo systemctl restart celestia-appd
                echo "Service restarted"
                ;;
            2)
                if [ "$swagger_enabled" = "true" ]; then
                    echo "Disabling Swagger..."
                    sed -i '/^\[api\]/,/^\[/s/^swagger = .*/swagger = false/' "$config_file"
                    echo "✅ Swagger disabled"
                else
                    echo "Enabling Swagger..."
                    sed -i '/^\[api\]/,/^\[/s/^swagger = .*/swagger = true/' "$config_file"
                    echo "✅ Swagger enabled"
                fi
                sudo systemctl restart celestia-appd
                echo "Service restarted"
                ;;
            3)
                # Handle API
                if [ "$api_enabled" = "true" ] && [[ "$api_address" == *"0.0.0.0"* ]]; then
                    echo "Disabling API..."
                    sed -i '/^\[api\]/,/^\[/s/^enable = .*/enable = false/' "$config_file"
                    sed -i '/^\[api\]/,/^\[/s|^address = .*|address = "tcp://127.0.0.1:'${CELESTIA_PORT}'317"|' "$config_file"
                    sudo ufw delete allow "${CELESTIA_PORT}317" 2>/dev/null || true
                    echo "✅ API disabled and port closed"
                else
                    echo "Enabling API..."
                    sed -i '/^\[api\]/,/^\[/s/^enable = .*/enable = true/' "$config_file"
                    sed -i '/^\[api\]/,/^\[/s|^address = .*|address = "tcp://0.0.0.0:'${CELESTIA_PORT}'317"|' "$config_file"
                    sudo ufw allow "${CELESTIA_PORT}317" comment 'Celestia API port'
                    echo "✅ API enabled and port opened"
                fi

                # Handle Swagger
                if [ "$swagger_enabled" = "true" ]; then
                    echo "Disabling Swagger..."
                    sed -i '/^\[api\]/,/^\[/s/^swagger = .*/swagger = false/' "$config_file"
                    echo "✅ Swagger disabled"
                else
                    echo "Enabling Swagger..."
                    sed -i '/^\[api\]/,/^\[/s/^swagger = .*/swagger = true/' "$config_file"
                    echo "✅ Swagger enabled"
                fi
                sudo systemctl restart celestia-appd
                echo "Service restarted"
                ;;
            0) return ;;
            *) echo "Invalid option" ;;
        esac
    done
}

show_node_peer() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║         Node Peer            ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1

    NODE_ID=$(celestia-appd tendermint show-node-id)
    IP=$(wget -qO- eth0.me)
    PORT=$(grep -A1 "Address to listen for incoming connection" "$CELESTIA_HOME/config/config.toml" | tail -1 | cut -d':' -f2 | tr -d '"')

    if [ -z "$NODE_ID" ] || [ -z "$IP" ] || [ -z "$PORT" ]; then
        echo "❌ Error getting node information"
        return 1
    fi

    echo "✅ Your node peer: ${NODE_ID}@${IP}:${PORT}"
}

delete_node() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║      Delete Celestia Node    ║"
    echo "╚══════════════════════════════╝"

    echo -e "\n⚠️  WARNING! This will completely remove your Celestia node!"
    echo "This includes:"
    echo "  - Celestia service and binary"
    echo "  - Node data directory and configuration"
    echo "  - Environment variables"
    echo -e "\nMake sure you have backed up important files if needed!"

    read -rp "Are you sure you want to proceed? (y/N): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo "Node deletion cancelled."
        return 0
    fi

    echo -e "\n🗑️  Removing Celestia node..."

    # Stop and disable service
    echo "Stopping Celestia service..."
    if systemctl is-active --quiet celestia-appd; then
        sudo systemctl stop celestia-appd 2>/dev/null || true
        sudo systemctl disable celestia-appd 2>/dev/null || true
        echo "Service stopped and disabled"
    else
        echo "Note: Service was not running"
    fi

    # Remove service file
    echo "Removing service file..."
    if [ -f "/etc/systemd/system/celestia-appd.service" ]; then
        sudo rm -f /etc/systemd/system/celestia-appd.service || true
        echo "Service file removed"
    else
        echo "Note: Service file not found"
    fi

    # Remove binary
    echo "Removing Celestia binary..."
    BINARY_PATH=$(which celestia-appd 2>/dev/null || true)
    if [ -n "$BINARY_PATH" ]; then
        sudo rm -f "$BINARY_PATH" 2>/dev/null || true
        echo "Binary removed: $BINARY_PATH"
    else
        echo "Note: Binary not found"
    fi

    # Remove data directory
    echo "Removing data directory..."
    if [ -d "$CELESTIA_HOME" ]; then
        sudo rm -rf "$CELESTIA_HOME" 2>/dev/null || true
        echo "Data directory removed"
    else
        echo "Note: Data directory not found"
    fi

    # Remove environment variables
    echo "Removing environment variables..."
    if [ -f "$HOME/.bash_profile" ] && grep -q "CELESTIA_" "$HOME/.bash_profile"; then
        sed -i '/CELESTIA_/d' "$HOME/.bash_profile" 2>/dev/null || true
        echo "Environment variables removed"
    else
        echo "Note: No environment variables found"
    fi

    # Reload systemd
    sudo systemctl daemon-reload 2>/dev/null || true

    echo -e "\n✅ Celestia node removal process completed!"
    echo "You may need to restart your terminal for all changes to take effect."
    exit 0
}

###################
# Validator Operation Functions
###################

check_balance() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║         Check Balance        ║"
    echo "╚══════════════════════════════╝"

    source "$HOME/.bash_profile"
    WALLET_ADDRESS=$(celestia-appd keys show "$WALLET" -a)
    celestia-appd q bank balances "$WALLET_ADDRESS"
}

create_wallet() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║       Create Wallet          ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    source "$HOME/.bash_profile"

    if [ -z "$WALLET" ]; then
        echo "WALLET variable not set. Please run set_environment_variables first."
        return 1
    fi

    # Check if wallet already exists
    if celestia-appd keys show "$WALLET" &>/dev/null; then
        echo "⚠️  Wallet '$WALLET' already exists!"
        read -rp "Do you want to create a new wallet with a different name? (y/N): " choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            return 0
        fi
        read -rp "Enter new wallet name: " WALLET
        # Update WALLET in .bash_profile
        sed -i "/^export WALLET=/c\export WALLET=\"$WALLET\"" "$HOME/.bash_profile"
        source "$HOME/.bash_profile"
    fi

    echo -e "\n⚠️  IMPORTANT: Please save the mnemonic phrase that will be shown below!"
    echo "It's your only backup if you lose access to your wallet."
    read -rp "Press Enter when you're ready..."

    # Create new wallet
    celestia-appd keys add "$WALLET"

    # Save wallet and validator addresses
    WALLET_ADDRESS=$(celestia-appd keys show "$WALLET" -a)
    VALOPER_ADDRESS=$(celestia-appd keys show "$WALLET" --bech val -a)

    # Update or add addresses to .bash_profile
    if grep -q "WALLET_ADDRESS=" "$HOME/.bash_profile"; then
        sed -i "/^export WALLET_ADDRESS=/c\export WALLET_ADDRESS=$WALLET_ADDRESS" "$HOME/.bash_profile"
    else
        echo "export WALLET_ADDRESS=$WALLET_ADDRESS" >> "$HOME/.bash_profile"
    fi

    if grep -q "VALOPER_ADDRESS=" "$HOME/.bash_profile"; then
        sed -i "/^export VALOPER_ADDRESS=/c\export VALOPER_ADDRESS=$VALOPER_ADDRESS" "$HOME/.bash_profile"
    else
        echo "export VALOPER_ADDRESS=$VALOPER_ADDRESS" >> "$HOME/.bash_profile"
    fi

    source "$HOME/.bash_profile"

    echo -e "\n✅ Wallet created successfully!"
    echo "Wallet Address: $WALLET_ADDRESS"
    echo "Validator Address: $VALOPER_ADDRESS"
    echo -e "\n⚠️  Remember to fund this wallet before creating a validator!"
}

# Update the validator_operations_menu function to include the new option
validator_operations_menu() {
    while true; do
        echo -e "\n╔══════════════════════════════╗"
        echo "║  Validator Operations Menu   ║"
        echo "╚══════════════════════════════╝"
        echo "  1.  Create Wallet"
        echo "  2.  View Validator Details"
        echo "  3.  Check Balance"
        echo "  4.  Create Validator"
        echo "  5.  Show Slashing Parameters"
        echo "  6.  Show Jailing Info"
        echo "  7.  Unjail Validator"
        echo "  8.  Delegate Tokens"
        echo "  9.  Unbond Tokens"
        echo " 10.  Check Validator Key"
        echo " 11.  Show Signing Info"
        echo "  0.  Back to Main Menu"
        echo ""
        read -rp "Enter your choice [0-11]: " subchoice

        case $subchoice in
            1) create_wallet ;;
            2) view_validator_details ;;
            3) check_balance ;;
            4) create_validator ;;
            5) show_slashing_params ;;
            6) show_jailing_info ;;
            7) unjail_validator ;;
            8) delegate_tokens ;;
            9) unstake_tokens ;;
            10) check_validator_key ;;
            11) show_signing_info ;;
            0) break ;;
            *) echo "Invalid option. Please enter a number between 0 and 11." ;;
        esac
    done
}

create_validator() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║    Create Validator Setup    ║"
    echo "╚══════════════════════════════╝"

    # Source environment variables
    source "$HOME/.bash_profile"

    # Check if environment variables are set
    if [ -z "${WALLET:-}" ] || [ -z "${MONIKER:-}" ]; then
        echo "Error: Required environment variables are not set!"
        echo "Please run set_environment_variables first."
        return 1
    fi

    # Check if wallet exists
    if ! celestia-appd keys show "$WALLET" >/dev/null 2>&1; then
        echo "Error: Wallet $WALLET not found!"
        return 1
    fi

    # Prompt for validator details with defaults
    read -rp "Enter validator moniker (default: $MONIKER): " val_moniker
    read -rp "Enter keybase.io identity (optional, press enter to skip): " val_identity
    read -rp "Enter website (optional, press enter to skip): " val_website
    read -rp "Enter details/description (optional, press enter to skip): " val_details
    read -rp "Enter amount in utia (default: 1000000): " val_amount
    read -rp "Enter commission rate (default: 0.1): " val_commission_rate
    read -rp "Enter maximum commission rate (default: 0.2): " val_commission_max_rate
    read -rp "Enter maximum commission change rate (default: 0.01): " val_commission_max_change_rate

    # Set defaults if values are empty
    val_moniker=${val_moniker:-$MONIKER}
    val_identity=${val_identity:-""}
    val_website=${val_website:-""}
    val_details=${val_details:-""}
    val_amount=${val_amount:-"1000000"}
    val_commission_rate=${val_commission_rate:-"0.1"}
    val_commission_max_rate=${val_commission_max_rate:-"0.2"}
    val_commission_max_change_rate=${val_commission_max_change_rate:-"0.01"}

    echo -e "\nValidator Configuration Summary:"
    echo "--------------------------------"
    echo "Moniker: $val_moniker"
    echo "Identity: $val_identity"
    echo "Website: $val_website"
    echo "Details: $val_details"
    echo "Amount: ${val_amount}utia"
    echo "Commission Rate: $val_commission_rate"
    echo "Commission Max Rate: $val_commission_max_rate"
    echo "Commission Max Change Rate: $val_commission_max_change_rate"
    echo "--------------------------------"

    read -rp "Do you want to proceed with validator creation? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Validator creation cancelled."
        return 0
    fi

    echo "Creating validator..."
    celestia-appd tx staking create-validator \
    --amount "${val_amount}utia" \
    --from "$WALLET" \
    --commission-rate "$val_commission_rate" \
    --commission-max-rate "$val_commission_max_rate" \
    --commission-max-change-rate "$val_commission_max_change_rate" \
    --min-self-delegation 1 \
    --pubkey "$(celestia-appd tendermint show-validator)" \
    --moniker "$val_moniker" \
    --identity "$val_identity" \
    --website "$val_website" \
    --details "$val_details" \
    --chain-id "$DEFAULT_CHAIN_ID" \
    --gas 300000 \
    --fees 2000utia \
    -y

    if [ $? -eq 0 ]; then
        echo "Validator created successfully!"
    else
        echo "Error creating validator. Please check the error message above."
    fi
}

show_slashing_params() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║    Slashing Parameters      ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    celestia-appd q slashing params || echo "❌ Error: Failed to get slashing parameters"
}

show_jailing_info() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║       Jailing Info           ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    celestia-appd q slashing signing-info $(celestia-appd tendermint show-validator) || {
        echo "❌ Error: Failed to get jailing info"
        return 1
    }
}

unjail_validator() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║     Unjail Validator        ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    source "$HOME/.bash_profile"

    if [ -z "$WALLET" ]; then
        echo "❌ Error: WALLET variable not set"
        return 1
    fi

    celestia-appd tx slashing unjail --from "$WALLET" --chain-id "$DEFAULT_CHAIN_ID" --gas 300000 --fees 2000utia -y || {
        echo "❌ Error: Failed to unjail validator"
        return 1
    }
}

delegate_tokens() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║       Delegate Tokens        ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    source "$HOME/.bash_profile"

    if [ -z "$WALLET" ]; then
        echo "❌ Error: WALLET variable not set"
        return 1
    fi

    read -rp "Enter validator address to delegate to (leave empty for self-delegation): " validator_address
    read -rp "Enter amount in utia (default: 1000000): " amount

    amount=${amount:-1000000}

    if [ -z "$validator_address" ]; then
        validator_address=$(celestia-appd keys show "$WALLET" --bech val -a) || {
            echo "❌ Error: Failed to get validator address"
            return 1
        }
        echo "Self-delegating ${amount}utia..."
    else
        echo "Delegating ${amount}utia to $validator_address..."
    fi

    celestia-appd tx staking delegate "$validator_address" "${amount}utia" \
        --from "$WALLET" \
        --chain-id "$DEFAULT_CHAIN_ID" \
        --gas 300000 \
        --fees 2000utia \
        -y || {
        echo "❌ Error: Failed to delegate tokens"
        return 1
    }
}

unstake_tokens() {
    echo -e "\n╔═════════════════════════════╗"
    echo "║       Unbond Tokens         ║"
    echo "╚═════════════════════════════╝"

    check_node_installed || return 1
    source "$HOME/.bash_profile"

    if [ -z "$WALLET" ]; then
        echo "❌ Error: WALLET variable not set"
        return 1
    fi

    read -rp "Enter amount in utia (default: 1000000): " amount
    amount=${amount:-1000000}

    validator_address=$(celestia-appd keys show "$WALLET" --bech val -a) || {
        echo "❌ Error: Failed to get validator address"
        return 1
    }

    echo "Unbonding ${amount}utia..."
    celestia-appd tx staking unbond "$validator_address" "${amount}utia" \
        --from "$WALLET" \
        --chain-id "$DEFAULT_CHAIN_ID" \
        --gas 300000 \
        --fees 2000utia \
        -y || {
        echo "❌ Error: Failed to unbond tokens"
        return 1
    }
}

view_validator_details() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║     Validator Details        ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    source "$HOME/.bash_profile"

    if [ -z "$WALLET" ]; then
        echo "❌ Error: WALLET variable not set"
        return 1
    fi

    celestia-appd q staking validator $(celestia-appd keys show "$WALLET" --bech val -a) || {
        echo "❌ Error: Failed to get validator details"
        return 1
    }
}

check_validator_key() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║    Validator Key Status      ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    source "$HOME/.bash_profile"

    # Get validator address
    VALOPER_ADDRESS=$(celestia-appd keys show "$WALLET" --bech val -a)
    if [ -z "$VALOPER_ADDRESS" ]; then
        echo "❌ Error: Could not get validator address"
        return 1
    fi

    # Check key match
    [[ $(celestia-appd q staking validator "$VALOPER_ADDRESS" -oj | jq -r .consensus_pubkey.key) = \
        $(celestia-appd status | jq -r .ValidatorInfo.PubKey.value) ]] && \
        echo -e "✅ Your key status is ok" || echo -e "❌ Your key status is error"
}

show_signing_info() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║       Signing Info          ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1
    celestia-appd q slashing signing-info $(celestia-appd tendermint show-validator) || {
        echo "❌ Error: Failed to get signing info"
        return 1
    }
}

###################
# Bridge Management Functions
###################

check_bridge_installed() {
    if ! command -v celestia &> /dev/null; then
        echo "❌ Error: celestia bridge is not installed!"
        return 1
    fi
    return 0
}

check_bridge_status() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║     Bridge Node Status       ║"
    echo "╚══════════════════════════════╝"

    check_bridge_installed || return 1
    celestia header sync-state --node.store ~/.celestia-bridge/
}

check_bridge_wallet() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║    Bridge Wallet Balance     ║"
    echo "╚══════════════════════════════╝"

    check_bridge_installed || return 1
    celestia state balance --node.store ~/.celestia-bridge/
}

get_node_id() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║         Node ID              ║"
    echo "╚══════════════════════════════╝"

    check_bridge_installed || return 1
    celestia p2p info --node.store ~/.celestia-bridge/
}

update_bridge_node() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║    Update Bridge Node        ║"
    echo "╚══════════════════════════════╝"

    check_bridge_installed || return 1

    echo "Stopping bridge node..."
    sudo systemctl stop celestia-bridge

    cd "$HOME"
    rm -rf celestia-node
    git clone https://github.com/celestiaorg/celestia-node.git
    cd celestia-node/
    git checkout tags/v0.21.5
    make build
    sudo make install
    make cel-key

    echo "Updating bridge configuration..."
    celestia bridge config-update

    echo "Starting bridge node..."
    sudo systemctl restart celestia-bridge

    echo -e "\n✅ Bridge node updated successfully"
    echo "Showing logs (press Ctrl+C to exit)..."
    sudo journalctl -u celestia-bridge -fo cat
}

delete_bridge_node() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║    Delete Bridge Node        ║"
    echo "╚══════════════════════════════╝"

    check_bridge_installed || return 1

    echo "Stopping and disabling bridge service..."
    sudo systemctl stop celestia-bridge
    sudo systemctl disable celestia-bridge

    echo "Removing service files..."
    sudo rm /etc/systemd/system/celestia-bridge*

    echo "Removing bridge node files..."
    rm -rf $HOME/celestia-node $HOME/.celestia-bridge

    echo -e "\n✅ Bridge node deleted successfully"
}

reset_bridge_node() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║     Reset Bridge Node        ║"
    echo "╚══════════════════════════════╝"

    check_bridge_installed || return 1

    echo "Resetting bridge node store..."
    celestia bridge unsafe-reset-store

    echo -e "\n✅ Bridge node store reset successfully"
}

get_wallet_address() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║     Bridge Wallet Info       ║"
    echo "╚══════════════════════════════╝"

    check_bridge_installed || return 1

    cd "$HOME/celestia-node"
    if [ -f "./cel-key" ]; then
        ./cel-key list --node.type bridge --keyring-backend os
    else
        echo "❌ Error: cel-key not found. Please ensure bridge node is properly installed."
        return 1
    fi
}

###################
# Status & Logs Functions
###################

view_logs() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║         View Logs            ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1

    echo "Showing live logs (press Ctrl+C to exit)..."
    sudo journalctl -u celestia-appd -fo cat
}

check_sync_status() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║       Sync Status            ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1

    # Get RPC port from config
    rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$CELESTIA_HOME/config/config.toml" | cut -d ':' -f 3)
    if [ -z "$rpc_port" ]; then
        echo "❌ Error: Could not determine RPC port"
        return 1
    fi

    echo "Checking sync status (press Ctrl+C to exit)..."
    echo ""

    while true; do
        local_height=$(curl -s localhost:$rpc_port/status | jq -r '.result.sync_info.latest_block_height')
        network_height=$(curl -s $RPC_URL/status | jq -r '.result.sync_info.latest_block_height')

        if ! [[ "$local_height" =~ ^[0-9]+$ ]] || ! [[ "$network_height" =~ ^[0-9]+$ ]]; then
            echo -e "\033[1;31mError: Invalid block height data. Retrying...\033[0m"
            sleep 5
            continue
        fi

        blocks_left=$((network_height - local_height))
        if [ "$blocks_left" -lt 0 ]; then
            blocks_left=0
        fi

        echo -e "\033[1;33mNode Height:\033[1;34m $local_height\033[0m \033[1;33m| Network Height:\033[1;36m $network_height\033[0m \033[1;33m| Blocks Left:\033[1;31m $blocks_left\033[0m"

        sleep 5
    done
}

check_service_status() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║      Service Status          ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1

    sudo systemctl status celestia-appd
}

###################
# Service Control Functions
###################

service_start() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║      Starting Service        ║"
    echo "╚══════════════════════════════╝"

    check_node_installed || return 1

    sudo systemctl start celestia-appd
    echo "Service started. Check status with: sudo systemctl status celestia-appd"
}

service_stop() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║      Stopping Service        ║"
    echo "╚══════════════════════════════╝"

    sudo systemctl stop celestia-appd
    echo "Service stopped. Check status with: sudo systemctl status celestia-appd"
}

service_restart() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║     Restarting Service       ║"
    echo "╚══════════════════════════════╝"

    sudo systemctl restart celestia-appd
    echo "Service restarted. Check status with: sudo systemctl status celestia-appd"
}

service_reload() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║     Reloading Services       ║"
    echo "╚══════════════════════════════╝"

    sudo systemctl daemon-reload
    echo "Services reloaded."
}

service_enable() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║      Enabling Service        ║"
    echo "╚══════════════════════════════╝"

    sudo systemctl enable celestia-appd
    echo "Service enabled. It will now start automatically on system boot."
}

service_disable() {
    echo -e "\n╔══════════════════════════════╗"
    echo "║      Disabling Service       ║"
    echo "╚══════════════════════════════╝"

    sudo systemctl disable celestia-appd
    echo "Service disabled. It will no longer start automatically on system boot."
}

###################
# Submenu Functions
###################

install_node_menu() {
    # Select network and directory
    select_network
    select_custom_directory
    
    while true; do
        echo -e "\n╔══════════════════════════════╗"
        echo "║      Install Node Menu       ║"
        echo "╚══════════════════════════════╝"
        echo -e "\n Consensus Node"
        echo "  1.  Pruned Node - Indexer Off"
        echo "  2.  Pruned Node - Indexer On"
        echo "  3.  Archive Node - Indexer Off"
        echo "  4.  Archive Node - Indexer On"
        echo -e "\n Bridge Node"
        echo "  5.  Bridge Node - Archive sync"
        echo "  6.  Bridge Node - Use Snapshot"
        echo ""
        echo "  0.  Back to Main Menu"
        echo ""
        read -rp "Enter your choice [0-6]: " choice

        case $choice in
            1)
                install_node_consensus "pruned" "off"
                if [ $? -eq 0 ]; then break; fi
                ;;
            2)
                install_node_consensus "pruned" "on"
                if [ $? -eq 0 ]; then break; fi
                ;;
            3)
                install_node_consensus "archive" "off"
                if [ $? -eq 0 ]; then break; fi
                ;;
            4)
                install_node_consensus "archive" "on"
                if [ $? -eq 0 ]; then break; fi
                ;;
            5)
                install_node_bridge "archive"
                if [ $? -eq 0 ]; then break; fi
                ;;
            6)
                install_node_bridge "snapshot"
                if [ $? -eq 0 ]; then break; fi
                ;;
            0) break ;;
            *) echo "Invalid option. Please enter a number between 0 and 7."  ;;
        esac
    done
}

node_operations_menu() {
    while true; do
        echo -e "\n╔══════════════════════════════╗"
        echo "║    Node Operations Menu      ║"
        echo "╚══════════════════════════════╝"
        echo "  1.  Node Info"
        echo "  2.  Install Cosmovisor"
        echo "  3.  Install Snapshot"
        echo "  4.  Update Node"
        echo "  5.  Configure Firewall Rules"
        echo "  6.  Toggle RPC"
        echo "  7.  Toggle gRPC"
        echo "  8.  Toggle API"
        echo "  9.  Show Node Peer"
        echo " 10.  Delete Node"
        echo "  0.  Back to Main Menu"
        echo ""
        read -rp "Enter your choice [0-10]: " subchoice

        case $subchoice in
            1) node_info ;;
            2) install_cosmovisor ;;
            3) install_snapshot ;;
            4) update_node ;;
            5) configure_firewall ;;
            6) toggle_rpc ;;
            7) toggle_grpc ;;
            8) toggle_api ;;
            9) show_node_peer ;;
            10) delete_node ;;
            0) break ;;
            *) echo "Invalid option. Please enter a number between 0 and 10." ;;
        esac
    done
}

validator_operations_menu() {
    while true; do
        echo -e "\n╔══════════════════════════════╗"
        echo "║  Validator Operations Menu   ║"
        echo "╚══════════════════════════════╝"
        echo "  1.  Check Balance"
        echo "  2.  View Validator Details"
        echo "  3.  Create Wallet"
        echo "  4.  Create Validator"
        echo "  5.  Show Slashing Parameters"
        echo "  6.  Show Jailing Info"
        echo "  7.  Unjail Validator"
        echo "  8.  Delegate Tokens"
        echo "  9.  Unbond Tokens"
        echo " 10.  Check Validator Key"
        echo " 11.  Show Signing Info"
        echo "  0.  Back to Main Menu"
        echo ""
        read -rp "Enter your choice [0-11]: " subchoice

        case $subchoice in
            1) check_balance ;;
            2) view_validator_details ;;
            3) create_wallet ;;
            4) create_validator ;;
            5) show_slashing_params ;;
            6) show_jailing_info ;;
            7) unjail_validator ;;
            8) delegate_tokens ;;
            9) unstake_tokens ;;
            10) check_validator_key ;;
            11) show_signing_info ;;
            0) break ;;
            *) echo "Invalid option. Please enter a number between 0 and 11." ;;
        esac
    done
}

bridge_management_menu() {
    while true; do
        echo -e "\n╔══════════════════════════════╗"
        echo "║    Bridge Management Menu    ║"
        echo "╚══════════════════════════════╝"
        echo "  1.  Check Bridge Node Status"
        echo "  2.  Check Bridge Wallet Balance"
        echo "  3.  Get Node ID"
        echo "  4.  Get Wallet Address"
        echo "  5.  Update Bridge Node"
        echo "  6.  Reset Bridge Node"
        echo "  7.  Delete Bridge Node"
        echo "  0.  Back to Main Menu"
        echo ""
        read -rp "Enter your choice [0-7]: " subchoice

        case $subchoice in
            1) check_bridge_status ;;
            2) check_bridge_wallet ;;
            3) get_node_id ;;
            4) get_wallet_address ;;
            5) update_bridge_node ;;
            6) reset_bridge_node ;;
            7) delete_bridge_node ;;
            0) break ;;
            *) echo "Invalid option. Please enter a number between 0 and 7." ;;
        esac
    done
}

service_operations_menu() {
    while true; do
        echo -e "\n╔══════════════════════════════╗"
        echo "║   Service Operations Menu    ║"
        echo "╚══════════════════════════════╝"
        echo "  1.  View Logs"
        echo "  2.  Check Service Status"
        echo "  3.  Start Service"
        echo "  4.  Stop Service"
        echo "  5.  Restart Service"
        echo "  6.  Reload Services"
        echo "  7.  Enable Service"
        echo "  8.  Disable Service"
        echo "  9.  Show Node Info"
        echo " 10.  Show Node Peer"
        echo "  0.  Back to Main Menu"
        echo ""
        read -rp "Enter your choice [0-10]: " subchoice

        case $subchoice in
            1) view_logs ;;
            2) check_service_status ;;
            3) service_start ;;
            4) service_stop ;;
            5) service_restart ;;
            6) service_reload ;;
            7) service_enable ;;
            8) service_disable ;;
            9) node_info ;;
            10) show_node_peer ;;
            0) break ;;
            *) echo "Invalid option. Please enter a number between 0 and 10." ;;
        esac
    done
}

status_logs_menu() {
    while true; do
        echo -e "\n╔══════════════════════════════╗"
        echo "║      Status & Logs Menu      ║"
        echo "╚══════════════════════════════╝"
        echo "  1.  View Logs"
        echo "  2.  Check Sync Status"
        echo "  3.  Check Service Status"
        echo "  4.  Check System Requirements"
        echo "  0.  Back to Main Menu"
        echo ""
        read -rp "Enter your choice [0-4]: " subchoice

        case $subchoice in
            1) view_logs ;;
            2) check_sync_status ;;
            3) check_service_status ;;
            4) check_system_requirements ;;
            0) break ;;
            *) echo "Invalid option. Please enter a number between 0 and 4." ;;
        esac
    done
}

###################
# Menu Functions
###################

show_main_menu() {
    echo -e "\n╔═══════════════════════════╗"
    echo "║  Celestia Node Manager    ║"
    echo "║  by PostHuman Validator   ║"
    echo "╚═══════════════════════════╝"
    echo "  1.  Install Node"
    echo "  2.  Update Node"
    echo "  3.  Node Operations"
    echo "  4.  Validator Operations"
    echo "  5.  Bridge Management"
    echo "  6.  Service Operations"
    echo "  7.  Status & Logs"
    echo "  0.  Exit"
    echo ""
    read -rp "Enter your choice [0-7]: " choice
}

# Initialize network configuration
configure_network

# Main menu loop
while true; do
    show_main_menu
    case $choice in
        1) install_node_menu ;;
        2) update_node ;; 
        3) node_operations_menu ;;
        4) validator_operations_menu ;;
        5) bridge_management_menu ;;
        6) service_operations_menu ;;
        7) status_logs_menu ;;
        0)
            echo "Thank you for using Celestia Node Manager by PostHuman Validator!"
            echo "Visit https://posthuman.digital"
            exit 0
            ;;
        *) echo "Invalid option. Please enter a number between 0 and 7."  ;;
    esac
done

# Reset terminal colors
tput sgr0
