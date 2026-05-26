#!/usr/bin/env bash
#
# AvalonLotus Mac Setup — bootstrap a new Mac in one command.
#
# Usage:
#   Recommended (verify-then-run):
#     git clone https://github.com/AvalonLotus/Mac-Setup.git ~/Mac-Setup
#     bash ~/Mac-Setup/install.sh
#
#   One-liner (faster but YOU MUST trust the source):
#     curl -fsSL https://raw.githubusercontent.com/AvalonLotus/Mac-Setup/main/install.sh | bash
#
# What it does:
#   1. Installs Homebrew + git + jq if missing
#   2. Clones (or pulls) all your AvalonLotus repos
#   3. Runs each repo's setup script (git-autosync, Obsidian Vault, etc.)
#   4. Reports what worked vs failed at the end
#
# Idempotent — safe to re-run. Re-running pulls the latest of each repo
# and re-runs its setup. Setup scripts themselves should be idempotent
# (Homebrew, pip, font installers all are).

set -uo pipefail   # NOT -e — we want to continue past individual repo failures

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; DIM='\033[2m'; NC='\033[0m'
log()  { printf "${GREEN}▶${NC} %s\n" "$*"; }
ok()   { printf "  ${GREEN}✓${NC} %s\n" "$*"; }
warn() { printf "  ${YELLOW}!${NC} %s\n" "$*"; }
fail() { printf "  ${RED}✗${NC} %s\n" "$*"; }
dim()  { printf "${DIM}  %s${NC}\n" "$*"; }

# ─── Prereqs ──────────────────────────────────────────────────────────
log "Checking prereqs"
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Make brew available in this shell
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
ok "Homebrew at $(brew --prefix)"
command -v git >/dev/null 2>&1 || brew install git
ok "git $(git --version | awk '{print $3}')"
command -v jq  >/dev/null 2>&1 || brew install jq
ok "jq $(jq --version)"

# ─── Baseline apps & CLI tools (idempotent — brew skips if already present) ───
# Pinned to AvalonLotus's daily-driver set. Each line = either a brew formula
# (CLI tool) or a cask (.app in /Applications). To remove an item, just
# delete its line; brew install is no-op if the cask/formula is already there.
log "Installing baseline tools (CLI + macOS apps)"

# CLI formulae — small, fast, mostly invisible
FORMULAE="gh mas"
for tool in $FORMULAE; do
  if brew list "$tool" >/dev/null 2>&1; then
    dim "  ✓ $tool (formula) already installed"
  else
    log "  brew install $tool"
    brew install "$tool" 2>&1 | tail -3 || warn "    $tool install failed (continue)"
  fi
done

# GUI apps via cask
# GFN essentials:  docker, 1password, 1password-cli
# Daily drivers:   google-chrome, visual-studio-code, obsidian, claude
# Specialised:     obs, utm, codex
CASKS="docker 1password 1password-cli google-chrome visual-studio-code obsidian claude obs utm codex"
for cask in $CASKS; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    dim "  ✓ $cask (cask) already installed"
  else
    log "  brew install --cask $cask"
    brew install --cask "$cask" 2>&1 | tail -3 || warn "    $cask install failed (continue)"
  fi
done

ok "baseline tools done"

# ─── Repo manifest ────────────────────────────────────────────────────
# Add new repos here. Format per row: <repo_url>|<local_path>|<setup_cmd>
# setup_cmd is run from the repo's root directory. Empty = no setup.
REPOS="
https://github.com/AvalonLotus/Global-Finance-News.git|$HOME/Global-Finance-News|bash scripts/install-git-autosync.sh
https://github.com/AvalonLotus/AvalonLotus-Vault.git|$HOME/AvalonLotus-Obsidian|./setup.sh
https://github.com/AvalonLotus/AvalonLotus-Skills.git|$HOME/AvalonLotus-Skills|
https://github.com/AvalonLotus/AvalonLotus.com.git|$HOME/AvalonLotus.com|
"

# ─── Process each repo ────────────────────────────────────────────────
SUCCEEDED=""
FAILED=""
SKIPPED=""

echo "$REPOS" | while IFS='|' read -r url path setup; do
  [ -z "$url" ] && continue
  name=$(basename "$path")
  echo
  log "[$name]"

  if [ -d "$path/.git" ]; then
    dim "exists at $path — pulling"
    if ! (cd "$path" && git pull --rebase --autostash --quiet 2>&1 | tail -3); then
      fail "$name: pull failed"
      continue
    fi
    ok "pulled"
  else
    dim "cloning into $path"
    if ! git clone --quiet "$url" "$path" 2>&1; then
      fail "$name: clone failed"
      continue
    fi
    ok "cloned"
  fi

  if [ -n "$setup" ]; then
    dim "running setup: $setup"
    if (cd "$path" && eval "$setup"); then
      ok "$name setup OK"
    else
      fail "$name setup failed (clone OK, just setup)"
    fi
  else
    dim "(no setup script, repo is just cloned)"
  fi
done

echo
log "All done. See above for any ✗ failures."
echo
echo "What's installed:"
echo "$REPOS" | while IFS='|' read -r url path setup; do
  [ -z "$url" ] && continue
  [ -d "$path/.git" ] && echo "  • $(basename "$path")  → $path"
done
echo
echo "If you re-run this script, it will pull the latest of each repo and"
echo "re-run their setup. All setup scripts are designed to be idempotent."
