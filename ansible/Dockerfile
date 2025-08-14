# Ubuntu target
FROM docker.io/heywoodlh/systemd:ubuntu AS ubuntu-test

COPY server/files/scripts/install-ansible.sh /install-ansible.sh
RUN /install-ansible.sh

COPY . /ansible

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

ENTRYPOINT [ "/docker-entrypoint.sh", "/bin/bash", "/ansible/entrypoint.sh" ]

# Debian target
FROM docker.io/heywoodlh/systemd:debian AS debian-test

COPY server/files/scripts/install-ansible.sh /install-ansible.sh
RUN /install-ansible.sh

COPY . /ansible

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

ENTRYPOINT [ "/docker-entrypoint.sh", "/bin/bash", "/ansible/entrypoint.sh" ]

# "Unifi" target
FROM docker.io/heywoodlh/systemd:debian-bullseye AS unifi-test

COPY server/files/scripts/install-ansible.sh /install-ansible.sh
RUN /install-ansible.sh

COPY . /ansible

# Configure things we need to emulate that are provided in UDM
RUN apt update \
    && apt install -y syslog-ng \
    && rm -rf /var/lib/apt/lists/* \
    && touch /usr/bin/ubios-udapi-server

COPY server/files/etc/syslog-ng/docker.conf /etc/syslog-ng/conf.d/docker.conf

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

ENTRYPOINT [ "/docker-entrypoint.sh", "/bin/bash", "/ansible/entrypoint.sh" ]

# Arch Linux target
FROM docker.io/heywoodlh/systemd:archlinux AS archlinux-test

RUN pacman -Sy --noconfirm ansible python bash grep

COPY . /ansible

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

ENTRYPOINT [ "/docker-entrypoint.sh", "/bin/bash", "/ansible/entrypoint.sh" ]

# Alpine target
FROM docker.io/heywoodlh/openrc AS alpine-test

RUN apk --no-cache add ansible python3 bash grep

COPY . /ansible

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

ENTRYPOINT [ "/openrc.sh", "/bin/bash", "/ansible/entrypoint.sh" ]

# Fedora target
FROM docker.io/heywoodlh/systemd:fedora AS fedora-test

RUN dnf install -y ansible python3 bash grep

COPY . /ansible

ENV ANSIBLE_REMOTE_TMP="/tmp/ansible"

ENTRYPOINT [ "/docker-entrypoint.sh", "/bin/bash", "/ansible/entrypoint.sh" ]
