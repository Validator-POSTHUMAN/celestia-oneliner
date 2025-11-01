# Celestia Node Manager by PostHuman Validator

Automated installation and management tool for Celestia mainnet nodes.

## 🚀 Quick Start

Download and run the interactive script:

```bash
curl -o celestia-manager.sh https://raw.githubusercontent.com/Validator-POSTHUMAN/celestia-oneliner/main/celestia-manager.sh && chmod +x celestia-manager.sh && ./celestia-manager.sh
```

**Network:** Celestia Mainnet  
**Chain ID:** celestia  
**Current Version:** v5.0.11  
**Go Version:** 1.24.1

---

## 📋 Features

### 1️⃣ Install Node (Full Setup)
Complete automated installation with options:
- ✅ **Pruned Node** (Indexer On/Off) - Recommended for validators
- ✅ **Archive Node** (Indexer On/Off) - Full history
- ✅ System requirements check
- ✅ Dependency installation (Go, build tools)
- ✅ Genesis & Addrbook from Posthuman snapshots
- ✅ Optimized configuration (pruning, gas price, peers)
- ✅ systemd service setup

### 2️⃣ Update Node ⭐
**Easy one-click update:**
- 📊 Shows current version
- 📦 Recommends latest stable version (v5.0.11)
- ✅ Press Enter to use recommended version
- 🛑 Graceful stop → Update → Restart
- ✅ Version verification
- 📜 Optional log viewing

**Typical update time:** 1-3 minutes

### 3️⃣ Node Operations
- 📊 **Node Info** - Status and configuration
- 🌐 **Your Node Peer** - Share your peer string
- 🔥 **Firewall Configuration** - Secure your server
- 🗑️ **Delete Node** - Complete removal

### 4️⃣ Validator Operations
- 💰 **Create Validator** - Initialize your validator
- 📊 **View Validator Info** - Status and voting power
- 💸 **Delegate Tokens** - Self-delegation
- 📤 **Unstake Tokens** - Unbond tokens
- 🏦 **Set Withdrawal Address** - Configure rewards
- 🔓 **Unjail Validator** - Restore jailed validator

### 5️⃣ Bridge Management
- 🌉 **Install Bridge Node** - Data availability bridge
- 💼 **Bridge Wallet** - Manage bridge wallet
- 🔄 **Update Bridge** - Update to latest version
- 🔃 **Reset Bridge** - Troubleshooting

### 6️⃣ Service Operations
- ▶️ **Start/Stop/Restart** - Service control
- 📜 **Check Logs** - Real-time monitoring
- 🔧 **Enable/Disable** - Auto-start configuration

### 7️⃣ Status & Logs
- 📊 Sync status monitoring
- 📜 Real-time log viewing
- 🔍 Service status check

---

## 💾 Snapshots

**Posthuman Snapshots** (recommended):
- 📍 URL: https://snapshots.posthuman.digital/celestia-mainnet/
- 📦 Pruned snapshot: ~5-6 GB
- ⏱️ Updated every 24 hours
- 🌐 Served via Cloudflare R2 (fast worldwide)
- ✅ Includes metadata: `snapshot.json`

**Benefits:**
- ⚡ Sync in minutes instead of days
- 💾 Save bandwidth and disk I/O
- ✅ Verified and maintained by PostHuman
- 🔄 Always up-to-date

**Manual snapshot restore:**
```bash
export CELESTIA_HOME="$HOME/.celestia-app"
export SERVICE_NAME="celestia-appd"

sudo systemctl stop "${SERVICE_NAME}"
cp "${CELESTIA_HOME}/data/priv_validator_state.json" "${CELESTIA_HOME}/priv_validator_state.json.backup"
rm -rf "${CELESTIA_HOME}/data"

curl -fL https://snapshots.posthuman.digital/celestia-mainnet/snapshot-latest.tar.zst | \
  tar -I zstd -xf - -C "${CELESTIA_HOME}"

mv "${CELESTIA_HOME}/priv_validator_state.json.backup" "${CELESTIA_HOME}/data/priv_validator_state.json"
sudo systemctl restart "${SERVICE_NAME}" && sudo journalctl -u "${SERVICE_NAME}" -f
```

---

## 📊 System Requirements

### Validator / Consensus Node (Official)
- **CPU**: 16 cores
- **RAM**: 32 GB
- **Disk**: 2 TiB NVMe SSD
- **Network**: 1 Gbps connection
- **OS**: Ubuntu 20.04+ or similar Linux

**Note**: These are official Celestia requirements for validator nodes. Non-validator full nodes may work with lower specs but are not recommended for production use.

### Archive Node
- **CPU**: 8+ cores
- **RAM**: 24 GB+
- **Disk**: 3 TB+ NVMe SSD
- **Network**: 1 Gbps connection

---

## 🔄 Update Guide

### When to Update?
- 🚨 Network upgrade announced
- 🐛 Critical bug fixes
- ✨ New features
- 📢 Monitor [Celestia Discord](https://discord.com/invite/celestiacommunity)

### Using the Script:
1. Run: `./celestia-manager.sh`
2. Select **"2. Update Node"**
3. Press Enter for recommended version (v5.0.11)
4. Confirm update
5. Wait 1-3 minutes
6. Done! ✅

### Manual Update:
```bash
sudo systemctl stop celestia-appd
cd ~/celestia-app
git fetch --all
git checkout tags/v5.0.11
make install
celestia-appd version
sudo systemctl restart celestia-appd
sudo journalctl -u celestia-appd -f
```

---

## 🔗 Resources

### PostHuman Services
- 🌐 **Website**: https://posthuman.digital
- 📊 **Explorer**: https://celestia-explorer.posthuman.digital
- 🔌 **RPC**: https://rpc-celestia-mainnet.posthuman.digital
- 🔌 **REST**: https://rest-celestia-mainnet.posthuman.digital
- 🔌 **gRPC**: https://grpc-celestia-mainnet.posthuman.digital
- 💾 **Snapshots**: https://snapshots.posthuman.digital/celestia-mainnet/
- 🌐 **Peer**: `2cc7330049bc02e4276668c414222593d52eb718@peer-celestia-mainnet.posthuman.digital:40656`

### Official Celestia
- 📚 **Docs**: https://docs.celestia.org
- 💬 **Discord**: https://discord.com/invite/celestiacommunity
- 🐦 **Twitter**: https://twitter.com/CelestiaOrg
- 💻 **GitHub**: https://github.com/celestiaorg/celestia-app

---

## 🛡️ Security

- 🔐 **Backup Keys**: Always backup `~/.celestia-app/config/priv_validator_key.json`
- 🔥 **Firewall**: Use the script's firewall configuration
- 🔑 **SSH**: Use key-based authentication
- 👁️ **Monitoring**: Setup alerts for downtime
- 💰 **Never share**: Private keys or seed phrases

---

## 🐛 Troubleshooting

### Node not syncing?
```bash
# Check logs
sudo journalctl -u celestia-appd -f -n 100

# Check sync status
celestia-appd status 2>&1 | jq .SyncInfo
```

### REST API not working?
- Known issue in v5.x
- Use gRPC instead: `grpcurl -plaintext localhost:9090 list`
- See [troubleshooting guide](https://github.com/Validator-POSTHUMAN/celestia-oneliner/issues)

### Service won't start?
```bash
# Check service status
sudo systemctl status celestia-appd

# View recent logs
sudo journalctl -u celestia-appd -n 50 --no-pager
```

---

## 📝 License

MIT License - provided by [PostHuman Validator](https://posthuman.digital)

**Support:**
- GitHub Issues: [celestia-oneliner repository](https://github.com/Validator-POSTHUMAN/celestia-oneliner)
- Discord: PostHuman community

---

**Version:** v5.0.11 | **Chain ID:** celestia | **Last Updated:** 2025-01-11

## 🆕 New Features

### Network Selection
The script now supports both **Mainnet** and **Testnet** (Mocha-4):

```bash
# Set network before running script
export NETWORK_TYPE=testnet  # or mainnet (default)
./celestia-manager.sh
```

Or select interactively when installing a node.

**Mainnet** (celestia):
- Version: v5.0.11
- Chain ID: celestia
- Snapshots: snapshots.posthuman.digital/celestia-mainnet/

**Testnet** (mocha-4):
- Version: v6.2.0-mocha
- Chain ID: mocha-4
- Snapshots: snapshots.posthuman.digital/celestia-testnet/

### Custom Installation Directory
Install to a custom directory (e.g., separate disk):

```bash
# Set custom directory before running
export CELESTIA_HOME=/mnt/nvme/.celestia-app
./celestia-manager.sh
```

Or select interactively during installation.

**Use cases:**
- Install on a larger/faster disk
- Multiple nodes on same server
- Custom backup/mount points

### Delete Node
Safely remove your Celestia node:
- Stops and disables service
- Removes binary and service files
- Optionally removes data directory
- Cleans environment variables

Access via: **Node Operations Menu → Option 10**

