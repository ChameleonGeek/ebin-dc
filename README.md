# ebin-dc
Configure an EspressoBin v7 as a Domain Controller

This is not at all functional at this point.  At the moment, it is being used to share notes between multiple systems and document possible strategies.

The EspressoBin is a pretty impressive piece of hardware for the cost.  Unfortunately, the documentation and support is pretty lacking.  This project is designed to take a fresh EspressoBin v7 straight out of the box and turn it into an Ubuntu 16.04LTS Domain Controller.  This is building upon my first EspressoBin repository, using a number of key learnings from that project.

The Ubuntu 16.04LTS image that can be downloaded from Espressobin.net includes a kernel which does not support POSIX ACLs.  This causes Samba Provisioning to fail.  Most tutorials related to compiling a Linux kernel have substantial voids in identifying the tools and previous key learnings held by the author.  I am making every attempt to ensure that this documentation can be followed step-by-step by a Linux amateur and will walk the user through every step.  As this project is being built (to some degree) through trial and error, the reasoning behind every step may not be explained, but each step will be validated by myself and a friend to ensure that each step works without needing to correct any of the steps.

```
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
```
