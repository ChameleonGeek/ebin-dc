#!/bin/bash
# ==============================================================================
# ==============================================================================
# 
#                               EspressoBin Config
#                               Domain Controller
#                                  January, 2020
#             https://github.com/ChameleonGeek/ebin-dc/preconfig.sh             
# 
#    This script is intended to be executed on first boot of the EspressoBin.
# It performs intitial DHCP network setup, updates Ubuntu and installs wget.
# Wget is used to download the main configuration script from 
# https://github.com/ChameleonGeek/ebin-dc/sysconfig.sh
# 
#	   This script expects that the EspressoBin has been configured to boot to 
# MicroSD and has been booted from a MicroSD card with a prevously untouched
# Ubuntu 16.04 LTS image installed, which has been configured per the
# instructions at https://github.com/ChameleonGeek/ebin-dc/README.md
#
# ==============================================================================
# ==============================================================================

# ==========================================================
#                                                  VARIABLES
# ==========================================================
GRN='\033[1;32m'   # Makes on-screen text green
NC='\033[0m'	   # Makes on-screen text default (white)


# ==========================================================
#                                USER NOTIFICATION FUNCTIONS
# ==========================================================
EchoColor(){ # color, text
	# Prints the passed string onto the screen in the designated color
	# Usage: EchoColor <color> <text>
	echo -e "$1$2${NC}";
}

Note(){ # text
	# Prints the passed string in green
	EchoColor "${GRN}" "$1";
}

# ==========================================================
#                                          PRIMARY FUNCTIONS
# ==========================================================
PreConfig(){
	clear
	Note "Starting networking.  This will take a moment"
	ip link set dev eth0 up
	ip link set dev lan1 up
	dhclient lan1
	apt-get update 		# Updates repositories - necessary for installing wget
	sleep 5				# System occasionally hangs if this is not performed

	Note "Installing wget so that main configuration script can be downloaded"
	apt-get install wget -y

	if [ -e sysconfig.sh ]; then 
		rm sysconfig.sh
	fi
	
	Note "Downloading configuration script"
	wget https://github.com/ChameleonGeek/ebin-dc/raw/master/sysconfig.sh
	chmod +x sysconfig.sh

	Note "Running configuration script"
	sudo bash sysconfig.sh
}

# Necessary to stop CPU throttling which may trigger a kernel panic
systemctl disable ondemand
pkill ondemand

# Run the script
PreConfig
