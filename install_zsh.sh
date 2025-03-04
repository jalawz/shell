#!/bin/bash

install_zsh() {
  echo "Instalando Zsh..."
  eval $install_cmd zsh

  echo "Instalando Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  echo "Zsh e Oh My Zsh instalados com sucesso."
}