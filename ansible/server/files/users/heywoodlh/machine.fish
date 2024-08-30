alias ansible-switch 'nix run \"github:heywoodlh/flakes/$(git ls-remote https://github.com/heywoodlh/flakes | head -1 | awk \'{print $1}\')?dir=ansible#server\"'
