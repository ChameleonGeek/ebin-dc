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
echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic main universe" > /etc/apt/sources.list
echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic-security main universe" >> /etc/apt/sources.list
echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic-updates main universe" >> /etc/apt/sources.list

Note "Setting up repo for Samba 4.11"
echo "deb http://apt.van-belle.nl/debian bionic-samba411 main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/van-belle.list
wget -O - http://apt.van-belle.nl/louis-van-belle.gpg-key.asc | apt-key add -

Note "Updating Package Lists"
apt update -y
sleep 5             # System occasionally hangs if this is not performed

Note "Upgrading installed software"
apt-get upgrade -y

Note "Installing Baseline Software"
apt install -y nano python3-dev python3-pip python3-cffi tasksel gnupg debconf-utils network-manager

Note "Checking Samba Installer Policy"
apt-cache policy samba

Note "Installing Samba AD-DC components"
apt install -y samba winbind libnss-winbind libpam-winbind ntp bind9 binutils ldb-tools krb5-user

Note "Configuring Samba to automatically start"
systemctl disable nmbd smbd winbind 
systemctl stop nmbd smbd winbind 
systemctl unmask samba-ad-dc
systemctl enable samba-ad-dc

