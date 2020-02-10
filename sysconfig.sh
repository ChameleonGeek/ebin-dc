#!/bin/bash

# DEVELOPMENT SCRIPT!
# THIS SCRIPT WILL FAIL!  IT IS INTENDED TO HELP ME WITH IDENTIFYING THE ACTUAL DEPENDENCIES TO BUILD SAMBA FROM SOURCE
#     NO SINGLE SOURCE I'VE FOUND TRULY IDENTIFIES ALL DEPENDENCIES IN THIS SCENARIO

GRN='\033[1;32m'   # Makes on-screen text green
NC='\033[0m'	   # Makes on-screen text default (white)

EchoColor(){ # color, text
	# Prints the passed string onto the screen in the designated color
	# Usage: EchoColor <color> <text>
	echo -e "$1$2${NC}";
}

Note(){ # text
	# Prints the passed string in green
	EchoColor "${GRN}" "$1";
}

Note "Configuring hostname and hosts file"
hostname espressobin
echo -e "127.0.0.1\tespressobin.verdunn.lan espressobin" > /etc/hosts

Note "Updating repositories"
sed -i 's| bionic main| bionic main universe|' /etc/apt/sources.list
sed -i 's| bionic-security main| bionic-security main universe|' /etc/apt/sources.list
sed -i 's| bionic-updates main| bionic-updates main universe|' /etc/apt/sources.list
sed -i 's| universe universe| universe|' /etc/apt/sources.list

Note "Updating Package Lists"
apt-get update
sleep 5             # System occasionally hangs if this is not performed

Note "Upgrading installed software"
apt-get upgrade -y

Note "Installing Baseline Software"
apt install -y nano python3-dev python3-pip python3-cffi tasksel gnupg debconf-utils network-manager

Note "Installing Samba Build Prereqs"
#apt install -y acl apt-utils attr autoconf bind9utils binutils bison build-essential chrpath curl debhelper dnsutils docbook-xml docbook-xsl flex gcc gdb git glusterfs-common gnutils gzip heimdal-multidev hostname htop krb5-config krb5-kdc krb5-user language-pack-en lcov libacl1-dev libaio-dev libarchive-dev libattr1-dev libavahi-common-dev libblkid-dev libbsd-dev libcap-dev libcephfs-dev libcups2-dev libdbus-1-dev libglib2.0-dev libgnutls28-dev libgpgme-dev libgpgme11-dev libicu-dev libjansson-dev libjs-jquery libjson-perl libkrb5-dev libldap2-dev liblmdb-dev libncurses5-dev libpam0g-dev libparse-yapp-perl libpcap-dev libpopt-dev libreadline-dev libsystemd-dev libtasn1-bin libtasn1-dev libunwind-dev lmdb-utils locales lsb-release make mawk mingw-w64 nettle-dev patch perl-modules perl pkg-config procps psmisc python-all-dev python-crypto python-dbg python-dev python-dnspython python-gpg python-markdown python3-dbg python3-dev python3-dnspython python3-gpg python3-iso8601 python3-markdown python3-matplotlib python3-pexpect python3 rng-tools rsync sed sudo tar tree uuid-dev xfslibs-dev xsltproc zlib1g-dev
apt-get build-dep samba -y

Note "Retrieving Samba Source Code"
cd /opt
wget -c https://ftp.samba.org/pub/samba/stable/samba-4.11.6.tar.gz

Note "Extracting Samba Source Code"
tar -zxvf samba-4.11.6.tar.gz
cd samba-4.11.6

Note "Configuring for build from source"
./configure.developer

Note "Compiling from Source"
make

Note "If this has succeeded, attempt \"make install\""
#make install

