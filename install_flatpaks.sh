#!/bin/bash

install_flatpaks() {
  local distro=$1
  local install_cmd=$2
  shift 2
  local flatpak_apps=("$@")
  
    # Ativação do suporte ao Flatpak e AppImage
  if [ "$DISTRO" == "ubuntu" ]; then
    $install_cmd gnome-software gnome-software-plugin-flatpak flatpak libfuse2 -y
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  fi

  for app in "${flatpak_apps[@]}"; do
    echo "Instalando $app:"
    flatpak install flathub "$app" -y
  done

  sudo flatpak override --filesystem=$HOME/.themes
  sudo flatpak override --filesystem=$HOME/.local/share/icons
}