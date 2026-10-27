#!/bin/zsh
# Git segment for the tmux status bar, coloured like atomic's git segment.
# Prints the powerline transition from the orange path segment into the
# purple command segment, with a git pill in between when inside a repo.

orange='#FF9248' purple='#83769c'
sep=$''

cd "$1" 2>/dev/null || { print -n "#[fg=$orange,bg=$purple]$sep"; exit }
st=$(git status --porcelain=v2 --branch 2>/dev/null) || { print -n "#[fg=$orange,bg=$purple]$sep"; exit }

branch='' ahead=0 behind=0 work=0 staged=0
for line in ${(f)st}; do
  case $line in
    '# branch.head '*) branch=${line#\# branch.head } ;;
    '# branch.oid '*)  oid=${${line#\# branch.oid }[1,7]} ;;
    '# branch.ab '*)   ab=(${=line#\# branch.ab }); ahead=${ab[1]#+}; behind=${ab[2]#-} ;;
    '? '*)             (( work++ )) ;;
    [12u]' '*)
      xy=${line[3,4]}
      [[ ${xy[1]} != . ]] && (( staged++ ))
      [[ ${xy[2]} != . ]] && (( work++ )) ;;
  esac
done
[[ $branch == '(detached)' ]] && branch=$oid

# Background follows atomic's background_templates order
bg='#FFFB38'
(( work || staged )) && bg='#ffeb95'
if (( ahead && behind )); then bg='#c5e478'
elif (( ahead || behind )); then bg='#C792EA'; fi

icon=$''
[[ $(git remote get-url origin 2>/dev/null) == *github* ]] && icon=$' '

out=" $icon $branch"
(( ahead ))  && out+=" ↑$ahead"
(( behind )) && out+=" ↓$behind"
(( work ))   && out+=$'  '$work
(( work && staged )) && out+=' |'
(( staged )) && out+="#[fg=#ef5350]"$'  '"$staged#[fg=#011627]"

print -n "#[fg=$orange,bg=$bg]$sep#[fg=#011627,bg=$bg]$out #[fg=$bg,bg=$purple]$sep"
