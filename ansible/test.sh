#!/usr/bin/env bash
export LC_ALL="C.UTF-8"
dir=$(dirname -- "$( readlink -f -- "$0"; )";)
operating_systems=("ubuntu" "debian" "alpine")
# If AMD64, also test Arch Linux
[[ $(arch) == "x86_64" ]] && operating_systems+=("archlinux")

# If argument provided, test single OS
if [[ -n "$1" ]]
then
    printf '%s\0' "${operating_systems[@]}" | grep -q -F -x -z -- "$1" && operating_systems=("$1")
fi

echo "Operating systems that will be tested: ${operating_systems[@]}"
for os in "${operating_systems[@]}"
do
  echo "Testing: ${os}"
  set -ex
  docker build -q -t ansible-${os}-test -f ${dir}/Dockerfile --target ${os}-test ${dir} || printf "Error occurred on operating system: ${os}"
  mkdir -p /tmp/ansible
  docker run -i --rm -v /tmp/.ansible:/root/.ansible --privileged ansible-${os}-test
done
