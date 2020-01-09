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
cd ~
HOMEPATH="$PWD"
SETACL=1
KERNELDOT=52

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

KernelToolchain(){
	cd "$HOMEPATH"
  	if [ -d toolchain ]; then
    		sudo rm -r toolchain
  	fi
  	# Download the toolchain to compile the kernel
  	Note "Downloading toolchain to compile the revised kernel"
  	# Thanks to http://wiki.espressobin.net/tiki-index.php?page=Build+From+Source+-+Toolchain
  	mkdir -p toolchain
  	cd toolchain
  	Note "Downloading Toolchain"
  	wget https://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-2/aarch64-linux-gnu/gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu.tar.xz
  	Note "Extracting Toolchain"
  	tar -xvf gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu.tar.xz
	
  	# Ensure the proper tools are installed
  	# Thanks to https://linux.com/tutorials/how-compile-linux-kernel-0
  	Note "Installing necessary software to build the kernel"
  	sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison -y
}

KernelDirMake(){
	# DELETES PREVIOUS KERNEL DIRECTORIES IF THEY EXIST AND CREATES COMPILE DIRECTORY
	# USAGE <kernel version>
	cd "$HOMEPATH"
	if [ -d kernel ]; then
		rm -r kernel
	fi
	mkdir -p "kernel/$1"
	cd "kernel/$1/"	
}

KernelClone(){
	# CLONES KERNEL REPOSITORY
	# REPO IS THE SAME FOR 4.4.8 AND 4.4.52
	Note "Cloning linux-marvell repository"
	git clone https://github.com/MarvellEmbeddedProcessors/linux-marvell .
}

KernelCompVars(){
	Note "Setting compiler variables"
	export ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-
}

KernelConfigBaseline(){
	# CREATES THE DEFAULT CONFIG FILE, AND ENABLES ACLS IF APPROPRIATE
	Note "Creating baseline configuration file"
  	make mvebu_v8_lsp_defconfig
	
	if [ "$SETACL" == 1 ]; then
		Note "Enabling ACLs in the config file"
  		sudo sed -i "s|# CONFIG_EXT3_FS_POSIX_ACL is not set|CONFIG_EXT3_FS_POSIX_ACL=y|" .config
  		sudo sed -i "s|# CONFIG_EXT4_FS_POSIX_ACL is not set|CONFIG_EXT4_FS_POSIX_ACL=y|" .config
	fi
}

# TODO:: Ask the user at the beginning of script if this is desired, or if defaults are ok
KernelCheckMenuConfig(){
	# SPAWNS THE MENUCONFIG DIALOG IF THE USER WISHES
	# make menuconfig
	return 0
}

KernelSetPath(){
	Note "Updating PATH to complete building the kernel"
	export PATH=$PATH:$HOMEPATH/toolchain/gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu/bin
}

KernelCompile(){
	Note "Compiling the kernel"
	make -j4
}

BuildKernel52(){
	# BUILDS KERNEL 4.4.52
	KernelToolchain
	
	KernelDirMake '4.4.52'
	
	KernelClone
	Note "Checking out repository"
	git checkout 6adee55d3e07e3cc99ec6248719aac042e58c5e6 -b espressobin-v7
	
	Note "Downloading kernel patches"
	wget -O ebin_v7_kernel_patches.zip http://wiki.espressobin.net/tiki-download_file.php?fileId=210
	Note "Unzipping patches"
	unzip ebin_v7_kernel_patches.zip
	Note "Applying patches"
	git am *.patch

	KernelCompVars
	KernelConfigBaseline
	KernelCheckMenuConfig
	KernelSetPath
}

BuildKernel8(){
	# BUILDS KERNEL VERSION 4.4.4
	KernelToolchain
	
	KernelDirMake '4.4.8'
	KernelClone

	Note "Checking out repository"
	git checkout linux-4.4.8-armada-17.02-espressobin

	KernelCompVars
	KernelConfigBaseline
	KernelCheckMenuConfig
	KernelSetPath
  	KernelCompile
}

QueryKernel(){
  if (YesNo("Build Kernel?", "Do you want to build the kernel?")); then
    BuildKernel52
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
  Note "Downloading CD Image"
  wget http://cdimage.ubuntu.com/releases/16.04.5/release/ubuntu-16.04.4-server-arm64.iso
  mkdir tmp
  Note "Mounting CD Image"
  sudo mount -o loop ubuntu-16.04.4-server-arm64.iso tmp/
  
  Note "Unsquashing CD Filesystem"
  sudo unsquashfs -d rootfs/ tmp/install/filesystem.squashfs

  Note "Making a couple of changes to the filesystem"
  sudo sed -i "s|root:x:0:0:root:/root:/bin/bash|root::0:0:root:/root:/bin/bash|" rootfs/etc/passwd

  Note "Enabling the USB serial port"
  sudo echo "ttyMV0" >> rootfs/etc/securetty

  Note "Transferring the kernel into the image"
  sudo cp "/home/michael/kernel/4.4.$KERNELDOT/arch/arm64/boot/Image" rootfs/boot/
  sudo cp "/home/michael/kernel/4.4.$KERNELDOT/arch/arm64/boot/dts/marvell/armada-3720-community.dtb" rootfs/boot/
  
  Note "Downloading ChameleonGeek initial EspressoBin configuration script"
  wget "https://raw.githubusercontent.com/ChameleonGeek/ebin-dc/master/ebin-config.sh"
  chmod +x ebin-config.sh
  sudo mv ebin-config.sh rootfs/root/ebin-config.sh

  Note "Creating Image File"
  sudo tar -cjvf rootfs.tar.bz2 -C rootfs/ .
  sudo mv rootfs.tar.bz2 /home/michael/
}

QueryImage(){
  if (YesNo("Build Image?", "Do you want to build the Ubuntu 16.04LTS Image?")); then
    BuildImage
  else
    return 0
  fi
}

QueryKernel()
QueryImage()
