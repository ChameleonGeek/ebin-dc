## Templates

This folder contains file templates needed to configure the EspressoBin.  These files will be downloaded to the proper location, and 
will be edited as necessary with the proper values, based upon the selections made by the user.

Not all template files will be downloaded for all installations.  They will only be downloaded when needed for specific configurations.

### 01-netcfg.yaml
This is the network configuration to be used by netplan.  It will be copied to /etc/netplan/01-netcfg.yaml and updated with the IP settings 
selected by the user.

### smb.conf
This is the configuration file for Samba.  It will be copied to /etc/samba/samba.conf and will be updated with the necessary information 
to configure Samba as a domain controller.
