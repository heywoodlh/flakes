# Ubuntu target
FROM docker.io/heywoodlh/systemd:ubuntu AS ubuntu-test
RUN apt update \
    && apt install -y pipx \
    && rm -rf /var/lib/apt/lists/*

RUN pipx ensurepath && pipx install --include-deps ansible

COPY . /ansible

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

CMD [ "/bin/bash", "/ansible/entrypoint.sh" ]

# Debian target
FROM docker.io/heywoodlh/systemd:debian AS debian-test

RUN apt update \
    && apt install -y pipx \
    && rm -rf /var/lib/apt/lists/*

RUN pipx ensurepath && pipx install --include-deps ansible

COPY . /ansible

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

CMD [ "/bin/bash", "/ansible/entrypoint.sh" ]

# Arch Linux target
FROM docker.io/heywoodlh/systemd:archlinux AS archlinux-test

RUN pacman -Sy --noconfirm ansible python

COPY . /ansible

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

CMD [ "/bin/bash", "/ansible/entrypoint.sh" ]

# Alpine target
FROM docker.io/heywoodlh/openrc AS alpine-test

RUN apk --no-cache add ansible python3

COPY . /ansible

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

CMD [ "/bin/ash", "/ansible/entrypoint.sh" ]
