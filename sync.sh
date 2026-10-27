#!/bin/zsh
# Pull the live configs from this Mac into the repo, then show what changed.
# Run this after tweaking nvim/tmux/oh-my-posh, then commit and push.
#
# config/psmux/psmux.conf is Windows-only and edited by hand in the repo.

set -e
repo=${0:A:h}

rsync -a --delete --exclude .git ~/.config/nvim/ "$repo/config/nvim/"
rsync -a --delete ~/.config/tmux/ "$repo/config/tmux/"
mkdir -p "$repo/config/oh-my-posh"
cp ~/Documents/config/atomic.omp.json "$repo/config/oh-my-posh/atomic.omp.json"

git -C "$repo" status --short
