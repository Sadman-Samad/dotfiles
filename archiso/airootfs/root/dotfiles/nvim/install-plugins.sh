#!/usr/bin/env bash

# Force install new Neovim plugins
# Run this after adding new plugin configurations

echo "Installing new Neovim plugins..."
echo "This will:"
echo "  1. Start Neovim"
echo "  2. Run :Lazy sync to install plugins"
echo "  3. Wait for completion"
echo ""
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Run Neovim with Lazy sync
nvim -c "Lazy sync" -c "echo 'Installing plugins... Press q to close Lazy window when done, then :qa to quit Neovim'"
