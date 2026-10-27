# dotfiles

My terminal setup: an [oh-my-posh](https://ohmyposh.dev) **atomic** prompt, a matching
tmux / [psmux](https://github.com/psmux/psmux) status bar (at the top), and
[NvChad](https://nvchad.com).

```
config/
  nvim/            NvChad config          -> ~/.config/nvim  |  %LOCALAPPDATA%\nvim
  tmux/            tmux theme + scripts   -> ~/.config/tmux  (macOS/Linux)
  psmux/psmux.conf psmux theme            -> ~\.psmux.conf   (Windows)
  oh-my-posh/      atomic prompt theme    -> ~/.config/oh-my-posh/atomic.omp.json
install.ps1        Windows installer
sync.sh            copy this Mac's live configs into the repo
```

## Install on Windows

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/WillJackson99/dotfiles/main/install.ps1 | iex
```

This:

1. clones the repo to `~\dotfiles` (or pulls it if it's already there)
2. installs Git, Neovim, oh-my-posh, psmux, ripgrep and zig with winget
3. installs FiraCode Nerd Font and sets it as the Windows Terminal font
4. copies the configs into place, backing up anything already there as `*.bak-<timestamp>`
5. adds the oh-my-posh atomic prompt to both Windows PowerShell and PowerShell 7 profiles
6. installs the NvChad plugins

Then open a new terminal and run `psmux` / `nvim`. Re-run the same command any
time to update.

Options (`-SkipPackages`, `-SkipFont`, `-SkipPlugins`, `-CloneDir <path>`):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/WillJackson99/dotfiles/main/install.ps1))) -SkipFont
```

From a local clone: `powershell -ExecutionPolicy Bypass -File .\install.ps1`.

## Updating the repo from the Mac

```sh
./sync.sh          # copies ~/.config/nvim, ~/.config/tmux and the omp theme in
git add -A && git commit -m "Update configs" && git push
```

`config/psmux/psmux.conf` is the Windows version of the tmux theme. It's edited by
hand here, so mirror any colour/layout changes from `config/tmux/tmux.conf`.
psmux doesn't document `#(command)` status segments, so the Windows bar has no live
git or battery pills.
