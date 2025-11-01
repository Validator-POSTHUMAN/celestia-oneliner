# Celestia Data Availability Nodes Guide

Complete guide for installing and managing Celestia Data Availability (DA) nodes using the PostHuman Celestia Node Manager.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Node Types](#node-types)
3. [Installation Guide](#installation-guide)
4. [Management Operations](#management-operations)
5. [Troubleshooting](#troubleshooting)
6. [FAQ](#faq)

---

## Overview

Celestia's Data Availability layer uses three types of nodes:

| Node Type | Purpose | Resources | Use Case |
|-----------|---------|-----------|----------|
| **Bridge Node** | Connects DA layer with consensus | Medium | Data availability sampling, bridges |
| **Full Storage Node** | Stores all block data | Medium | Full data storage, archival |
| **Light Node** | Lightweight verification | Minimal | Apps, wallets, lightweight clients |

---

## Node Types

### 🌉 Bridge Node

**Purpose:**
- Bridges the Data Availability layer with the consensus layer
- Validates and forwards block data
- Participates in data availability sampling

**Requirements:**
- CPU: 4+ cores
- RAM: 8 GB minimum
- Disk: 500 GB+ SSD (grows over time)
- Network: 100 Mbps+

**Features:**
- Archival mode support
- Snapshot sync available
- Metrics integration
- Requires Core RPC connection

**When to use:**
- Building bridges between chains
- Running infrastructure services
- Need full DA layer access
- Require historical data

---

### 💾 Full Storage Node

**Purpose:**
- Stores complete block data
- Provides data availability guarantees
- Serves data to light clients

**Requirements:**
- CPU: 4+ cores
- RAM: 8 GB minimum
- Disk: 500 GB+ SSD (grows over time)
- Network: 100 Mbps+

**Features:**
- Complete data storage
- P2P data serving
- Metrics integration
- Requires Core RPC connection

**When to use:**
- Need complete data availability
- Running data services
- Archival purposes
- High reliability requirements

---

### 💡 Light Node

**Purpose:**
- Lightweight data availability verification
- Minimal resource consumption
- Data availability sampling

**Requirements:**
- CPU: 2+ cores
- RAM: 2 GB minimum
- Disk: 50 GB+ SSD
- Network: 25 Mbps+

**Features:**
- Minimal resources
- No Core RPC needed
- Fast sync
- Perfect for development

**When to use:**
- Building applications
- Testing and development
- Wallet integration
- Resource-constrained environments

---

## Installation Guide

### Prerequisites

1. **Launch the Manager:**
```bash
curl -o celestia-manager.sh https://raw.githubusercontent.com/Validator-POSTHUMAN/celestia-oneliner/main/celestia-manager.sh
chmod +x celestia-manager.sh
./celestia-manager.sh
```

2. **Navigate to DA Nodes Menu:**
- Choose option `5` (Data Availability Nodes)
- Then select option `1` (Install DA Node)
- Select your network (Mainnet/Testnet) and directory

---

### Installing Bridge Node

**Step 1:** Navigate to installation:
- Main Menu → Option `5` (Data Availability Nodes)
- Select Option `1` (Install DA Node)
- Choose network and installation directory

**Step 2:** From Install DA Node Menu, select:
- Option `1` - Bridge Node (Archive sync)
- Option `2` - Bridge Node (Use Snapshot) ⚡ Recommended

**Step 3:** Provide Core RPC IP when prompted:
```
Enter Core RPC node IP: <your-rpc-ip>
```

You can use:
- Your own consensus node RPC
- Public RPC: `consensus.lunaroasis.net` (example)
- PostHuman RPC: `rpc-celestia-mainnet.posthuman.digital`

**Step 4:** Wait for installation to complete

**Step 5:** Fund your wallet
```bash
# Get wallet address
cd $HOME/celestia-node
./cel-key list --node.type bridge --keyring-backend test
```

⚠️ **Important:** Bridge nodes require TIA tokens for PayForBlob transactions!

**Step 6:** Verify installation
```bash
# Check service status
sudo systemctl status celestia-bridge

# View logs
sudo journalctl -u celestia-bridge -f

# Check sync status
celestia header sync-state --node.store ~/.celestia-bridge/
```

---

### Installing Full Storage Node

**Step 1:** Navigate to installation:
- Main Menu → Option `5` (Data Availability Nodes)
- Select Option `1` (Install DA Node)
- Choose network and installation directory

**Step 2:** From Install DA Node Menu, select option `3` (Full Storage Node)

**Step 3:** Provide Core RPC IP:
```
Enter Core RPC node IP: <your-rpc-ip>
```

**Step 4:** Wait for installation and sync

**Step 5:** Verify installation
```bash
# Check service
sudo systemctl status celestia-full

# View logs
sudo journalctl -u celestia-full -f

# Check sync
celestia header sync-state --node.store ~/.celestia-full/
```

---

### Installing Light Node

**Step 1:** Navigate to installation:
- Main Menu → Option `5` (Data Availability Nodes)
- Select Option `1` (Install DA Node)
- Choose network and installation directory

**Step 2:** From Install DA Node Menu, select option `4` (Light Node)

**Step 3:** Installation is automatic (no Core RPC needed)

**Step 4:** Verify installation
```bash
# Check service
sudo systemctl status celestia-light

# View logs
sudo journalctl -u celestia-light -f

# Check sync
celestia header sync-state --node.store ~/.celestia-light/
```

---

## Management Operations

Access DA Nodes management from main menu option `5` (Data Availability Nodes)

### Available Operations

#### 1️⃣ Check DA Node Status

Check sync status for any node type:
- Shows current block height
- Displays sync status
- Network information

**Usage:**
1. Select option `1` from DA Nodes menu
2. Choose node type (Bridge/Full/Light)
3. View status

---

#### 2️⃣ Check DA Wallet Balance

Check wallet balance for your DA node:
- Current balance
- Account information
- Network details

**Usage:**
1. Select option `2` from DA Nodes menu
2. Choose node type
3. View balance

---

#### 3️⃣ Get DA Node ID

Get your node's peer ID for sharing:
- Full node ID
- Network information
- Connection details

**Usage:**
1. Select option `3` from DA Nodes menu
2. Choose node type
3. Copy peer ID

**Example output:**
```json
{
  "ID": "12D3KooW...",
  "Addrs": ["/ip4/x.x.x.x/tcp/2121"]
}
```

---

#### 4️⃣ Get DA Wallet Address

Retrieve wallet address for funding:

**Usage:**
1. Select option `4` from DA Nodes menu
2. Choose node type
3. Copy address and fund it

---

#### 5️⃣ Update DA Node

Update to latest Celestia node version:

**Usage:**
1. Select option `5` from DA Nodes menu
2. Choose node type to update
3. Confirm update
4. Wait for completion

**The script will:**
- Stop the service
- Download latest version
- Build and install
- Update configuration
- Restart service

---

#### 6️⃣ Reset DA Node

Reset node store (troubleshooting):

**Usage:**
1. Select option `6` from DA Nodes menu
2. Choose node type
3. Confirm reset

⚠️ **Warning:** This removes local data. The node will resync.

---

#### 7️⃣ Delete DA Node

Remove DA node completely:

**Options:**
- Delete specific node type
- Delete all DA nodes at once

**Usage:**
1. Select option `7` from DA Nodes menu
2. Choose what to delete
3. Confirm deletion

**The script will:**
- Stop service
- Disable auto-start
- Remove service files
- Delete data directory
- Clean up binaries (if all deleted)

---

#### 8️⃣ View DA Node Logs

View real-time logs:

**Usage:**
1. Select option `8` from DA Nodes menu
2. Choose node type
3. View logs (Ctrl+C to exit)

**Alternative commands:**
```bash
# Bridge logs
sudo journalctl -u celestia-bridge -f

# Full node logs
sudo journalctl -u celestia-full -f

# Light node logs
sudo journalctl -u celestia-light -f
```

---

## Troubleshooting

### Bridge Node Issues

**Problem:** "Error: bridge is not initialized"
```bash
# Solution: Re-initialize bridge
celestia bridge init --core.ip <RPC_IP>
```

**Problem:** "Error: insufficient funds"
```bash
# Solution: Fund your bridge wallet
cd $HOME/celestia-node
./cel-key list --node.type bridge --keyring-backend test
# Send TIA to displayed address
```

**Problem:** Bridge not syncing
```bash
# Check Core RPC connection
curl http://<RPC_IP>:26657/status

# Restart bridge
sudo systemctl restart celestia-bridge
```

---

### Full Storage Node Issues

**Problem:** Node using too much disk space
```bash
# Check disk usage
du -sh ~/.celestia-full/

# Solution: This is normal - full nodes store all data
# Consider adding more disk space
```

**Problem:** Slow sync
```bash
# Check network connectivity
celestia p2p info --node.store ~/.celestia-full/

# Restart service
sudo systemctl restart celestia-full
```

---

### Light Node Issues

**Problem:** Light node not connecting
```bash
# Check P2P connectivity
celestia p2p info --node.store ~/.celestia-light/

# Restart light node
sudo systemctl restart celestia-light
```

**Problem:** "Error: failed to find header"
```bash
# Reset and resync
celestia light unsafe-reset-store
sudo systemctl restart celestia-light
```

---

### General Issues

**Check Service Status:**
```bash
# Bridge
sudo systemctl status celestia-bridge

# Full
sudo systemctl status celestia-full

# Light
sudo systemctl status celestia-light
```

**View Recent Errors:**
```bash
# Last 50 lines with errors
sudo journalctl -u celestia-bridge -n 50 | grep -i error
sudo journalctl -u celestia-full -n 50 | grep -i error
sudo journalctl -u celestia-light -n 50 | grep -i error
```

**Restart All DA Nodes:**
```bash
sudo systemctl restart celestia-bridge celestia-full celestia-light
```

---

## FAQ

### Q: Can I run multiple DA node types on the same server?

**A:** Yes! All three node types can run simultaneously. They use different:
- Service names (celestia-bridge, celestia-full, celestia-light)
- Data directories (~/.celestia-bridge, ~/.celestia-full, ~/.celestia-light)
- Ports (configurable)

**Installation tip:** Each node type can use the same or different custom directories for their data.

---

### Q: Which node type should I choose?

**A:** Depends on your use case:
- **Building apps?** → Light Node (lowest resources)
- **Need full data?** → Full Storage Node
- **Running bridge?** → Bridge Node (requires TIA tokens)
- **Development/testing?** → Light Node (fastest setup)
- **Production infrastructure?** → Bridge or Full Storage Node

---

### Q: Do I need a consensus node to run DA nodes?

**A:** 
- **Bridge & Full:** Yes, require Core RPC connection
- **Light:** No, connects via P2P network

---

### Q: How much does it cost to run DA nodes?

**A:**
- **Bridge Node:** Requires TIA for PayForBlob transactions
- **Full Storage Node:** No transaction costs
- **Light Node:** No transaction costs

---

### Q: Can I use snapshots for faster sync?

**A:**
- **Bridge Node:** Yes, available via installation menu (option 2 in Install DA Node menu)
- **Full Storage Node:** No snapshot available yet
- **Light Node:** Fast sync by default, no snapshot needed

Access snapshots: Main Menu → Option 5 → Option 1 → Option 2

---

### Q: How do I backup my DA node?

**A:**
```bash
# Backup wallet keys
cp -r ~/celestia-node/ ~/celestia-node-backup/

# Backup data (Bridge example)
cp -r ~/.celestia-bridge/ ~/.celestia-bridge-backup/
```

---

### Q: How do I migrate to a new server?

**A:**
1. Stop service on old server
2. Backup data directory and cel-key
3. Install node on new server
4. Restore data directory
5. Restore cel-key
6. Start service

```bash
# On old server
sudo systemctl stop celestia-bridge
tar -czf bridge-backup.tar.gz ~/.celestia-bridge celestia-node

# Transfer to new server
scp bridge-backup.tar.gz user@new-server:~/

# On new server
tar -xzf bridge-backup.tar.gz -C ~/
# Run installation script to setup service
# Start service
```

---

### Q: How do I check my node's performance?

**A:**
```bash
# Check resource usage
htop

# Check network usage
nethogs

# Check disk I/O
iotop

# DA node metrics (if enabled)
curl http://localhost:26658/metrics
```

---

### Q: What's the difference between Bridge and Full Storage nodes?

**A:**
- **Bridge Node:** Connects consensus layer with DA layer, bridges data, requires TIA tokens
- **Full Storage Node:** Pure storage node, serves data to light clients, no tokens required
- Both store complete data, but Bridge has additional consensus bridging role
- Bridge nodes participate in PayForBlob transactions

---

### Q: Can I run a validator and DA nodes together?

**A:** Yes, but consider:
- Separate servers recommended for production
- Ensure sufficient resources (CPU, RAM, disk)
- Use different data directories (custom paths recommended)
- Monitor system performance carefully
- Validators have strict uptime requirements
- DA nodes can use `/mnt/data` while validator uses default path

---

### Q: Does the script check disk space for my custom directory?

**A:** Yes! When you select a custom installation directory (e.g., `/mnt/data/.celestia-app`), the script now checks the disk space of that specific mount point, not the root filesystem. This ensures accurate resource validation.

---

## Additional Resources

### Official Documentation
- **Celestia Docs:** https://docs.celestia.org
- **Node Tutorial:** https://docs.celestia.org/nodes/overview
- **API Reference:** https://node-rpc-docs.celestia.org

### PostHuman Services
- **Website:** https://posthuman.digital
- **Snapshots:** https://snapshots.posthuman.digital/celestia-mainnet/
- **RPC:** https://rpc-celestia-mainnet.posthuman.digital
- **Explorer:** https://celestia-explorer.posthuman.digital

### Community
- **Discord:** https://discord.com/invite/celestiacommunity
- **Forum:** https://forum.celestia.org
- **GitHub:** https://github.com/celestiaorg

---

## Support

Having issues? Get help:

1. **Check Logs:** Most issues show up in logs
2. **GitHub Issues:** [Report bugs](https://github.com/Validator-POSTHUMAN/celestia-oneliner/issues)
3. **Discord:** PostHuman and Celestia communities
4. **Documentation:** This guide and official docs

---

**Version:** 1.0.0 | **Last Updated:** 2025-01-11 | **Maintained by:** [PostHuman Validator](https://posthuman.digital)