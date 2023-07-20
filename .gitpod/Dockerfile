# You can find the new timestamped tags here: https://hub.docker.com/r/gitpod/workspace-full/tags
FROM gitpod/workspace-full:2023-07-17-21-17-42

# Copy flakes to /flakes
RUN sudo git clone https://github.com/heywoodlh/flakes /flakes \
    && sudo chown -R gitpod:gitpod /flakes

# Install nix
RUN curl -L https://nixos.org/nix/install | bash -s -- --no-daemon --yes

# Configure nix
COPY .gitpod/nix.conf /home/gitpod/.config/nix/nix.conf

# Install vim
RUN /home/gitpod/.nix-profile/bin/nix profile install /flakes/vim#
