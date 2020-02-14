#!/bin/bash
# UPDATED: 2020-02-13 16:00:45
# ==============================================================================
# ==============================================================================
# 
#                               EspressoBin Config
#                               Domain Controller
#                                 February, 2020
#             https://github.com/ChameleonGeek/ebin-dc/           
# 
#    THIS SCRIPT FILL FAIL!
#    IT IS INTENDED TO IDENTIFY FAILURES IN THE BUILD PROCESS FOR CONFIGURING
# SAMBA ON THE ESPRESSOBIN AS AN AD DC.
#
# ==============================================================================
# ==============================================================================

# ======================================
#                              VARIABLES
# ======================================
#display variables
BLU='\033[1;34m'   # Makes on-screen text blue
CYA='\033[1;36m'   # Makes on-screen text cyan
GRN='\033[1;32m'   # Makes on-screen text green
MAG='\033[1;35m'   # Makes on-screen text magenta
NC='\033[0m'	   # Makes on-screen text default (white)
RED='\033[1;31m'   # Makes on-screen text red
YEL='\033[1;33m'   # Makes on-screen text yellow


# ======================================
#               BASIC USER COMMUNICATION
# ======================================
Alert(){ # text
	# Prints the passed string in red
	EchoColor "${RED}" "$1";
}

DispSysConfig(){
	TimeStamp
	Note "Logging some system info to assist in debugging"
	Note "Listing Block Devices"
	lsblk
	Note "Displaying filesystem type"
	df -Th | grep "^/dev"
	Note "tune2fs report for /dev/mmcblk0p1"
	tune2fs -l /dev/mmcblk0p1
}

EchoColor(){ # color, text
	# Prints the passed string onto the screen in the designated color
	# Usage: EchoColor <color> <text>
	echo -e "$1$2${NC}";
}

LogInstall(){ # Software
	# Logs main software package installation
	if ! [ -e "installed.list" ]; then
		touch "installed.list"
	fi
	echo "$1" >> "installed.list"
}

Note(){ # text
	# Prints the passed string in green
	EchoColor "${GRN}" "$1";
	EchoColor "${GRN}" "################################################################################"
}

NotePause(){ # text
	# Displays the passed string and waits for the user to hit enter to continue
	return 0
}

QueryInstall(){ # package cfg_key
	# Asks if user wants to install the specified package
	if [ "$(YesNo "Install $2" "Do you want to install $1?")" == "1" ]; then
		cfg_write "$2" 1
	else
		cfg_write "$2" 0
	fi
}

QueryInstallConfirm(){
	# 
	return 0
}

QueryPass(){ # <default value> <whiptail title> <prompt>
	# Asks the user for a password.  Input will be hidden from view
	retval=$(whiptail --title "$2" --passwordbox "$3" 8 78 "$1" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ "$exitstatus" = "0" ]; then
		echo "$retval"
	else
		echo ""
	fi
}

QueryString(){ # <default value> <whiptail title> <prompt>
	# Asks the user for a string value
	retval=$(whiptail --title "$2" --inputbox "$3" 8 78 "$1" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ "$exitstatus" = "0" ]; then
		echo "$retval"
	else
		echo ""
	fi
}

Splash(){
	return 0
}

TimeStamp(){
	EchoColor "${YEL}" "$(date)"
	EchoColor "${YEL}" "################################################################################"
}

YesNo(){ # <title> <question>
	# Uses whiptail to ask user yes/no questions
	if (whiptail --title "$1" --yesno "$2" 8 78 3>&1 1>&2 2>&3) then
		echo "1"
	else
		echo "0"
	fi
}

YesNoConfirm(){ # <title> <question>
	# Asks the user a question and then asks the user to confirm the answer
	ret="$(YesNo "$1?"  "$2")"
	if [ "$ret" = "1" ]; then
		ret="$(YesNo "Confirm" "You answered yes. Is this correct?")"
	else
		ret="$(YesNo "Confirm" "You answered no. Is this correct?")"
	fi
	echo "$ret"
}

YesNoInstall(){ # <software> <config_key>
	# Asks the user if they want to install a specific program, then confirm that answer
	ci="0"
	while [ "$ci" = "0" ]; do
		ret="$(YesNo "Install $1?"  "Do you want to install $1?")"
		if [ "$ret" = "1" ]; then
			ci="$(YesNo "Confirm Install" "You chose to install $1. Is this correct?")"
		else
			ci="$(YesNo "Confirm Install" "You chose NOT to install $1. Is this correct?")"
		fi
	done
	
	cfg_write "$2" "$ret"
}

# ======================================
#               CONFIGURATION READ/WRITE
# ======================================
SetHost(){
	Note "Configuring hostname and hosts file"
	hostname espressobin
	echo -e "127.0.0.1\tespressobin.home.lan espressobin" > /etc/hosts
}

SetSourcesMain(){
	Note "Updating repositories to include \"universe\" sources"
	echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic main universe" > /etc/apt/sources.list
	echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic-security main universe" >> /etc/apt/sources.list
	echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic-updates main universe" >> /etc/apt/sources.list

	TimeStamp
	Note "Updating Package Lists"
	apt-get update
	sleep 5             # System occasionally hangs if this is not performed
}

SetSourcesVanBelle(){
	TimeStamp
	Note "Adding Van-Belle repository necessary to install Samba"
	echo "deb http://apt.van-belle.nl/debian bionic-samba411 main contrib non-free" > /etc/apt/sources.list.d/van-belle.list
	echo "deb-src http://apt.van-belle.nl/debian bionic-samba411 main contrib non-free" > /etc/apt/sources.list.d/van-belle.list

	Note "Adding GPG key for Van-Belle Repo"
	wget http://apt.van-belle.nl/louis-van-belle.gpg-key.asc
	apt-key add louis-van-belle.gpg-key.asc
	rm louis-van-belle.gpg-key.asc

	TimeStamp
	Note "Updating Package Lists with Van-Belle repo"
	apt-get update
	sleep 5             # System occasionally hangs if this is not performed
}

# ======================================
#                        SIMPLE BUILDERS
# ======================================
GetVanBelleSourceAndDeps(){ # <pkg #> <pkg name>
	# Downloads Van Belle sources and installs the necessary dependencies
	TimeStamp
	Note "<<<<< Downloading Van Belle Source ($1) $2 >>>>>"
	if ! [ -d "$1-$2" ]; then mkdir "$1-$2/"; fi

	# User _apt must be the owner of these directories
	# Resolve "W: Download is performed unsandboxed as root as file '<specific file>' couldn't be accessed by user '_apt'. - pkgAcquire::Run (13: Permission denied)" errors
	chown _apt "$1-$2/"
	cd "$1-$2/"

	Note "Retrieving source"
	apt-get source "$2"

	Note "Building and installing dependency list"
	apt-get build-dep "$2" -y

	# Move to folder to complete build process
	cd $(ls -ltr|grep "drwx" |awk '{ print $NF }')
	Note "Building source in $(pwd)"
	Note "Configuring $2 for make"
	./configure
	Note "Making $2"
	make
	Note "Installing $2"
	make install
	cd ..
	cd ..
}

# ======================================
#                      SIMPLE INSTALLERS
# ======================================
AptUpgrade(){
	TimeStamp
	Note "Upgrading installed software"
	apt-get upgrade -y
}

BaselineInstall(){
	TimeStamp
	Note "Installing Baseline Software"
	apt install -y nano python3-dev python3-pip python3-cffi tasksel gnupg debconf-utils network-manager
}

VanBelleAddedDeps(){
	# Installs dependencies for building Samba which are not captured by Van Belle repos
	# List is currently being built
	apt install -y libtalloc-dev 
	apt install -y libcmocka-dev libldb-dev libtdb-dev libtevent-dev python3-ldb python3-ldb-dev python3-talloc-dev python3-tdb
	return 0
}

# ======================================
#                     MANAGED INSTALLERS
# ======================================
VanBellePullSources(){
	# Pulls sources from Van Belle repos
	GetVanBelleSourceAndDeps 01 talloc
	GetVanBelleSourceAndDeps 02 tevent
	GetVanBelleSourceAndDeps 03 tdb
	GetVanBelleSourceAndDeps 04 cmocka
	GetVanBelleSourceAndDeps 05 ldb
	GetVanBelleSourceAndDeps 06 nss-wrapper
	GetVanBelleSourceAndDeps 07 resolv-wrapper
	GetVanBelleSourceAndDeps 08 uid-wrapper
	GetVanBelleSourceAndDeps 09 socket-wrapper
	GetVanBelleSourceAndDeps 10 pam-wrapper
	GetVanBelleSourceAndDeps 11 samba 
}

# ======================================
#                      SCRIPT NAVIGATION
# ======================================
Initialize(){
	DispSysConfig
	SetHost
	SetSourcesMain
	AptUpgrade
	BaselineInstall

	SetSourcesVanBelle
	VanBelleAddedDeps          # This is needed before downloading Van Belle repos
	VanBellePullSources

	TimeStamp
	Note "Script complete.  Please review for errors or warnings."
}

# ======================================
#          STRUCTURED USER COMMUNICATION
# ======================================
Initialize "$1" "$2"
