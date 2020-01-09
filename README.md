# ebin-dc
Configure an EspressoBin v7 as a Domain Controller

This is not at all functional at this point.  At the moment, it is being used to share notes between multiple systems and document possible strategies.

# Download the toolchain to compile the kernel
http://wiki.espressobin.net/tiki-index.php?page=Build+From+Source+-+Toolchain
mkdir -p toolchain && cd toolchain
wget https://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-2/aarch64-linux-gnu/gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu.tar.xz
tar -xvf gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu.tar.xz

# The path is proper for running from an Ubuntu Live CD
export PATH=$PATH:/home/toolchain/gcc-linaro-5.2-2015.11-2-x86_64_aarch64-linux-gnu/bin

cd /home
sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison -y

sudo su
mkdir -p kernel/4.4.8 && cd kernel/4.4.8/
git clone https://github.com/MarvellEmbeddedProcessors/linux-marvell .
git checkout linux-4.4.8-armada-17.02-espressobin

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
