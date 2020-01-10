# ebin-dc
Configure an EspressoBin v7 as a Domain Controller

This is not at all functional at this point.  At the moment, it is being used to share notes between multiple systems and document possible strategies.

The EspressoBin is a pretty impressive piece of hardware for the cost.  Unfortunately, the documentation and support is pretty lacking.  This project is designed to take a fresh EspressoBin v7 straight out of the box and turn it into an Ubuntu 16.04LTS Domain Controller.  This is building upon my first EspressoBin repository, using a number of key learnings from that project.

The Ubuntu 16.04LTS image that can be downloaded from Espressobin.net includes a kernel which does not support POSIX ACLs.  This causes Samba Provisioning to fail.  Most tutorials related to compiling a Linux kernel have substantial voids in identifying the tools and previous key learnings held by the author.  I am making every attempt to ensure that this documentation can be followed step-by-step by a Linux amateur and will walk the user through every step.  As this project is being built (to some degree) through trial and error, the reasoning behind every step may not be explained, but each step will be validated by myself and a friend to ensure that each step works without needing to correct any of the steps.

Note that if you already have directories at /root/kernel, /root/toolchain or /root/ubuntu_16.04 they will and all files contained will be deleted.

Before you start the process, a few steps need to be completed:
- Connect a formatted microSD card to the computer.
- Identify which block device is the microSD card (such as sda1, sdb1, etc).  This can be accomplished by using the lsblk command.  You will be asked for confirmation, but the selected drive will be reformatted and all data will be deleted.
- Elevate your terminal session to superuser permissions by issuing the command sudo su.  Some of the tasks performed by the script will fail if not run by a superuser.

This process can take as long as an hour.

Once you are ready to compile the kernel and build the filesystem for the EspressoBin, paste the following commands into your terminal:

```
cd ~
wget https://raw.githubusercontent.com/ChameleonGeek/ebin-dc/master/kernel.sh
chmod +x kernel.sh
bash kernel.sh
```


January, 2020
