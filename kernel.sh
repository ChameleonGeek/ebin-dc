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
#	This script has been developed and tested using Ubuntu 18.04.1.  Other
# system configurations may result in errors.
#
# 	View https://github.com/ChameleonGeek/ebin-dc/README.md for the purpose
# and details regarding this script
#
# ==============================================================================
# ==============================================================================
cd ~
HOMEPATH="$PWD"		# Manages the home directory for the user for flexible file management
SETACL=1					# Specifies whether ACLs should be nabled in the kernel
KERNELDOT=52			# Holds the selected kernel version
KERNELEMAIL='me@gmail.com'	# User email needed by Git in order to compile the kernel
KERNELUSERNAME='espressobin developer'	# User name needed by Git in order to compile the kernel
KERNELBUILT=0			# Flag identifying if the kernel has been built
OSBUILT=0					# Flag identifying if the Ubuntu OS Image has been built with kernel
REMDIRPATH=""			# Removable drive path for installing onto SD card

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
	echo -e "${GRN}$1${NC}"
}

Splash(){ # Alerts user of major steps in the configuration process
	# Usage: Splash <display text>
	title="$1"
	clear
	echo -e "${GRN}=============================================================================="
	echo "=============================================================================="
	printf "%*s\n" $(((${#title}+80)/2)) "$title"
	echo "=============================================================================="
	echo -e "==============================================================================${NC}"
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

RadioKernelVersions(){
	TITLE="Kernel Version"
	PROMPT="Select the kernel version to compile"
	retval="$(whiptail --title "$TITLE" --radiolist "$PROMPT" 20 78 4 \
		"8" "Version 4.4.8" OFF \
		"52" "Version 4.4.52" ON 3>&1 1>&2 2>&3)"
	KERNELDOT="$retval"
}

WhipNotify(){ # Uses whiptail to notify the user of important information.  Waits for the user to OK
	# Usage: WhipNotify <title> <message>
	whiptail --title "$1" --msgbox "$2" 8 78
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

KernelUserInfo(){
	KERNELUSERNAME="$(Query "" "Git User Name" "Git needs your name to compile the kernel")"
	KERNELEMAIL="$(Query "" "Git Email Address" "Git needs your email address to compile the kernel")"
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

KernelPatchIdentify(){
	git config --global user.name "$KERNELUSERNAME"
	git config --global user.email "$KERNELEMAIL"
}

OSImagePathQuery(){
	# Read the list of attached drives into an array
	readarray -t DEVICES <<< "$(lsblk | grep ─sd)"

	TITLE="'Select Drive'"
	PROMPT="'Select the drive the EspressoBin boot image should be installed on'"
	whiptail_args=(--title "$TITLE" --radiolist "$PROMPT" 10 80 "${#DEVICES[@]}")

	for device in "${DEVICES[@]}"; do
		i+=1
		drvid="${device:2:4}"
		#echo "DRIVE $i: $drvid"
		whiptail_args+=( "$drvid" "'${device:0:60}'" "OFF")
	done

  # Query which partition the image should be installed on and save to variable
	REMDIRPATH="$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)"
}


BuildKernel52(){
	# BUILDS KERNEL 4.4.52
	WhipNotify "Kernel Building and Configuration Script" "Do you want to build the 4.4.52 Kernel?\n\nThis process may take as long as an hour to complete."
	KernelUserInfo
	KernelToolchain

	KernelDirMake '4.4.52'
	KernelPatchIdentify
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
	KernelCompile
	KERNELBUILT=1
}

BuildKernel8(){
	# BUILDS KERNEL VERSION 4.4.4
	WhipNotify "Kernel Building and Configuration Script" "Do you want to build the 4.4.8 Kernel?\n\nThis process may take as long as an hour to complete."
	KernelUserInfo
	KernelToolchain

	KernelDirMake '4.4.8'
	KernelPatchIdentify
	KernelClone

	Note "Checking out repository"
	git checkout linux-4.4.8-armada-17.02-espressobin

	KernelCompVars
	KernelConfigBaseline
	KernelCheckMenuConfig
	KernelSetPath
	KernelCompile
	KERNELBUILT=1
}

QueryKernel(){
	if [ "$(YesNo 'Build Kernel?', 'Do you want to build the kernel?')" == "0" ]; then
		return 0
	fi

	RadioKernelVersions
	case "$KERNELDOT" in
		"52")
			BuildKernel52
			;;
		"8")
			BuildKernel8
			;;
	esac
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
	sudo cp "$HOMEPATH/kernel/4.4.$KERNELDOT/arch/arm64/boot/Image" rootfs/boot/
	sudo cp "$HOMEPATH/kernel/4.4.$KERNELDOT/arch/arm64/boot/dts/marvell/armada-3720-community.dtb" rootfs/boot/

	Note "Downloading ChameleonGeek initial EspressoBin configuration script"
	wget "https://raw.githubusercontent.com/ChameleonGeek/ebin-dc/master/ebin-config.sh"
	chmod +x ebin-config.sh
	sudo mv ebin-config.sh rootfs/root/ebin-config.sh

	Note "Creating Image File"
	sudo tar -cjvf rootfs.tar.bz2 -C rootfs/ .
	sudo mv rootfs.tar.bz2 "$HOMEPATH/"
	OSBUILT=1
}

QueryImage(){
	if [ "$(YesNo 'Build Image?', 'Do you want to build the Ubuntu 16.04LTS Image?')" == "1" ]; then
		BuildImage
	else
		return 0
	fi
}

QueryDriveMove(){
	if [ "$OSBUILT" == "0" ]; then
		return 0
	fi
	if [ "$(YesNo 'Image Drive?' 'Do you want to load the image onto a removable drive?')" == "1" ]; then
		DriveImage
	else
		return 0
	fi
}


DriveImage(){
	OSImagePathQuery
	# REMDIRPATH
	REMDIRPATH="/dev/$REMDIRPATH"
	if [ "$(YesNo "Image Drive?" "You selected $REMDIRPATH as the partition to install the OS image.  This will reformat the drive.  Do you want to continue?")" == "0" ]; then
		return 0
	fi

	cd "$HOMEPATH"
	DEVICEPATH="$REMDIRPATH"

	Note "The drive must be unmounted"
	sudo umount "${DEVICEPATH}"

	Note "Formatting the drive"
	sudo mkfs -t ext4 "${DEVICEPATH}"

	Note "Mounting the newly formatted drive"
	sudo mkdir /ebincard
	sudo mount "${DEVICEPATH}" /ebincard
	cd /ebincard

	Note "Extracting the OS onto the drive"
	sudo tar -xvf "$HOMEPATH/rootfs.tar.bz2"

	cd "$HOMEPATH"
	sudo umount /ebincard
	sudo rm -rf /ebincard

	Note "Drive has been prepped and is safe to disconnect."
}

ProcessManage(){
	QueryKernel
	QueryImage
	QueryDriveMove
}

ProcessManage
