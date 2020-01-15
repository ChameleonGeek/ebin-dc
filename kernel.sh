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

# ======================================
#                              VARIABLES
# ======================================
# COLORS FOR CLEARER NOTIFICATIONS
BLU='\033[1;34m'
GRN='\033[1;32m'
NC='\033[0m' # No Color
RED='\033[1;31m'
YEL='\033[1;33m'

# USER SELECTED OPTIONS
ARCHIVEKERNEL=0                         # Flag identifying if the user wants to save the kernel for later use
ARCHIVEKERNELNAME=""                    # Holds the folder name the kernel should be archived in (if ARCHIVEKERNEL=1)
ARCHIVEOS=0                             # Flag identifying if the user wants to archive the OS image for later
ARCHIVEOSNAME=""                        # Holds the folder name the OS should be archived in (if ARCHIVEOS=1)
BUILDKERNEL=0				# Flag identifying if the kernel should be built
BUILDOS=0                               # Flag identifying if an OS should be built
KERNELBUILT=0                           # Flag identifying if the kernel has been built
KERNELDOT=52                            # Holds the selected kernel version
KERNELREUSE=0                           # Holds the kernel version to reuse in card image
KERNELEMAIL='me@gmail.com'              # User email needed by Git in order to compile the kernel
KERNELUSERNAME='espressobin developer'  # User name needed by Git in order to compile the kernel
OSBUILT=0                               # Flag identifying if the Ubuntu OS Image has been built with kernel
OSVERSION=0                             # Holds the selected OS Version
REMDIRPATH=""                           # Removable drive path for installing onto SD card
SETACL=1                                # Specifies whether ACLs should be nabled in the kernel
ORIG_PARTS=()                           # A list of all partitions available on system without the SD card attached
WDRIV_PARTS=()                          # A list of all partitions available on system WITH the SD card attached
IMAGE_DRIVE=0				# Flags if the user intends to image a drive
AVAIL_DRIVES=()                         # A list of attached drives (diff ORIG_PARTS, WDRIV_PARTS)
BOOT_PARTITION=""			# Partition used to boot this PC
DRIVE_TO_IMAGE=""                       # Partition to image with OS
# ======================================
#                      USER INTERACTIONS
# ======================================
Alert(){	echo -e "${RED}$1${NC}";	}

Note(){	echo -e "${GRN}$1${NC}";	}

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

BuildKernel(){
	echo "Building Kernel"
	if [ "$BUILDKERNEL" == "0" ]; then Note "User opted to not build a kernel"; return 0; fi
	MakeDirNE /espressobin/kernel 1

	Note "Personalizing Git"
	git config --global user.name "$KERNELUSERNAME"
	git config --global user.email "$KERNELEMAIL"

	Note "Checking Out Kernel Source"
	kdir="/espressobin/kernel/4.4.$KERNELDOT"
	DeletePrevDir "$kdir"
	MakeDirNE "$kdir" 1
	ln -s "$kdir" /espressobin/kbuild
#	cd /espressobin/kbuild

	# CLONES KERNEL REPOSITORY
	# REPO IS THE SAME FOR 4.4.8 AND 4.4.52
	Note "Cloning linux-marvell repository"
	git clone https://github.com/MarvellEmbeddedProcessors/linux-marvell .

	Note "Checking out repository"
	if [ "$KERNELDOT" == "8" ]; then
		git checkout linux-4.4.8-armada-17.02-espressobin
	fi

	if [ "$KERNELDOT" == "52" ]; then
		git checkout 6adee55d3e07e3cc99ec6248719aac042e58c5e6 -b espressobin-v7
		Note "Downloading kernel patches"
		wget -O ebin_v7_kernel_patches.zip http://wiki.espressobin.net/tiki-download_file.php?fileId=210
		Note "Unzipping patches"
		unzip ebin_v7_kernel_patches.zip
		Note "Applying patches"
		git am *.patch
	fi

	Note "Setting kernel compiler variables"
	export ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-

	Note "Creating baseline configuration file"
  	make mvebu_v8_lsp_defconfig

	if [ "$SETACL" == 1 ]; then
		Note "Enabling ACLs in the config file"
  		sudo sed -i "s|# CONFIG_EXT3_FS_POSIX_ACL is not set|CONFIG_EXT3_FS_POSIX_ACL=y|" .config
  		sudo sed -i "s|# CONFIG_EXT4_FS_POSIX_ACL is not set|CONFIG_EXT4_FS_POSIX_ACL=y|" .config
	fi

	# FUTURE IMPROVEMENT:  Handle spawning kernel config menu
	# KernelCheckMenuConfig

	Note "Updating PATH to complete building the kernel"
	export PATH=$PATH:/espressobin/toolchain/gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu/bin

	Note "Compiling the kernel"
	make -j4

	if [ "$ARCHIVEKERNEL" == "1" ]; then
		Note "Archiving kernel Image and dtb files"
		cp "/espressobin/kbuild/arch/arm64/boot/Image" /espressobin/karchive/
		cp "/espressobin/kbuild/arch/arm64/boot/dts/marvell/armada-3720-community.dtb" /espressobin/karchive/
	fi
	KERNELBUILT=1
}

BuildOS(){
	Note "Building OS"
	if [ "$OSVERSION" == "0" ]; then Note "User opted to not build an operating system"; return 0; fi
	MakeDirNE /espressobin/os_image 1

	if [ -e rootfs.tar.bz2 ]; then rm rootfs.tar.bz2; fi

	Note "Downloading OS ISO Image"
	case "$OSVERSION" in
		14)
			;;
		16)
			img="ubuntu-16.04.4-server-arm64.iso"
			imgurl="http://cdimage.ubuntu.com/releases/16.04.5/release/ubuntu-16.04.4-server-arm64.iso"
			;;
		18)
			img="ubuntu-18.04.3-server-arm64.iso"
			imgurl="http://cdimage.ubuntu.com/releases/18.04.3/release/ubuntu-18.04.3-server-arm64.iso"
			;;
	esac

	if ! [ -e "$img" ]; then
		Note "Downloading CD Image"
		wget "$imgurl"
	fi

	Note "Mounting CD Image"
	MakeDirNE tmp
	mount -o loop "$img" tmp/

	Note "Unsquashing CD Filesystem"
	unsquashfs -d rootfs/ tmp/install/filesystem.squashfs

	Note "Transferring the kernel into the image"
	cp "/espressobin/kbuild/arch/arm64/boot/Image" rootfs/boot/
	cp "/espressobin/kbuild/arch/arm64/boot/dts/marvell/armada-3720-community.dtb" rootfs/boot/

	Note "Making a couple of changes to the filesystem"
	sed -i "s|root:x:0:0:root:/root:/bin/bash|root::0:0:root:/root:/bin/bash|" rootfs/etc/passwd
	Note "Enabling the USB serial port"
	echo "ttyMV0" >> rootfs/etc/securetty

	Note "Adding ChameleonGeek preconfig script to root's home directory on image"
	if [ -e preconfig.sh ]; then rm preconfig.sh; fi
	wget "https://raw.githubusercontent.com/ChameleonGeek/ebin-dc/master/preconfig.sh"
	chmod +x preconfig.sh
	mv preconfig.sh rootfs/root/

	Note "Creating Image File"
	tar -cjvf rootfs.tar.bz2 -C rootfs/ .

	if [ "$ARCHIVEOS" == "1" ]; then
		Note "Archiving OS Image (rootfs.tar.bz2)"
		cp rootfs.tar.bz2 /espressobin/oarchive/
	fi

	umount tmp/
	OSBUILT=1
}

CheckDriveSpace(){
	BOOT_PARTITION="$(df /boot | grep /dev)"
	BOOT_SPACE=${BOOT_PARTITION:33:10}
	BOOT_SPACE="$(echo -e "$BOOT_SPACE" | tr -d '[:space:]')"
	BOOT_PARTITION="${BOOT_PARTITION:5:4}"
	echo "Boot Space:  ($BOOT_SPACE)"
	if [ 24000000 -gt $BOOT_SPACE ]; then
		Alert "There is not enough space on the boot drive to proceed."
		exit
	fi
}

MakeDirNE(){ # <path> <cd to>
	if ! [ -d "$1" ]; then mkdir -p "$1"; Note "Created Directory $1"; fi
	if [ "$2" == "1" ]; then cd "$1"; fi
}

UserIDDestDrive(){
	# Asks the user to select the drive to image.  
	# If none is selected, it asks again
	# If canceled, the script ends
	if [ "$IMAGE_DRIVE" == "0" ]; then return 0; fi

	DRIVEOPTS=()
	PART_COUNT=0
	for drive in "${AVAIL_DRIVES[@]}"; do
		#echo "SELECTING DRIVE"
		if [ "${drive:3:3}" != "${BOOT_PARTITION:0:3}" ]; then
			#echo "$drive"
			PART_COUNT+=1
			DRIVEOPTS+=("${drive:2:4}" "${drive:0:60}" "OFF")
		fi
	done

	if [ "$PART_COUNT" == "0" ]; then
		Alert "No valid drives detected.  Please try again."
		exit
	fi

	DRIVE_TO_IMAGE="$(whiptail --title "Image Partition" --radiolist "Select the drive to image" 10 80 "${#DRIVEOPTS[@]}" \
		"${DRIVEOPTS[@]}" 3>&1 1>&2 2>&3)"

	if [ "$?" = 1 ]; then
		clear
		Alert "User Canceled."
		exit
	fi

	if [ "$DRIVE_TO_IMAGE" == "" ]; then UserIDDestDrive; fi
	Note "You have selected $DRIVE_TO_IMAGE"
}

UserQuestions(){
	# Asks the user the questions needed to determine what tasks need to be performed

	if [ "$(YesNo "Image Drive?" "Do you want to extract an image to a drive (SD card)?")" == "1" ]; then
		IMAGE_DRIVE=1
		whiptail --title "Disconnect Drive" --msgbox "If the drive you want imaged is connected, please disconnect it now. Press Enter to continue." 8 78
		ReadAttachedPartitions 0
	fi

	# Connect the drive so that it can be detected
	if [ "$IMAGE_DRIVE" == "1" ]; then
		whiptail --title "Connect Drive" --msgbox "Connect the drive you want to image now. Press Enter to continue." 8 78
	fi

	# Create kernel?
	if [ "$(YesNo "Create Kernel?" "Do you want to build a kernel?")" == "1" ]; then
		BUILDKERNEL=1
		# Kernel Version
		KERNELDOT="$(whiptail --title "Kernel Version" --radiolist "Select the kernel version to build" 10 80 2 \
		"8" "Version 4.4.8" OFF "52" "Version 4.4.52" ON 3>&1 1>&2 2>&3)"

		# Git personalization
		KERNELEMAIL="$(Query "" "Email Address" "Git requires your email address in order to compile the kernel")"
		KERNELUSERNAME="$(Query "" "Your Name" "Git requires your name to compile the kernel")"

		var=`(date +%F_%H-%M-%S)` # Capture current timestamp
		# Archive Kernel?
		if [ "$(YesNo "Archive Kernel?" "Do you want to save the kernel files to be re-used later?")" == "1" ]; then
			Note "Kernel Archive Selected"
			ARCHIVEKERNEL=1
			ARCHIVEKERNELNAME="$(Query "4.4.$KERNELDOT $var" "Kernel Name" "Enter a brief description of this kernel")"
			MakeDirNE "/espressobin/build_archive/kernel/$ARCHIVEKERNELNAME"
			ln -s "/espressobin/build_archive/kernel/$ARCHIVEKERNELNAME" /espressobin/karchive
			touch "/espressobin/build_archive/kernel/$ARCHIVEKERNELNAME/$var"
			
		else
			Note "Kernel Archive NOT Selected"
		fi
	fi

	# Create OS?
	if [ "$(YesNo "Create OS?" "Do you want to build an OS image?")" == "1" ]; then
		BUILDOS=1
		# OS Version
		OSVERSION="$(whiptail --title "OS Version" --radiolist "Select the OS version to build" 10 80 3 \
			"14" "Ubuntu 14.04.5 (Trusty)" OFF "16" "Ubuntu 16.04.4 (Xenial)" ON \
			"18" "Ubuntu 18.04.3 (Bionic)" OFF 3>&1 1>&2 2>&3)"

		# Archive OS?
		if [ "$(YesNo "Archive OS?" "Do you want to save the OS to be re-used later?")" == "1" ]; then
			ARCHIVEOS=1
			ARCHIVEOSNAME="$(Query "Ubuntu $OSVERSION $var" "OS Name" "Enter a brief description of this OS ")"
			MakeDirNE "/espressobin/build_archive/os/$ARCHIVEOSNAME"
			ln -s "/espressobin/build_archive/os/$ARCHIVEOSNAME" /espressobin/oarchive
			touch "/espressobin/build_archive/os/$ARCHIVEOSNAME/$var"
		fi
	fi

	# Read partitons second time to identify new drive attached
	if [ "$IMAGE_DRIVE" == "1" ]; then ReadAttachedPartitions 1; fi

	# Compare first drive inventory to last drive inventory
	IdentifyAvailableDrives

	# Choose partition to write image to
	UserIDDestDrive
	#echo "$DRIVE_TO_IMAGE"
}

YesNo(){ # Uses whiptail to ask yes/no questions
    # Usage: YesNo <whiptail title> <prompt>
    if (whiptail --title "$1" --yesno "$2" 8 78 3>&1 1>&2 2>&3) then
        echo "1"
    else
        echo "0"
    fi
}

DeletePrevDir(){ # <dir path>
	# Removes directories if they already exist
	if [ -d "$1" ]; then rm -rf "$1"; fi
}

IdentifyAvailableDrives(){
	# Compares ORIG_PARTS to WDRIV_PARTS to identify drives added during operation
	AVAIL_DRIVES=()
	for i in "${WDRIV_PARTS[@]}"; do
	    skip=
	    for j in "${ORIG_PARTS[@]}"; do
	        [[ $i == $j ]] && { skip=1; break; }
	    done
	    [[ -n $skip ]] || AVAIL_DRIVES+=("$i")
	done

	#for i in "${AVAIL_DRIVES[@]}"; do
	#	echo "$i"
	#done
}

ImageRemDrive(){
	if [ "$IMAGE_DRIVE" == "0" ]; then return 0; fi
	message="The process is nearly complete.  The script will now image /dev/$DRIVE_TO_IMAGE with the OS.  You will have to enter \"y\" after this message to approve imaging."
	whiptail --title "Ready to Image Drive" --msgbox "$message" 16 78
	cd /espressobin
	
	Note "The drive must be unmounted"
	sudo umount "/dev/${DRIVE_TO_IMAGE}"

	Note "Formatting the drive"
	sudo mkfs -t ext4 "/dev/${DRIVE_TO_IMAGE}"

	MakeDirNE /espressobin/cardtemp
	Note "Mounting the newly formatted drive"
	mount "/dev/${DRIVE_TO_IMAGE}" /espressobin/cardtemp
	cd /espressobin/cardtemp
	
	Note "Extracting the OS onto the drive"
	sudo tar -xvf "/espressobin/os_image/rootfs.tar.bz2"

	cd /espressobin
	sudo umount /espressobin/cardtemp
	DeletePrevDir /espressobin/cardtemp
	DeletePrevDir /espressobin/os_image/tmp
}

KillSymlinks(){
	if [ -d /espressobin/karchive ]; then unlink /espressobin/karchive; fi
	if [ -d /espressobin/kbuild ]; then unlink /espressobin/kbuild; fi
	if [ -d /espressobin/oarchive ]; then unlink /espressobin/oarchive; fi
	if [ -d /espressobin/obuild ]; then unlink /espressobin/obuild; fi
}

ReadAttachedPartitions(){ # <drive not attached = 0, drive attached = 1>
	# Loads all attached drive partitions
	if [ "$1" == "0" ]; then
		readarray -t ORIG_PARTS <<< "$(lsblk | grep ─sd)"
	else
		readarray -t WDRIV_PARTS <<< "$(lsblk | grep ─sd)"
	fi
	Note "Drive Inventory Complete."
}

Toolchain(){
	MakeDirNE /espressobin/toolchain 1

	if ! [ -e "gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu.tar.xz" ]; then
		Note "Downloading Kernel Building Toolchain"
		wget https://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-2/aarch64-linux-gnu/gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu.tar.xz
	else
		Note "Kernel Downloading Toolchain already downloaded"
	fi

	DeletePrevDir "/espressobin/toolchain/gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu"

	Note "Extracting Toolchain"
  	tar -xvf gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu.tar.xz

  	Note "Installing necessary software to build the kernel"
  	sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison -y

	cd /espressobin
}

# ======================================
#                    ROUTING AND CONTROL
# ======================================
Initialize(){
	# Routes the script process based upon selections made by the user
	CheckDriveSpace # Verifies that the boot drive has sufficient space
	MakeDirNE /espressobin 1        # Creates the base build directory

	KillSymlinks                    # Delete symlinks created by this process if they exist
	UserQuestions                   # Ask the user questions to control the process

	whiptail --title "Begin" --msgbox "The process will now begin.  It can take up to an hour depending on network and PC capabilities.  This process will not be interupted until it reaches the end and the removable drive will be imaged." 12 78
	if [ "$?" = 1 ]; then
		clear
		Alert "User Canceled."
		exit
	fi

	Toolchain                       # Download the kernel building toolchain if not already present
	BuildKernel                     # Build the kernel if selected
	BuildOS                         # Build Operating System if selected
	ImageRemDrive                   # Copies the OS filesystem to the removable drive
	KillSymlinks                    # Delete symlinks created by this process if they exist

	message="The process is complete."
	whiptail --title "Process Complete" --msgbox "$message" 16 78
}

Initialize
