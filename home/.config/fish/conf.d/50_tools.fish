set -q __fish_config_interactive; or return

# Disabled while testing Tide as the active Fish prompt.
# type -q starship; and starship init fish | source
functions -q enable_transience; and enable_transience
type -q zoxide; and zoxide init --cmd j fish | source
type -q fzf; and fzf --fish | source
