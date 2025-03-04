#!/bin/sh

ROOTFS_DIR=$(pwd)
RAM_DIR="$ROOTFS_DIR/ram"
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

case "$ARCH" in
  x86_64) ARCH_ALT=amd64 ;;
  aarch64) ARCH_ALT=arm64 ;;
  *)
    echo "Unsupported CPU architecture: ${ARCH}"
    exit 1
    ;;
esac

mkdir -p "$RAM_DIR"

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "███████╗██████╗ ███████╗███████╗██████╗  ██████╗  ██████╗ ████████╗
██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝
█████╗  ██████╔╝█████╗  █████╗  ██████╔╝██║   ██║██║   ██║   ██║   
██╔══╝  ██╔══██╗██╔══╝  ██╔══╝  ██╔══██╗██║   ██║██║   ██║   ██║   
██║     ██║  ██║███████╗███████╗██║  ██║╚██████╔╝╚██████╔╝   ██║   
╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   
                                                                   "
  echo "Fork - Made by KVM-i7"
  read -p "Do you want to install Ubuntu? (YES/no): " install_ubuntu
fi

case $install_ubuntu in
  [yY][eE][sS])
    ROOTFS_TAR="$RAM_DIR/rootfs.tar.gz"
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_TAR" \
      "https://cdn.kvm-i7.host/ubuntu-base-22.04.2-base-${ARCH_ALT}.tar.gz"

    if [ $? -ne 0 ] || [ ! -s "$ROOTFS_TAR" ]; then
      echo "Download failed or file is empty. Exiting."
      exit 1
    fi

    tar -xf "$ROOTFS_TAR" -C "$ROOTFS_DIR"
    if [ $? -ne 0 ]; then
      echo "Extraction failed. Exiting."
      exit 1
    fi
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  PROOT_BIN="$ROOTFS_DIR/usr/local/bin/proot"
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$PROOT_BIN" \
    "https://raw.githubusercontent.com/katy-the-kat/freeroot/main/proot-${ARCH}"

  if [ $? -ne 0 ] || [ ! -s "$PROOT_BIN" ]; then
    echo "proot download failed or file is empty. Exiting."
    exit 1
  fi

  chmod 755 "$PROOT_BIN"
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
  touch "$ROOTFS_DIR/.installed"
fi

CYAN='\e[0;36m'
RESET_COLOR='\e[0m'

display_gg() {
  echo -e ""
  echo -e "           ${CYAN}-----> Complete <----${RESET_COLOR}"
  echo -e ""
}

clear
display_gg

"$PROOT_BIN" \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /bin/sh
