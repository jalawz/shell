#!/bin/bash

remove_snaps() {
    local distro=$1
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