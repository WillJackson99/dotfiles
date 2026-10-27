#!/bin/zsh
# Battery segment for the tmux status bar, coloured like atomic's battery
# segment. Sits between the grey OS pill and the blue time pill.

os='#b2bec3' time='#40c4ff'
sep=$''

batt=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%;[^;]*')
if [[ -z $batt ]]; then
  print -n "#[fg=$time,bg=$os]$sep"
  exit
fi

pct=${batt%%\%*}
state=${${batt#*; }## }

case $state in
  charging)            bg='#b8e994' icon=$' ' ;;
  discharging)         bg='#fff34e' icon=$' ' ;;
  charged|finishing*)  bg='#33DD2D' icon=$' ' ;;
  *)                   bg='#f36943' icon=$' ' ;;
esac

print -n "#[fg=$bg,bg=$os]$sep#[fg=#262626,bg=$bg] $icon$pct"$''" #[fg=$time,bg=$bg]$sep"
