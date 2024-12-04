This is a patching of ttyd to support nerd fonts.

# Build and run

```
nix run .#gen
git add html
nix run .# -- -W -t fontSize=16 -t fontFamily="JetBrains" -p 8000 /bin/zsh
```

# Generate patch

This is mostly copying in changes from this branch: <https://github.com/metorm/ttyd-nerd-font>

Generate a patch file like so:

```
git clone https://github.com/tsl0922/ttyd /tmp/ttyd

# make changes in /tmp/ttyd

git -C /tmp/ttyd diff > ttyd.patch
```
