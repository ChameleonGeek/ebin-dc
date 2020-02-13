#!/bin/bash

# DEVELOPMENT SCRIPT!
# THIS SCRIPT WILL FAIL!  IT IS INTENDED TO HELP ME RESOLVE THE SAMBA BUILD FAILURES I AM ENCOUNTERING.
# THIS SCRIPT CHANGED TO ATTEMPT RECOMMENDATIONS FROM L.P.H VAN BELLE ON 2020-02-12
# PREVIOUS VERSION IS sysconfig0.sh

BLU='\033[1;34m'
GRN='\033[1;32m'
NC='\033[0m' # No Color
RED='\033[1;31m'
YEL='\033[1;33m'

EchoColor(){ # color, text
	# Prints the passed string onto the screen in the designated color
	# Usage: EchoColor <color> <text>
	echo -e "$1$2${NC}";
}

Note(){ # text
	# Prints the passed string in green
	EchoColor "${GRN}" "$1";
	EchoColor "${GRN}" "################################################################################"
}

TimeStamp(){
	EchoColor "${YEL}" "$(date)"
	EchoColor "${YEL}" "################################################################################"
}

TimeStamp
Note "Logging some info to assist in debugging"
Note "Listing Block Devices"
lsblk
Note "Displaying filesystem type"
df -Th | grep "^/dev"
Note "tune2fs report for /dev/mmcblk0p1"
tune2fs -l /dev/mmcblk0p1

Note "Configuring hostname and hosts file"
hostname espressobin
echo -e "127.0.0.1\tespressobin.home.lan espressobin" > /etc/hosts

Note "Updating repositories"
echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic main universe" > /etc/apt/sources.list
echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic-security main universe" >> /etc/apt/sources.list
echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic-updates main universe" >> /etc/apt/sources.list

TimeStamp
Note "Updating Package Lists"
apt-get update
sleep 5             # System occasionally hangs if this is not performed

TimeStamp
Note "Upgrading installed software"
apt-get upgrade -y

TimeStamp
Note "Installing Baseline Software"
apt install -y nano python3-dev python3-pip python3-cffi tasksel gnupg debconf-utils network-manager

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

TimeStamp
if [ ! -d 01-talloc ]; then
    mkdir 01-talloc 02-tevent 03-tdb 04-cmocka 05-ldb 06-nss-wrapper 07-resolv-wrapper 08-uid-wrapper 09-socket-wrapper 10-pam-wrapper 11-samba
fi

Note "Gathering source and dependencies"
Note "talloc"
cd 01-talloc/
apt-get source talloc
apt-get build-dep talloc -y

Note "tevent"
cd 02-tevent/
apt-get source tevent
apt-get build-dep tevent -y
cd ..

Note "tdb"
cd 03-tdb/
apt-get source tdb
apt-get build-dep tdb -y
cd ..

Note "cmocka"
cd 04-cmocka/
apt-get source cmocka
apt-get build-dep cmocka -y
cd ..

Note "ldb"
cd 05-ldb/
apt-get source ldb
apt-get build-dep ldb -y
cd ..

Note "nss-wrapper"
cd 06-nss-wrapper/
apt-get source nss-wrapper
apt-get build-dep nss-wrapper -y
cd ..

Note "resolv-wrapper"
cd 07-resolv-wrapper/
apt-get source resolv-wrapper
apt-get build-dep resolv-wrapper -y
cd ..

Note "uid-wrapper"
cd 08-uid-wrapper/
apt-get source uid-wrapper
apt-get build-dep uid-wrapper -y
cd ..

Note "socket-wrapper"
cd 09-socket-wrapper/
apt-get source socket-wrapper
apt-get build-dep socket-wrapper -y
cd ..

Note "pam-wrapper"
cd 10-pam-wrapper/
apt-get source pam-wrapper
apt-get build-dep pam-wrapper -y
cd ..

Note "samba"
cd 11-samba/
apt-get source samba
apt-get build-dep samba -y
cd ..

TimeStamp
Note "Complete.  Expand script if successful"
