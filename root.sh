#!/bin/sh

ROOTFS_DIR=$(pwd)
RAM_DIR="$ROOTFS_DIR/ram"
PROOT_BIN="$ROOTFS_DIR/usr/local/bin/proot"
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
  echo -e "_ _  _ ____ ___ ____ _    _    ____ ____ 
| |\ | [__   |  |__| |    |    |___ |__/ 
| | \| ___]  |  |  | |___ |___ |___ |  \ "
  echo -e
  echo -e "Start installing ubuntu 22.04?"
  read -p "(y/n) > " install_ubuntu
fi

case $install_ubuntu in
  yes|y)
    ROOTFS_TAR="$ROOTFS_DIR/${ARCH_ALT}.tar.gz"
    if [ -f "$ROOTFS_TAR" ]; then
      echo "----------------------------"
      echo "Found local file."
    else
      echo "Local file not found. Downloading ${ARCH_ALT}.tar.gz..."
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_TAR" \
        "https://github.com/katy-the-kat/freeroot/raw/refs/heads/main/${ARCH_ALT}.tar.gz"

      if [ $? -ne 0 ] || [ ! -s "$ROOTFS_TAR" ]; then
        echo "Download failed or file is empty. Exiting."
        exit 1
      fi
    fi
    echo "Extracting rootfs..."
    tar -xf "$ROOTFS_TAR" -C "$ROOTFS_DIR"
    if [ $? -ne 0 ]; then
      echo "Extraction failed. Exiting."
      exit 1
    fi
    ;;
  *)
    ;;
esac

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  PROOT_BIN="$ROOTFS_DIR/usr/local/bin/proot"
  if [ -f "proot-${ARCH}" ]; then
    echo "----------------------------"
    echo "Found local binary."
    mv proot-${ARCH} $ROOTFS_DIR/usr/local/bin/proot
    chmod +x $ROOTFS_DIR/usr/local/bin/proot
  else
    echo "Did not find binary, Downloading binary."
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$PROOT_BIN" \
      "https://raw.githubusercontent.com/katy-the-kat/freeroot/main/proot-${ARCH}"

    if [ $? -ne 0 ] || [ ! -s "$PROOT_BIN" ]; then
      echo "binary download failed or file is empty. Exiting."
      exit 1
    fi
    chmod 755 "$PROOT_BIN"
  fi
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
  touch "$ROOTFS_DIR/.installed"
  echo "----------------------------"
fi

display_gg() {
  echo -e "____ _  _ ____ _    _       ____ ___ ____ ____ ___ ____ ___  
[__  |__| |___ |    |       [__   |  |__| |__/  |  |___ |  \ 
___] |  | |___ |___ |___    ___]  |  |  | |  \  |  |___ |__/ 
                                                             "
  echo -e "Do whatever you want! Make sure to join discord.gg/kvm!"
}

display_gg

"$PROOT_BIN" \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /bin/sh
