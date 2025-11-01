# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed - Data Availability Nodes Update

#### 🎯 Major Changes

**Replaced "Bridge Management" with "Data Availability Nodes"**
- Section 5 of the main menu is now "Data Availability Nodes" instead of "Bridge Management"
- **DA Nodes Installation Separated:** DA nodes now have dedicated installation submenu
- **Menu Reorganization:** Consensus nodes (Install Node menu) and DA nodes are now completely separate
- Comprehensive support for all three types of Celestia DA nodes:
  - 🌉 **Bridge Node** - Connects DA layer with consensus layer
  - 💾 **Full Storage Node** - Stores all block data
  - 💡 **Light Node** - Lightweight data verification

#### ✨ New Features

**1. Install Data Availability Nodes**
- Added `install_node_light()` - Install Light Node
- Added `install_node_full()` - Install Full Storage Node
- Enhanced `install_node_bridge()` - Improved Bridge Node installation
- All installations include:
  - Automatic dependency checking
  - Systemd service creation
  - Wallet generation
  - Service auto-start

**2. Unified DA Node Management**
- `check_da_node_status()` - Check status for any DA node type
- `check_da_wallet_balance()` - Check wallet balance for any DA node type
- `get_da_node_id()` - Get peer ID for any DA node type
- `get_da_wallet_address()` - Get wallet address for any DA node type
- `update_da_node()` - Update any DA node type
- `reset_da_node()` - Reset any DA node type
- `delete_da_node()` - Delete specific or all DA nodes
- `view_da_logs()` - View logs for any DA node type

**3. Enhanced Install Menu Structure**
- **Consensus Nodes Menu (Option 1):** Now contains ONLY consensus nodes (Pruned/Archive)
- **DA Nodes Menu (Option 5 → Option 1):** Dedicated submenu for all DA node installations
  - Bridge Node (Archive/Snapshot)
  - Full Storage Node
  - Light Node
- Better separation of concerns between consensus and DA layers

**4. Improved DA Nodes Menu**
- **New Option 1:** Install DA Node - Opens dedicated installation submenu
- Interactive selection for node type in all operations
- Support for managing multiple node types simultaneously
- Option to delete all DA nodes at once
- Dedicated logs viewer for each node type
- All DA operations now in single, organized menu

**5. Smart Disk Space Checking**
- `check_system_requirements()` now checks disk space of selected installation directory
- If `CELESTIA_HOME` is set to `/mnt/data/.celestia-app`, checks `/mnt/data` disk space
- No longer assumes root filesystem - checks actual target disk
- Provides accurate warnings for custom installation paths

#### 🔧 Technical Improvements

**Function Renaming (Breaking Changes)**
- `bridge_management_menu()` → `da_nodes_menu()`
- `check_bridge_installed()` → `check_da_node_installed()`
- `check_bridge_status()` → `check_da_node_status()`
- `check_bridge_wallet()` → `check_da_wallet_balance()`
- `get_node_id()` → `get_da_node_id()`
- `update_bridge_node()` → `update_da_node()`
- `delete_bridge_node()` → `delete_da_node()`
- `reset_bridge_node()` → `reset_da_node()`
- `get_wallet_address()` → `get_da_wallet_address()`

**Service Configuration**
- `celestia-bridge.service` - Bridge Node service
- `celestia-full.service` - Full Storage Node service
- `celestia-light.service` - Light Node service

**Data Directories**
- `~/.celestia-bridge/` - Bridge Node data
- `~/.celestia-full/` - Full Storage Node data
- `~/.celestia-light/` - Light Node data

#### 📝 Configuration Details

**Bridge Node:**
- Requires Core RPC node IP
- Archival mode enabled
- Metrics enabled (otel.celestia.observer)
- Supports snapshot sync

**Full Storage Node:**
- Requires Core RPC node IP
- Full data storage
- Metrics enabled
- Manual sync from genesis

**Light Node:**
- No Core RPC required
- Connects via P2P network
- Minimal resource requirements
- Public RPC: https://rpc.celestia.pops.one

#### 📚 Documentation Updates

**README.md**
- Updated feature list with all DA node types
- Added system requirements for each node type:
  - Bridge: 4+ cores, 8GB RAM, 500GB SSD
  - Full Storage: 4+ cores, 8GB RAM, 500GB SSD
  - Light: 2+ cores, 2GB RAM, 50GB SSD
- Updated menu structure documentation

#### 🔄 Migration Guide

**For Existing Users:**
1. The script is backward compatible
2. Existing bridge nodes will continue to work
3. All old bridge functions now support multi-node selection
4. No action required for existing installations

**For New Installations:**
1. Select network type (mainnet/testnet)
2. Choose DA node type from Install Menu (options 5-8)
3. Follow the interactive prompts
4. Manage nodes via "Data Availability Nodes" menu (option 5)

#### 🐛 Bug Fixes
- Fixed keyring backend inconsistency (now uses `test` backend)
- Improved error handling for missing node directories
- Added proper directory existence checks
- Fixed disk space check to use custom directory path instead of root filesystem

#### 🏗️ Architecture Changes

**Menu Structure:**
```
OLD:
Main Menu
├── 1. Install Node (Consensus + DA nodes mixed)
│   ├── Options 1-4: Consensus nodes
│   └── Options 5-8: DA nodes
└── 5. Bridge Management

NEW:
Main Menu
├── 1. Install Node (Consensus nodes ONLY)
│   └── Options 1-4: Pruned/Archive nodes
└── 5. Data Availability Nodes
    ├── 1. Install DA Node (New submenu!)
    │   ├── 1-2: Bridge Nodes
    │   ├── 3: Full Storage Node
    │   └── 4: Light Node
    └── 2-9: Management operations
```

**Benefits:**
- Clear separation between consensus and DA layers
- Easier to find and install specific node types
- Better organization and user experience
- Reduced menu clutter in Install Node section

#### 📦 Dependencies
- Celestia Node Version: v0.21.5 (BRIDGE_VERSION)
- Go Version: 1.24.1
- All dependencies shared across node types

---

## [1.0.0] - Previous Release

### Features
- Initial release with mainnet/testnet support
- Consensus node installation (Pruned/Archive)
- Bridge node installation
- Validator operations
- Service management
- Snapshot support

---

## Reference Links

- ITRocket Bridge Node Guide: https://itrocket.net/services/mainnet/celestia/bridge-node/
- Official Celestia Documentation: https://docs.celestia.org
- PostHuman Validator: https://posthuman.digital