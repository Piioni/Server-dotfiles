set -q __fish_config_interactive; or return

abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr --add --position anywhere --function expand_last_command !!
abbr g 'git'
abbr gs 'git status'
abbr v 'nvim'
