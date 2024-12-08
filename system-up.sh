#!/bin/bash

# Caminho do arquivo de configuração do GRUB
grub_config="/etc/default/grub"

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
  io.bassi.Amberol
  net.agalwood.Motrix
  com.rafaelmardojai.Blanket
  com.github.KRTirtho.Spotube
  com.mattjakeman.ExtensionManager
)

flatpak_apps_optional=(
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

install_flatpaks() {
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

configure_grub() {
  # Caminho do arquivo de configuração do GRUB
  grub_config="/etc/default/grub"
  if [[ -f "$grub_config" ]]; then
    if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub_config"; then
      sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi_backlight=native"/' "$grub_config"
    else
      echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi_backlight=native"' | sudo tee -a "$grub_config" >/dev/null
    fi
    
    # Determina o comando correto para atualizar o GRUB com base na distribuição
    if grep -qi fedora /etc/os-release; then
      sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    else
      sudo update-grub
    fi
    
    echo "Configuração do GRUB atualizada com sucesso."
  else
    echo "Arquivo de configuração do GRUB não encontrado em $grub_config."
  fi
}

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

remove_snaps() {
    # Verifica se a distribuição é Ubuntu
    if [[ "$DISTRO" == "ubuntu" ]]; then
      echo "Executando a remoção do Snap em uma distribuição Ubuntu..."
      
      # Remove pacotes Snap
      while [ "$(snap list | wc -l)" -gt 0 ]; do
          for snap in $(snap list | tail -n +2 | cut -d ' ' -f 1); do
              snap remove --purge "$snap"
          done
      done

      systemctl stop snapd
      systemctl disable snapd
      systemctl mask snapd
      apt purge snapd -y
      rm -rf /snap /var/lib/snapd
      for userpath in /home/*; do
          rm -rf "$userpath/snap"
      done

      # Configura o APT para evitar o Snap
      echo "Package: snapd
      Pin: release a=*
      Pin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref

      echo "Snap removido com sucesso."
    else
      echo "Esta distro é: $DISTRO"
      echo "Distribuição não é Ubuntu. Nenhuma ação foi executada."
    fi
}

install_zsh() {
  echo "Instalando Zsh..."
  eval $install_cmd zsh

  echo "Instalando Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  echo "Zsh e Oh My Zsh instalados com sucesso."
}

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

    elif [[ "$DISTRO" == "fedora" ]]; then
        # Para distribuições baseadas em Fedora
        local download_path="/tmp/package_latest.rpm"
        echo "Baixando e instalando o pacote (versão .rpm) para $DISTRO..."
        wget -O "$download_path" "$pacote_url"
        sudo dnf install -y "$download_path"
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
    configure_grub
    install_custom_package $chrome_url
    install_custom_package $vscode_url

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

  # Defina o arquivo de configuração do shell
  SHELL_CONFIG=$HOME/.zshrc
  if [ ! -f "$SHELL_CONFIG" ]; then
    SHELL_CONFIG=$HOME/.bashrc
  fi

  # Verifica se o arquivo de configuração existe
  if [ -f "$SHELL_CONFIG" ]; then
    # Verifica se a linha já está no arquivo
    if ! grep -q "export WORKON_HOME=\$HOME/.virtualenvs" "$SHELL_CONFIG"; then
      echo "$commands" >> "$SHELL_CONFIG"
      echo "Comandos adicionados ao final do arquivo $SHELL_CONFIG com sucesso."
    fi
    # Aplica as alterações
    source "$SHELL_CONFIG"
    echo "Configurações carregadas com sucesso."
  else
    echo "Nenhum arquivo de configuração (.zshrc ou .bashrc) foi encontrado!"
  fi

  echo "Instalando Node.js"
  nvm install 22.12.0
  echo "Instalando Java 21"
  sdk install java 21.0.5-zulu
}

customize_gnome() {
    if [ "$DISTRO" == "ubuntu" ]; then
      sudo apt update && sudo apt dist-upgrade -y
      eval "$install_cmd" curl \
      gdebi \
      rsync \
      nautilus-admin \
      nautilus-extension-gnome-terminal \
      sassc \
      gnome-tweaks \
      gnome-shell-extension-manager
    elif [ "$DISTRO" == "fedora" ]; then
      eval "$update_cmd"
      eval "$install_cmd" rpm-ostree
      sudo dnf copr enable tomaszgasior/mushrooms -y
      sudo dnf copr enable konimex/neofetch fedora-rawhide-x86_64 -y
      sudo dnf install nautilus-admin -y
      eval "$install_cmd" curl \
      rsync \
      sassc \
      gnome-tweaks
    fi

    # Instalação da extensão do Gnome
    unzip -o "$CUSTOM_FOLDER/gnome-extensions.zip" -d $HOME/.local/share/gnome-shell/

    # Instalação do tema GTK
    mkdir -p $HOME/.themes
    unzip -o "$CUSTOM_FOLDER/GTK-Themes.zip" -d $HOME/.themes
    mkdir -p $HOME/.config/gtk-4.0
    ln -sf $HOME/.themes/Orchis-Dark/gtk4.0/{assets,gtk.css,gtk-dark.css} $HOME/.config/gtk-4.0/

    # Instalação dos temas de ícones e cursores
    mkdir -p $HOME/.local/share/icons
    unzip -o "$CUSTOM_FOLDER/icon-themes.zip" -d $HOME/.local/share/icons
    mkdir -p $HOME/.icons
    unzip -o "$CUSTOM_FOLDER/cursors-theme.zip" -d $HOME/.icons/

    # Instalação das fontes e papéis de parede
    unzip -o "$CUSTOM_FOLDER/fonts.zip" -d $HOME/.local/share
    sudo unzip -o "$CUSTOM_FOLDER/wallpapers.zip" -d /usr/share/backgrounds/

    # Instalação do widget Conky
    eval "$install_cmd $conky_package jq curl playerctl -y"
    unzip -o "$CUSTOM_FOLDER/conky-config.zip" -d $HOME/.config/

    # Instalação do Cava e NeoFetch
    $install_cmd cava
    unzip -o "$CUSTOM_FOLDER/cava-config.zip" -d $HOME/.config/
    $install_cmd neofetch
    unzip -o "$CUSTOM_FOLDER/neofetch-config.zip" -d $HOME/.config/

    install_flatpaks "${flatpak_apps[@]}"

    # Instalação de aplicativos Gnome
    $install_cmd gnome-weather \
    gnome-maps \
    gnome-audio \
    gnome-calendar \
    gnome-clocks \
    gnome-connections \
    gnome-console \
    gnome-contacts \
    gnome-music \
    vlc \
    gnome-shell-pomodoro

    if [[ "$DISTRO" == "ubuntu" ]]; then
        # Instalação e mudança do tema Plymouth para Ubuntu
        sudo apt install plymouth -y
        sudo unzip -o "$CUSTOM_FOLDER/plymouth-theme.zip" -d /usr/share/plymouth/themes

        sudo update-alternatives --install \
            /usr/share/plymouth/themes/default.plymouth default.plymouth \
            /usr/share/plymouth/themes/hexagon_dots/hexagon_dots.plymouth 100

        sudo update-alternatives --config default.plymouth # Escolha o número 2
        sudo update-initramfs -u
    elif [[ "$DISTRO" == "fedora" ]]; then
        # Instalação e mudança do tema Plymouth para Fedora
        sudo dnf install plymouth -y
        sudo dnf install plymouth-plugin-script -y
        sudo unzip -o "$CUSTOM_FOLDER/plymouth-theme.zip" -d /usr/share/plymouth/themes
        sudo plymouth-set-default-theme -R hexagon_dots
    fi


    # Aplicação de configurações do Gnome Shell para Fedora
    unzip "$CUSTOM_FOLDER/$zip_file" -d "$HOME/Downloads"
    dconf load / < "$HOME/$settings_conf"
}

install_all() {
  install_dependencies
  install_dev_dependencies
  install_flatpaks "${flatpak_apps_optional[@]}"
  eval "$install_cmd tlp tlp-rdw"
  sudo systemctl enable tlp
  sudo systemctl start tlp
  eval "$install_cmd powertop"
  sudo powertop --auto-tune
}

# Exemplo de chamada da função com a lista de aplicativos Flatpak

# Função para exibir o menu interativo
menu() {
  while true; do
    echo "=============================="
    echo "         MENU GRUB            "
    echo "=============================="
    echo "1) Instalar Dependencias Iniciais"
    echo "2) Remover Snaps Ubuntu"
    echo "3) Instalar Flatpaks Opcionais"
    echo "4) Instalar ZSH com Oh My ZSH"
    echo "5) Customizar Gnome"
    echo "6) Instalar Dependencias Dev"
    echo "7) Instalar Todas as Dependencias"
    echo "8) Reboot"
    echo "q) Sair"
    echo "=============================="
    read -p "Escolha uma opção: " option

    case $option in
      1)
        install_dependencies
        ;;
      2)
        remove_snaps
        ;;
      3)
        install_flatpaks "${flatpak_apps_optional[@]}"
        ;;
      4)
        install_zsh
        ;;
      5)
        customize_gnome
        ;;
      6)
        install_dev_dependencies
        ;;
      7)
        install_all
        ;;
      8)
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