# Celestia Node Manager by PostHuman Validator

One-line automated installation and management tool for Celestia nodes (Mainnet & Testnet).

## 🚀 One-Liner Install & Run

```bash
curl -sL https://raw.githubusercontent.com/Validator-POSTHUMAN/celestia-oneliner/main/celestia-manager.sh > celestia-manager.sh && chmod +x celestia-manager.sh && ./celestia-manager.sh
```

**Current Versions:**
- 🌐 Mainnet: `v5.0.11` (chain-id: `celestia`)
- 🧪 Testnet: `v6.2.0-mocha` (chain-id: `mocha-4`)
- 🔧 Go: `1.24.1`

---

## 📋 Features

### 1️⃣ Install Node
**Consensus Nodes:**
- Pruned Node (Indexer On/Off)
- Archive Node (Indexer On/Off)

**Installation includes:**
- Automatic dependency installation
- Network selection (Mainnet/Testnet)
- Custom directory support
- Snapshot integration
- Systemd service setup

### 2️⃣ Update Node
One-click update with version selection and verification.

### 3️⃣ Node Operations
- Node info & configuration
- Snapshot installation
- Firewall configuration
- RPC/gRPC/API toggle
- Delete node

### 4️⃣ Validator Operations
- Create wallet & validator
- Check balance & validator info
- Delegate/Unbond tokens
- Unjail validator
- Set withdrawal address

### 5️⃣ Data Availability Nodes
**Install & Manage:**
- 🌉 **Bridge Node** - DA layer bridge (requires Core RPC + TIA)
- 💾 **Full Storage Node** - Complete data storage (requires Core RPC)
- 💡 **Light Node** - Lightweight verification (no RPC needed)

**Operations:**
- Check status & balance
- Get Node ID & wallet
- Update, reset, delete
- View logs

### 6️⃣ Service Operations
Start/Stop/Restart/Enable/Disable services and view logs.

### 7️⃣ Status & Logs
Real-time sync status, logs, and system checks.

---

## 💾 Snapshots

**PostHuman Snapshots:**
- 📍 https://snapshots.posthuman.digital/celestia-mainnet/
- 📍 https://snapshots.posthuman.digital/celestia-testnet/
- ⏱️ Updated every 24 hours
- 🌐 Fast worldwide delivery via Cloudflare R2

**Manual snapshot restore:**
```bash
export CELESTIA_HOME="$HOME/.celestia-app"
sudo systemctl stop celestia-appd
cp "${CELESTIA_HOME}/data/priv_validator_state.json" "${CELESTIA_HOME}/priv_validator_state.json.backup"
rm -rf "${CELESTIA_HOME}/data"
curl -L https://snapshots.posthuman.digital/celestia-mainnet/snapshot-latest.tar.zst | tar -I zstd -xf - -C "${CELESTIA_HOME}"
mv "${CELESTIA_HOME}/priv_validator_state.json.backup" "${CELESTIA_HOME}/data/priv_validator_state.json"
sudo systemctl restart celestia-appd && sudo journalctl -u celestia-appd -f
```

---

## 📊 System Requirements

| Node Type | CPU | RAM | Disk | Network |
|-----------|-----|-----|------|---------|
| **Validator** | 16 cores | 32 GB | 2 TB NVMe | 1 Gbps |
| **Archive** | 8+ cores | 24 GB | 3+ TB NVMe | 1 Gbps |
| **Bridge** | 4+ cores | 8 GB | 500+ GB SSD | 100 Mbps |
| **Full Storage** | 4+ cores | 8 GB | 500+ GB SSD | 100 Mbps |
| **Light** | 2+ cores | 2 GB | 50+ GB SSD | 25 Mbps |

---

## 🔗 PostHuman Services

### Mainnet (celestia)
- 🌐 **Website**: https://posthuman.digital
- 📊 **Explorer**: https://explorer.posthuman.digital/celestia
- 🔌 **RPC**: https://celestia-rpc.posthuman.digital
- 🔌 **API**: https://celestia-api.posthuman.digital
- 🔌 **gRPC**: celestia-grpc.posthuman.digital:443
- 💾 **Snapshots**: https://snapshots.posthuman.digital/celestia-mainnet/
- 🌐 **Peer**: `2cc7330049bc02e4276668c414222593d52eb718@celestia-peer.posthuman.digital:26656`
- 🌐 **Addrbook**: https://snapshots.posthuman.digital/celestia-mainnet/addrbook.json

### Testnet (mocha-4)
- 📊 **Explorer**: https://explorer.posthuman.digital/celestia-testnet
- 🔌 **RPC**: https://celestia-testnet-rpc.posthuman.digital
- 🔌 **API**: https://celestia-testnet-api.posthuman.digital
- 🔌 **gRPC**: celestia-testnet-grpc.posthuman.digital:443
- 💾 **Snapshots**: https://snapshots.posthuman.digital/celestia-testnet/
- 🌐 **Addrbook**: https://snapshots.posthuman.digital/celestia-testnet/addrbook.json

---

## 🛡️ Official Celestia Resources

- 📚 **Docs**: https://docs.celestia.org
- 💬 **Discord**: https://discord.com/invite/celestiacommunity
- 🐦 **X (Twitter)**: https://x.com/CelestiaOrg
- 💻 **GitHub**: https://github.com/celestiaorg/celestia-app
- 📊 **Explorer**: https://celestiascan.com

---

## 🐛 Troubleshooting

**Node not syncing?**
```bash
sudo journalctl -u celestia-appd -f -n 100
celestia-appd status 2>&1 | jq .SyncInfo
```

**Service won't start?**
```bash
sudo systemctl status celestia-appd
sudo journalctl -u celestia-appd -n 50 --no-pager
```

**Check sync status:**
```bash
./celestia-manager.sh
# Select: 7 (Status & Logs) → 2 (Check Sync Status)
```

---

## 🆕 Features

### Network Selection
Supports both Mainnet and Testnet:
```bash
export NETWORK_TYPE=testnet  # or mainnet (default)
./celestia-manager.sh
```

### Custom Installation Directory
Install to custom location:
```bash
export CELESTIA_HOME=/mnt/data/.celestia-app
./celestia-manager.sh
```

### DA Nodes Management
Complete suite for Data Availability nodes:
- Main Menu → Option 5 → Option 1 (Install DA Node)
- Support for Bridge, Full Storage, and Light nodes
- Unified management interface

---

## 🔄 Quick Update

```bash
./celestia-manager.sh
# Select: 2 (Update Node) → Press Enter for latest version
```

---

## 🛡️ Security Best Practices

- 🔐 Backup `~/.celestia-app/config/priv_validator_key.json`
- 🔥 Use script's firewall configuration (Option 3 → 5)
- 🔑 Enable SSH key-based authentication
- 👁️ Setup monitoring and alerts
- 💰 Never share private keys or seed phrases

---

## 📝 License

MIT License - [PostHuman Validator](https://posthuman.digital)

**Support:**
- 🐛 GitHub Issues: https://github.com/Validator-POSTHUMAN/celestia-oneliner
- 💬 Discord: PostHuman Community
- 📧 Contact: https://posthuman.digital

---

**Version:** 1.1.0 | **Last Updated:** 2025-01-11

🚀 **Happy Node Running!**