#!/bin/bash

# Defines path to OS image '.iso'
iso_path="/iso/CentOS-7-x86_64-Everything-1908.iso"

# Definitions
vm_dir="/var/vbox"
vm_name="CentOS_7"
vm_ostype="RedHat_64"
vm_cpus=2
vm_memory=6000		# MB
vm_storage=20480	# MB

# Check is running as privileged user
if [ $EUID -ne 0 ]
then
	printf "ERROR:\tThis script must be run as privileged user...\nExiting...\n"
	exit 1
fi

# Check the '.iso' disc image is exists
if [ ! -f $iso_path ];
then
	printf "Could not find disc image:\t$iso_path\nPlease ensure disc image exists at this location.\nExiting..."
	exit 1
fi


# Create the install dir if it does not exist
if [ ! -d "$vm_dir" ]; then sudo mkdir "$vm_dir"; fi

# Create the VM
sudo VBoxManage createvm \
--name "$vm_name" \
--ostype "$vm_ostype" \
--register \
--basefolder "$vm_dir"

# Add key information
sudo VBoxManage modifyvm "$vm_name" \
--cpus "$vm_cpus" \
--memory "$vm_memory" \
--nic1 bridged \
--bridgeadapter1 $(ip route get 1.1.1.1 | grep -Po '(?<=dev\s)\w+' | cut -f1 -d ' ') \
--boot1 dvd \
--vrde on \		# Allows Remote Connection to VM via host:5001 (i.e. 192.168.0.9:5001)
--vrdeport 5001		# Defines VRDE port

# Configure Storage
sudo VBoxManage storagectl "$vm_name" \
--name ""$vm_name"_SATA" \
--add sata

sudo VBoxManage createhd \
--filename ""$vm_dir"/"$vm_name"/"$vm_name".vdi" \
--size "$vm_storage" \
--format VDI \
--variant Standard

sudo VBoxManage storageattach "$vm_name" \
--storagectl ""$vm_name"_SATA" \
--port 1 \
--type hdd \
--medium ""$vm_dir"/"$vm_name"/"$vm_name".vdi"

# Configure DVD drive
sudo VBoxManage storageattach "$vm_name" \
--storagectl ""$vm_name"_SATA" \
--port 0 \
--type dvddrive \
--medium "$iso_path"

# Show settings
sudo VBoxManage showvminfo "$vm_name"

# Start VM
sudo VBoxHeadless --startvm "$vm_name" --vrde on &
