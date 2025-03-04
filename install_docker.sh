#!/bin/bash

install_docker() {
  if [[ "$DISTRO" == "fedora" ]]; then
    echo "Removendo pacotes Docker no Fedora..."
    sudo dnf remove docker \
      docker-client \
      docker-client-latest \
      docker-common \
      docker-latest \
      docker-latest-logrotate \
      docker-logrotate \
      docker-selinux \
      docker-engine-selinux \
      docker-engine
  else
    echo "Removendo pacotes Docker em distribuição baseada em Ubuntu..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
      sudo apt-get remove -y $pkg
    done
  fi

  # Instalação de certificados para gerenciar repositórios
  eval $install_cmd ca-certificates curl

  # Configuração do repositório Docker
  if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "zorin" ]]; then
    # Adiciona o repositório para Ubuntu/Zorin
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    eval "$update_cmd"
  elif [[ "$DISTRO" == "linuxmint" ]]; then
    # Adiciona o repositório para Linux Mint
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    eval "$update_cmd"
  elif [[ "$DISTRO" == "fedora" ]]; then
    # Adiciona o repositório para Fedora
    sudo dnf -y install dnf-plugins-core
    sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  fi

  # Instalação do Docker
  if [[ "$DISTRO" == "fedora" ]]; then
    eval $install_cmd docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  else
    eval $install_cmd docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  # Adiciona o usuário ao grupo Docker
  sudo groupadd docker
  sudo usermod -aG docker "$USER"

  if [[ "$DISTRO" == "fedora" ]]; then
    sudo systemctl enable docker
  fi
}