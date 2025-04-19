#!/bin/bash

source ./install_flatpaks.sh
source ./install_docker.sh
source ./install_zsh.sh
source ./install_dev_dependencies.sh
source ./remove_snaps.sh

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Distribuição não reconhecida."
    exit 1
fi

# Define o diretório CUSTOM_FOLDER baseado na distribuição
if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "zorin" || "$DISTRO" == "linuxmint" ]]; then
    CUSTOM_FOLDER="$PWD/resources"
    zip_file="ubuntu-desktop-settings.zip"
    settings_conf="Downloads/ubuntu-desktop-settings.conf"
    update_cmd="sudo apt update -y"
    install_cmd="sudo apt install -y"
    chrome_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
    conky_package="conky-all"
elif [[ "$DISTRO" == "fedora" ]]; then
    CUSTOM_FOLDER="$PWD/resources"
    zip_file="fedora-desktop-settings.zip"
    settings_conf="Downloads/fedora-desktop-settings.conf"
    update_cmd="sudo dnf update -y"
    install_cmd="sudo dnf install -y"
    chrome_url="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
    vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
    conky_package="conky"
else
    echo "Distribuição não suportada para este script."
    exit 1
fi


flatpak_apps=(
  io.github.getnf.embellish
  com.rtosta.zapzap
  com.obsproject.Studio
  org.duckstation.DuckStation
  org.ppsspp.PPSSPP
  com.heroicgameslauncher.hgl
  net.lutris.Lutris
  net.pcsx2.PCSX2
  com.discordapp.Discord
  org.telegram.desktop
  com.getpostman.Postman
  io.dbeaver.DBeaverCommunity
  com.jetbrains.PyCharm-Community
  com.jetbrains.IntelliJ-IDEA-Community
  org.gnome.meld
  io.httpie.Httpie
  page.kramo.Sly
  com.github.jeromerobert.pdfarranger
  com.zettlr.Zettlr
  com.github.johnfactotum.Foliate
)

# Função para baixar e instalar pacotes .deb ou .rpm
install_custom_package() {
    local pacote_url=$1

    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "zorin" || "$DISTRO" == "linuxmint" ]]; then
        # Para distribuições baseadas em Debian
        local download_path="/tmp/package_latest.deb"
        echo "Baixando e instalando o pacote (versão .deb) para $DISTRO..."
        wget -O "$download_path" "$pacote_url"
        sudo dpkg -i "$download_path"
        sudo apt-get -f install -y

        echo "Instalando extensões adicionais do gnome"
        sudo apt install gnome-tweaks
        sudo apt install gnome-extensions-app
        sudo apt install chrome-gnome-shell

    elif [[ "$DISTRO" == "fedora" ]]; then
        # Para distribuições baseadas em Fedora
        local download_path="/tmp/package_latest.rpm"
        echo "Baixando e instalando o pacote (versão .rpm) para $DISTRO..."
        wget -O "$download_path" "$pacote_url"
        sudo dnf install -y "$download_path"

        echo "Instalando extensões adicionais do gnome"
        sudo dnf install gnome-tweaks
        sudo dnf install gnome-extensions-app
        sudo dnf install chrome-gnome-shell
    else
        echo "Distribuição não suportada: $DISTRO"
        return 1
    fi

    # Verifica se a instalação foi bem-sucedida
    if [[ $? -eq 0 ]]; then
        echo "Pacote instalado com sucesso! $pacote_url"
        echo "Apagando arquivo baixado..."
        rm "$download_path"
    else
        echo "Erro na instalação do pacote."
    fi
}

install_dependencies() {

    eval $update_cmd
    echo "Instalando Chrome"
    install_custom_package $chrome_url
    echo "Instalando VS Code"
    install_custom_package $vscode_url

    echo "Instalando Brave Browser"
    curl -fsS https://dl.brave.com/install.sh | sh

    # GIT
    eval $install_cmd git
    git config --global user.name "Paulo Roberto Menezes"
    git config --global user.email paulomenezes.web@gmail.com
    git config --global init.defaultBranch main
    # CURL
    eval $install_cmd curl
    # PIP
    eval $install_cmd python3-pip

    # DOCKER
    echo "Installing Docker"
    install_docker
}



# Exemplo de chamada da função com a lista de aplicativos Flatpak

# Função para exibir o menu interativo
menu() {
  while true; do
    echo "=============================="
    echo "         MENU GRUB            "
    echo "=============================="
    echo "1) Instalar Dependencias Iniciais"
    echo "2) Instalar Flatpaks"
    echo "3) Instalar ZSH com Oh My ZSH"
    echo "4) Instalar Dependencias Dev"
    echo "5) Remover Snaps"
    echo "9) Reboot"
    echo "q) Sair"
    echo "=============================="
    read -p "Escolha uma opção: " option

    case $option in
      1)
        install_dependencies
        ;;
      2)
        install_flatpaks "$DISTRO" "$install_cmd" "${flatpak_apps[@]}"
        ;;
      3)
        install_zsh
        ;;
      4)
        install_dev_dependencies
        ;;
      5)
        remove_snaps "$DISTRO"
        ;;
      9)
        sudo reboot
        ;;
      q|Q)
        echo "Saindo..."
        break
        ;;
      *)
        echo "Opção inválida. Tente novamente."
        ;;
    esac
  done
}

# Executa o menu
menu