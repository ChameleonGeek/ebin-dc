#!/bin/bash
# ==============================================================================
# ==============================================================================
# 
#                             EspressoBin Config
#                             Domain Controller
#                              January, 2020
#                    https://github.com/ChameleonGeek/ebin-dc
# 
#     This script performs the basic software installation and configuration 
# necessary to make a new EspressoBin v7 into an Ubuntu 16.04 LTS Domain 
# Controller
# 
# https://github.com/ChameleonGeek/ebin-dc/README.md
# 
# ==============================================================================
# ==============================================================================
# ======================================
#               VARIABLES
# ======================================
# COLORS FOR CLEARER NOTIFICATIONS
BLU='\033[1;34m'
GRN='\033[1;32m'
NC='\033[0m' # No Color
RED='\033[1;31m'
YEL='\033[1;33m'

# ======================================
#   BASIC USER INTERACTION FUNCTIONS
# ======================================
Note(){
	echo "${GRN}$1${NC}"
    
}

Splash(){ # Alerts user of major steps in the configuration process
	# Usage: Splash <display text>
	title="$1"
	clear
	echo "${GRN}=============================================================================="
	echo "=============================================================================="
	printf "%*s\n" $(((${#title}+80)/2)) "$title"
	echo "=============================================================================="
	echo "==============================================================================${NC}"
}

Query(){ # Uses whiptail to ask user for input
    # Usage: Query <default value> <whiptail title> <prompt>
    retval=$(whiptail --title "$2" --inputbox "$3" 8 78 "$1" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ "$exitstatus" = "0" ]; then
	    echo "$retval"
	else
	    echo ""
	fi
}

YesNo(){ # Uses whiptail to ask yes/no questions
    # Usage: YesNo <whiptail title> <prompt>
    if (whiptail --title "$1" --yesno "$2" 8 78 3>&1 1>&2 2>&3) then
        echo "1"
    else
        echo "0"
    fi
}

varUC(){
	echo "$1" | tr '[a-z]' '[A-Z]'
}

varLC(){
	echo "$1" | tr '[A-Z]' '[a-z]'
}

BuildKernel(){
  cd ~
  if [ -d toolchain ]; then
    sudo rm -r toolchain
  fi
  # Download the toolchain to compile the kernel
  Note("Downloading toolchain to compile the revised kernel")
  # From http://wiki.espressobin.net/tiki-index.php?page=Build+From+Source+-+Toolchain
  mkdir -p toolchain
  cd toolchain
  Note("Downloading Toolchain")
  wget https://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-2/aarch64-linux-gnu/gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu.tar.xz
  Note("Extracting Toolchain")
  tar -xvf gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu.tar.xz

  # Ensure the proper tools are installed
  Note("Installing necessary software to build the kernel")
  sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison -y

  if [ -d kernel ]; then
    sudo rm -r kernel
  fi
  mkdir -p kernel/4.4.8
  cd kernel/4.4.8/
  Note("Cloning linux-marvell repository")
  git clone https://github.com/MarvellEmbeddedProcessors/linux-marvell .
  Note("Checking out repositary")(
  git checkout linux-4.4.8-armada-17.02-espressobin

  Note("Setting compiler variables")
  export ARCH=arm64
  export CROSS_COMPILE=aarch64-linux-gnu-

  Note("Creating baseline configuration file")
  make mvebu_v8_lsp_defconfig
  
  # TODO:: Update .config with POSIX ACLs enabled for EXT3 and EXT4 filesystems
  Note("Enabling ACLs in the config file")
  sed -i "s|||" .config
  sed -i "s|||" .config
  
  Note("Updating PATH to complete building the kernel")
  export PATH=$PATH:$HOME/toolchain/gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu/bin
  
  Note("Compiling the kernel")
  make -j4

}

QueryKernel(){
  if (YesNo("Build Kernel?", "Do you want to build the kernel?")); then
    BuildKernel()
  else
    return 0
  fi
}

BuildImage(){
  cd ~
  if [ -d ubuntu_16.04 ]; then
    sudo rm -r ubuntu_16.04
  fi
  mkdir -p ubuntu_16.04
  cd ubuntu_16.04
  Note("Downloading CD Image")
  wget http://cdimage.ubuntu.com/releases/16.04.5/release/ubuntu-16.04.4-server-arm64.iso
  mkdir tmp
  Note("Mounting CD Image")
  sudo mount -o loop ubuntu-16.04.4-server-arm64.iso tmp/
  
  Note("Unsquashing CD Filesystem")
  sudo unsquashfs -d rootfs/ tmp/install/filesystem.squashfs

  Note("Making a couple of changes to the filesystem")
  sudo sed -i "s|root:x:0:0:root:/root:/bin/bash|root::0:0:root:/root:/bin/bash|" rootfs/etc/passwd

  Note("Enabling the USB serial port")
$ sudo vim rootfs/etc/securetty
[...]
# Serial Console for MIPS Swarm
duart0
duart1

# s390 and s390x ports in LPAR mode
ttysclp0
ttyMV0
  
  Note("Transferring the kernel into the image")
  sudo cp ~/kernel/4.4.8/arch/arm64/boot/Image rootfs/boot/
  sudo cp ~/kernel/4.4.8/arch/arm64/boot/dts/marvell/armada-3720-community.dtb rootfs/boot/

  Note("")
$ sudo tar -cjvf rootfs.tar.bz2 -C rootfs/ .
}

QueryImage(){

}

QueryKernel()
QueryImage()
