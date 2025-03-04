#!/bin/bash

install_dev_dependencies() {
  # Instalação do SDKMAN, NVM, pip3, e configuração do virtualenvwrapper
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  sudo pip3 install virtualenvwrapper --break-system-packages

  # Configuração do virtualenvwrapper no .zshrc
  commands="
  export WORKON_HOME=\$HOME/.virtualenvs
  export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
  export VIRTUALENVWRAPPER_VIRTUALENV_ARGS=' -p /usr/bin/python3 '
  export PROJECT_HOME=\$HOME/Devel
  source /usr/local/bin/virtualenvwrapper.sh
  "

  SHELL_CONFIG=$HOME/.zshrc
  echo "$commands" >> "$SHELL_CONFIG"
  echo "Comandos adicionados ao final do arquivo $SHELL_CONFIG com sucesso."

  source "$SHELL_CONFIG"
  echo "Configurações carregadas com sucesso."


  echo "Instalando Node.js"
  nvm install 22.12.0
  echo "Instalando Java 21"
  sdk install java 21.0.5-zulu
}