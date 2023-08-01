fish_config theme choose Nord
fish_config prompt choose astronaut
set fish_greeting ''

# Colors
# Nord theme from https://github.com/nordtheme/nord/issues/102#issue-320528768
set fish_color_cwd 88c0d0
set fish_color_user d8dee9
set fish_color_operator 81a1c1
set fish_color_host 81a1c1
set fish_color_host_remote 81a1c1

# Use 1password SSH agent if it exists
if test -e $HOME/.1password/agent.sock
    set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
end
if test -e "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
end

# Add ~/bin to $PATH
if not contains $HOME/bin $PATH
    set -gx PATH $HOME/bin $PATH
end
