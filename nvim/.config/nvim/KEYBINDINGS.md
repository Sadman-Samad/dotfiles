# Neovim Keybindings Reference

Quick reference for all custom keybindings in this Neovim configuration.

## Table of Contents

- [Obsidian (Note-Taking)](#obsidian-note-taking)
- [Git (Neogit & Diffview)](#git-neogit--diffview)
- [Productivity Tools](#productivity-tools)
- [Code Folding](#code-folding)
- [Themes](#themes)
- [General LazyVim](#general-lazyvim)

---

## Obsidian (Note-Taking)

**Leader prefix:** `<leader>o`

### Note Creation & Navigation
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>on` | New Note | Create a new note |
| `<leader>oq` | Quick Switch | Quick switch between notes (fuzzy finder) |
| `<leader>oo` | Search Notes | Search all notes (Telescope) |
| `<leader>ob` | Show Backlinks | Show backlinks to current note |
| `<leader>ow` | Switch Workspace | Switch between vaults (personal/work/public/projects) |

### Daily Notes
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ot` | Today's Note | Open today's daily note |
| `<leader>oy` | Yesterday's Note | Open yesterday's daily note |
| `<leader>oT` | Insert Template | Insert a template into current note |

### Linking
| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `<leader>ol` | Link to Note | Visual | Link selected text to existing note |
| `<leader>oL` | Link to New Note | Visual | Link selected text to new note |
| `<leader>of` | Follow Link | Normal | Follow link under cursor |
| `gf` | Follow Link | Normal | Follow markdown/wiki link (in markdown files) |
| `<cr>` | Smart Action | Normal | Follow link or toggle checkbox |

### Utilities
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>or` | Rename Note | Rename current note |
| `<leader>os` | Search Tags | Search notes by tags |
| `<leader>oO` | Open in Obsidian | Open current note in Obsidian app |
| `<leader>ch` | Toggle Checkbox | Toggle markdown checkbox |

---

## Git (Lazygit & Diffview)

**Leader prefix:** `<leader>g`

### Lazygit (Terminal Git UI)
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>gg` | LazyGit | Open lazygit in floating terminal |
| `<leader>gf` | LazyGit Current File | Open lazygit focused on current file |
| `<leader>gl` | LazyGit Log | Open lazygit commit log |

#### Inside Lazygit
Lazygit runs in a terminal buffer. Use your normal lazygit keybindings!
- Common: `a` stage, `c` commit, `p` push, `P` pull, `x` menu
- See: https://github.com/jesseduffield/lazygit for full keybindings

### Diffview (Advanced Diffs)
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>gd` | Diffview Open | Open diff view |
| `<leader>gD` | Diffview Close | Close diff view |
| `<leader>gh` | File History | Show current file history |
| `<leader>gH` | Branch History | Show full branch history |

#### Inside Diffview
| Key | Action |
|-----|--------|
| `<tab>` | Next file |
| `<s-tab>` | Previous file |
| `gf` | Go to file |
| `-` | Toggle stage |
| `S` | Stage all |
| `U` | Unstage all |

---

## Productivity Tools

### Search & Replace (Spectre)
| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `<leader>sr` | Open Spectre | Normal | Open search/replace UI |
| `<leader>sw` | Search Word | Normal | Search current word |
| `<leader>sw` | Search Selection | Visual | Search selected text |
| `<leader>sf` | Search in File | Normal | Search/replace in current file only |

#### Inside Spectre Buffer
| Key | Action |
|-----|--------|
| `<leader>R` | Replace All |
| `<leader>rc` | Replace Current Line |
| `dd` | Toggle Line |
| `<cr>` | Go to File |
| `<leader>q` | Send to Quickfix |
| `ti` | Toggle Ignore Case |
| `th` | Toggle Hidden Files |

### Colorizer (Color Preview)
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>uc` | Toggle Colorizer | Toggle color highlighting |
| `<leader>uC` | Reload Colorizer | Reload all buffers |

### Refactoring
| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `<leader>re` | Extract Function | Visual | Extract selected code to function |
| `<leader>rf` | Extract to File | Visual | Extract function to new file |
| `<leader>rv` | Extract Variable | Visual | Extract to variable |
| `<leader>ri` | Inline Variable | Normal/Visual | Inline variable |
| `<leader>rb` | Extract Block | Normal | Extract block |
| `<leader>rbf` | Extract Block to File | Normal | Extract block to file |
| `<leader>rr` | Refactor Menu | Visual | Show refactor options menu |

---

## Code Folding

### UFO (Enhanced Folding)
| Key | Action | Description |
|-----|--------|-------------|
| `zR` | Open All Folds | Open all folds in buffer |
| `zM` | Close All Folds | Close all folds in buffer |
| `zr` | Open Folds Except Kinds | Open folds except certain kinds |
| `zm` | Close Folds With | Close folds with certain kinds |
| `zK` | Peek Fold | Peek at folded content (or LSP hover) |
| `zo` | Open Fold | Open fold under cursor |
| `zc` | Close Fold | Close fold under cursor |
| `za` | Toggle Fold | Toggle fold under cursor |

---

## Themes

### Switch Themes
| Command | Description |
|---------|-------------|
| `:RosePine` | Switch to Rose Pine (current variant) |
| `:RosePineMoon` | Switch to Rose Pine Moon (dark) |
| `:RosePineMain` | Switch to Rose Pine Main (darker) |
| `:RosePineDawn` | Switch to Rose Pine Dawn (light) |

**Note:** Catppuccin is your default theme. Rose Pine is available as an alternative.

---

## General LazyVim

### File Navigation
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ff` | Find Files | Fuzzy find files |
| `<leader>fr` | Recent Files | Recent files |
| `<leader>fg` | Live Grep | Search in files |
| `<leader>fb` | Buffers | List buffers |
| `<leader>e` | File Explorer | Toggle file explorer |

### LSP
| Key | Action | Description |
|-----|--------|-------------|
| `gd` | Go to Definition | Jump to definition |
| `gr` | References | Show references |
| `K` | Hover | Show hover information |
| `<leader>ca` | Code Action | Show code actions |
| `<leader>cr` | Rename | Rename symbol |

### Harpoon (Quick Navigation)
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>h` | Harpoon Menu | Show harpoon menu |
| `<leader>a` | Add File | Add file to harpoon |

### Window Management
| Key | Action | Description |
|-----|--------|-------------|
| `<C-h>` | Left Window | Move to left window |
| `<C-j>` | Bottom Window | Move to bottom window |
| `<C-k>` | Top Window | Move to top window |
| `<C-l>` | Right Window | Move to right window |

### Buffers
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>bd` | Delete Buffer | Delete current buffer |
| `<S-h>` | Previous Buffer | Go to previous buffer |
| `<S-l>` | Next Buffer | Go to next buffer |

### Terminal
| Key | Action | Description |
|-----|--------|-------------|
| `<C-/>` | Toggle Terminal | Toggle terminal |
| `<C-_>` | Terminal (Alt) | Alternative terminal toggle |

---

## Tips

### Obsidian Workflow
1. Use `<leader>on` to create new notes
2. Use `<leader>oo` to search all notes
3. Use `<leader>ot` for daily notes
4. Use `gf` to follow links in markdown
5. Use `<leader>ow` to switch between vaults

### Git Workflow
1. Use `<leader>gg` to open Lazygit
2. Use your normal lazygit workflow (a=stage, c=commit, p=push, etc.)
3. Use `<leader>gd` to see diffs in Neovim (Diffview)
4. Use `<leader>gh` to see file history in Neovim

### Refactoring Workflow
1. Select code in visual mode
2. Use `<leader>rr` to see refactoring options
3. Or use specific refactorings like `<leader>re` for extract function

### Search & Replace
1. Use `<leader>sr` to open Spectre
2. Type search pattern
3. Type replacement
4. Press `<leader>R` to replace all

### Code Folding
1. Use `zM` to fold everything for overview
2. Use `za` to toggle individual folds
3. Use `zK` to peek at folded content

---

## Customization

To modify these keybindings, edit the respective plugin files:
- Obsidian: `nvim/.config/nvim/lua/plugins/obsidian.lua`
- Git: `nvim/.config/nvim/lua/plugins/lazygit.lua`
- Productivity: `nvim/.config/nvim/lua/plugins/productivity.lua`

For general LazyVim keybindings, see: https://www.lazyvim.org/keymaps
