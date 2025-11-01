# 🚀 Upgrade Notice: Data Availability Nodes Update

## What's Changed?

The **Bridge Management** section (Menu Option 5) has been upgraded to **Data Availability Nodes** with support for all Celestia DA node types!

---

## 🎯 Key Changes

### ✅ What's New

1. **Three Node Types Now Supported:**
   - 🌉 **Bridge Node** - Connects DA layer with consensus (previously available)
   - 💾 **Full Storage Node** - Complete data storage (NEW!)
   - 💡 **Light Node** - Lightweight verification (NEW!)

2. **Unified Management:**
   - Single menu for all DA node operations
   - Interactive node type selection
   - Manage multiple nodes from one place

3. **Enhanced Installation:**
   - DA nodes now have their own installation submenu
   - Access via: Main Menu → Option 5 (Data Availability Nodes) → Option 1 (Install DA Node)
   - Consensus nodes (options 1-4) are now separate from DA nodes
   - All nodes use latest version (v0.21.5)

4. **Improved Operations:**
   - Check status for any node type
   - View logs for each node separately
   - Delete individual or all DA nodes
   - Better error handling

---

## 🔄 For Existing Users

### ✅ Your Bridge Nodes Still Work!

**No action required!** Your existing bridge node installations:
- Continue to function normally
- Service name unchanged: `celestia-bridge`
- Data directory unchanged: `~/.celestia-bridge/`
- All management commands still work

### 📋 Menu Changes

**Old Menu (Option 5):**
```
Bridge Management
1. Check Bridge Node Status
2. Check Bridge Wallet Balance
3. Get Node ID
4. Get Wallet Address
5. Update Bridge Node
6. Reset Bridge Node
7. Delete Bridge Node
```

**New Menu (Option 5):**
```
Data Availability Nodes
1. Install DA Node            ← NEW! Dedicated installation menu
2. Check DA Node Status       ← Works for all node types
3. Check DA Wallet Balance    ← Works for all node types
4. Get DA Node ID             ← Works for all node types
5. Get DA Wallet Address      ← Works for all node types
6. Update DA Node             ← Works for all node types
7. Reset DA Node              ← Works for all node types
8. Delete DA Node             ← Works for all node types
9. View DA Node Logs          ← NEW! Node-specific logs
```

---

## 📖 Quick Start Guide

### Installing a New DA Node

1. **Run the script:**
   ```bash
   ./celestia-manager.sh
   ```

2. **Select option 5** (Data Availability Nodes)

3. **Select option 1** (Install DA Node)

4. **Choose your node type:**
   - **Option 1:** Bridge Node - Archive sync (requires Core RPC + funding)
   - **Option 2:** Bridge Node - Use Snapshot (requires Core RPC + funding) ⚡ Faster
   - **Option 3:** Full Storage Node (requires Core RPC)
   - **Option 4:** Light Node (minimal resources, no RPC needed)

5. **Follow the prompts** (select network and directory if not already set)

### Managing Existing Nodes

1. **Select option 5** (Data Availability Nodes)

2. **Choose operation** (status, balance, logs, etc.)

3. **Select node type** when prompted:
   - Bridge Node
   - Full Storage Node
   - Light Node

---

## 💡 Which Node Should I Choose?

| Use Case | Recommended Node |
|----------|------------------|
| Building rollups/bridges | Bridge Node |
| Need full data history | Full Storage Node |
| App development/testing | Light Node |
| Resource constrained | Light Node |
| Data availability service | Full Storage Node |
| Already running bridge | Keep Bridge Node |

---

## 📊 System Requirements

### Bridge Node
- CPU: 4+ cores
- RAM: 8 GB
- Disk: 500 GB+ SSD
- Needs: Core RPC + TIA tokens

### Full Storage Node
- CPU: 4+ cores
- RAM: 8 GB
- Disk: 500 GB+ SSD
- Needs: Core RPC

### Light Node
- CPU: 2+ cores
- RAM: 2 GB
- Disk: 50 GB+ SSD
- Needs: Nothing (P2P network)

---

## 🔄 Menu Structure Changes

### Old Structure:
```
Main Menu
├── 1. Install Node
│   ├── 1-4: Consensus Nodes
│   ├── 5-6: Bridge Nodes
│   └── 7-8: Full/Light Nodes
└── 5. Bridge Management
    └── Operations
```

### New Structure:
```
Main Menu
├── 1. Install Node
│   └── 1-4: Consensus Nodes ONLY
└── 5. Data Availability Nodes
    ├── 1. Install DA Node (submenu)
    │   ├── 1-2: Bridge Nodes
    │   ├── 3: Full Storage Node
    │   └── 4: Light Node
    └── 2-9: DA Operations
```

---

## 🔧 Technical Details

### Service Names
```bash
# Bridge Node
sudo systemctl status celestia-bridge

# Full Storage Node
sudo systemctl status celestia-full

# Light Node
sudo systemctl status celestia-light
```

### Data Directories
```bash
# Bridge Node
~/.celestia-bridge/

# Full Storage Node
~/.celestia-full/

# Light Node
~/.celestia-light/
```

### Log Commands
```bash
# Bridge Node
sudo journalctl -u celestia-bridge -f

# Full Storage Node
sudo journalctl -u celestia-full -f

# Light Node
sudo journalctl -u celestia-light -f
```

---

## 📚 Additional Resources

- **Complete Guide:** See `DA_NODES_GUIDE.md` for detailed documentation
- **Changelog:** See `CHANGELOG.md` for full list of changes
- **README:** Updated with all new features

### Helpful Links
- Official Docs: https://docs.celestia.org
- ITRocket Guide: https://itrocket.net/services/mainnet/celestia/bridge-node/
- PostHuman Services: https://posthuman.digital
- Snapshots: https://snapshots.posthuman.digital/celestia-mainnet/

---

## ❓ FAQ

**Q: Will this update affect my existing bridge node?**  
A: No, everything continues to work. Only the menu interface has improved.

**Q: Can I run multiple DA nodes on one server?**  
A: Yes! All three types can run simultaneously.

**Q: Do I need to reinstall anything?**  
A: No, just update the script and enjoy new features. Existing installations are not affected.

**Q: Why are DA nodes in a separate menu now?**  
A: For better organization - consensus nodes and DA nodes serve different purposes and have different requirements.

**Q: Where do I install DA nodes now?**  
A: Main Menu → Option 5 (Data Availability Nodes) → Option 1 (Install DA Node)

**Q: Which node type is best for me?**  
A: See the comparison table above or read `DA_NODES_GUIDE.md`.

**Q: Where do I get Core RPC for Bridge/Full nodes?**  
A: Use your own consensus node or public RPC:
   - PostHuman: `rpc-celestia-mainnet.posthuman.digital`
   - Community RPCs listed in official docs

**Q: Does the script check disk space for custom directories?**  
A: Yes! The script now checks disk space of the directory you select (e.g., /mnt/data/.celestia-app), not just root filesystem.

**Q: How do I update to the latest script?**  
A: Download again:
   ```bash
   curl -o celestia-manager.sh https://raw.githubusercontent.com/Validator-POSTHUMAN/celestia-oneliner/main/celestia-manager.sh
   chmod +x celestia-manager.sh
   ```

---

## 🐛 Issues or Questions?

1. **Check Logs:** Most issues show up in service logs
2. **Read Guide:** `DA_NODES_GUIDE.md` has troubleshooting section
3. **GitHub Issues:** https://github.com/Validator-POSTHUMAN/celestia-oneliner/issues
4. **Discord:** PostHuman and Celestia communities

---

## 🙏 Credits

- **ITRocket** for Bridge Node documentation and guides
- **Celestia Team** for the amazing DA layer
- **PostHuman Validator** for script development and maintenance

---

**Happy Node Running! 🚀**

*Version: 1.1.0 | Date: 2025-01-11 | Maintained by PostHuman Validator*