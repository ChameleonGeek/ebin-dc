#!/bin/bash
# ==============================================================================
# ==============================================================================
# 
#                               EspressoBin Config
#                               Domain Controller
#                                September, 2019
#                   https://github.com/ChameleonGeek/ebin-dc
# 
#    This script performs the initial setup tasks outlined at 
# https://github.com/ChameleonGeek/ebin-kodi/raw/master/README.md
#	 This script performs the basic software installation and configuration 
# necessary to make a new EspressoBin v7 into an Ubuntu 16.04 LTS server with 
# various software necessary to support a Kodi/OSMC media center.
# 
#	   This script is the fourth step of configuring the EspressoBin.  It expects
# that the EspressoBin has been configured to boot to MicroSD, it has a MicroSD 
# card with a prevously untouched Ubuntu 16.04 LTS image installed, which has 
# been configured per the instructions at 
# https://github.com/ChameleonGeek/ebin-kodi/README.md
# 
# ==============================================================================
# ==============================================================================
preconfig(){
	clear
	echo "Starting networking.  This will take a moment"
	ip link set dev eth0 up
	ip link set dev lan1 up
	dhclient lan1
	apt-get update
	sleep 5
	apt-get install wget -y
	
	wget https://raw.githubusercontent.com/ChameleonGeek/ebin-kodi/master/espressobin.sh
	chmod +x espressobin.sh
	bash espressobin.sh
}
preconfig
