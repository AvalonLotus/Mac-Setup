# AvalonLotus Mac Setup

One-command bootstrap for a new Mac. Clones every AvalonLotus repo and runs each one's setup script.

## Quick start (new Mac)

```bash
# Option A — verify-then-run (recommended)
git clone https://github.com/AvalonLotus/Mac-Setup.git ~/Mac-Setup
bash ~/Mac-Setup/install.sh

# Option B — one-liner (faster, requires trust)
curl -fsSL avalonlotus.com/mac | bash
```

Takes ~5-10 minutes on a fresh Mac (most time is Homebrew install).

## What it installs

| # | Repo | Cloned to | Setup |
|---|---|---|---|
| 1 | [AvalonLotus](https://github.com/AvalonLotus/AvalonLotus) | `~/AvalonLotus` | (brand assets, just clone) |
| 2 | [AvalonLotus.com](https://github.com/AvalonLotus/AvalonLotus.com) | `~/AvalonLotus.com` | (just clone, no setup) |
| 3 | [Global-Finance-News](https://github.com/AvalonLotus/Global-Finance-News) | `~/Projects/Global-Finance-News` | `scripts/install-git-autosync.sh` — post-commit auto-push + 15-min auto-pull launchd daemon |
| 4 | [AvalonLotus-Vault](https://github.com/AvalonLotus/AvalonLotus-Vault) (Obsidian) | `~/Obsidian` | `./setup.sh` — fonts + Python markdown packages |
| 5 | [AvalonLotus-Skills](https://github.com/AvalonLotus/AvalonLotus-Skills) | `~/Skills` | (just clone, no setup) |

Prereqs (auto-installed if missing): Homebrew, git, jq.



## Baseline tools (auto-installed via Homebrew)

Installed before any repos are cloned, idempotent (skipped if already present):

**CLI formulae:** `gh`, `mas`

**GUI apps (casks):**
- GFN essentials: `docker`, `1password`, `1password-cli`
- Daily drivers: `google-chrome`, `visual-studio-code`, `obsidian`, `claude`
- Specialised: `obs`, `utm`, `codex`

To add/remove items, edit the `FORMULAE` / `CASKS` variables in `install.sh`.

## Adding a new repo

Edit the `REPOS` block at the top of `install.sh`:

```
<repo_url>|<local_path>|<setup_cmd>
```

Commit + push. Next time you (or another machine) runs `install.sh`, the new repo gets included.

## Idempotent

Safe to re-run anytime. Pulls latest of each repo, re-runs setup. Useful as a "sync everything" command.

## Why not Ansible / Nix / chezmoi

Three reasons:
1. **Zero-prereq bootstrapping** — a fresh Mac has bash + git. Anything else needs to be installed first, which defeats the "one command" goal.
2. **Personal scale** — ~5 repos, ~2 machines. The complexity overhead of a real config manager isn't worth it.
3. **Each repo owns its own setup** — `install-git-autosync.sh`, `setup.sh`, etc. live in their respective repos. This file just calls them. Easy to maintain.
