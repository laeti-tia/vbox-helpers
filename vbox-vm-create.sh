#!/usr/local/bin/bash
#
# Create a new VM and its ZVOL
# See the README.md file for general documentation
#
# This script takes two arguments:
#  - the VM name, with an optional path prefix
#  - the disk size, in GB

### Constants
zvol_root='/dev/zvol/'
# The zfs mount point where are stored the ZVOLs
zvol_path='tank/vm/disks/'
# The zfs pool where are stored the ZVOLs
zfs_pool='tank/vm/disks/'
# VirtualBox VM root
vbox_root='/tank/vm/'
# TODO: add the possibilty to use other snapshot names
curr='Clean'
# VM settings
memory=1024

### User supplied variables
# $1: the full VM path, it can take subdirectories under $zvol_path
if [ -z $1 ]; then
    echo -e "\033[31mPlease provide a VM name/path to create.\033[0m"
    exit 1
fi
VM_path=$1
VM=${VM_path/*\//}
if [ -z $2 ]; then
    echo "Which OS type this VM is? You can get a list of currently supported types by running 'VBoxManage list ostypes'"
    exit 1
elif ! VBoxManage list ostypes | grep -qE "^ID:[[:space:]]+$2$"; then
    echo "The OS type $2 doesn't seem to exist for VirtualBox, check the currently supported types with 'VBoxManage list ostypes'"
    exit 1
else
    ostype=$2
fi
if [ -z $3 ]; then
    echo "You didn't provide a disk size, I'll create a 10G disk for you."
    echo "If you want to use another size, run this script with the disk size (and G suffix) as last arg."
    echo
    size="10G"
else
    size=$3
fi

### Checks
# Check there's no existing VM with the new name
VBoxManage showvminfo $VM > /dev/null 2> /dev/null
ret=$?
if [ $ret -eq 0 ]; then
    echo -e "\033[31mThere is already a VM named \033[38;5;12m$VM\033[0m, please provide another name."
    exit 1
fi
if [ $ret -ne 1 ]; then
    echo -e "\033[38;5;214mThis was not the return code that I was expecting ($return) for \033[38;5;12m$VM\033[0m"
    echo "I continue anyway, but something might go wrong later."
fi

zfs list $zfs_pool$VM_path > /dev/null 2> /dev/null
ret=$?
if [ $ret -eq 0 ]; then
    echo -e "\033[31mA disk named \033[38;5;12m$zfs_pool$VM_path\033[0;31m already exists, I cannot create this VM.\033[0m"
    exit 1
fi
if [ $ret -ne 1 ]; then
    echo -e "\033[38;5;214mThis was not the return code that I was expecting ($return) for \033[38;5;12m$zfs_pool$VM_path\033[0m"
    echo "I continue anyway, but something might go wrong later."
fi

### Ask for confirmation
#
echo -e "We're going to create \033[38;5;12m$VM\033[0m as a \033[1m$ostype VM and its ZVOL of $size\033[0m under \033[38;5;12m$VM_path\033[0m."
echo -e "We'll need to use sudo for the 'zfs create' command (I might ask for your password)."
echo -e "\033[1mIs that ok?\033[0m"
unset ANSWER
read -p "(y/N) " -n 1 ANSWER
echo
if [[ "${ANSWER:=n}" == "n" || "${ANSWER:=N}" == "N" ]]; then
    echo "Ok, I quit"
    exit
fi

### Take action
# Create ZVOL (not sure why it needs sudo although permissions on zfs and devs are supposed to be set correctly...)
if ! sudo zfs create -V $size -p $zfs_pool$VM_path; then
    echo -e "\033[31mThere was an error trying to create the ZVOL \033[38;5;12m$zfs_pool$VM_path\033[0m."
    echo -e "It's better I stop here."
    exit 1
fi
    
# Create VM
if ! VBoxManage createvm --name $VM --ostype $ostype --register; then
    echo -e "\033[31mThere was an error trying to create the VM \033[38;5;12m$VM\033[0m."
    echo -e "It's better I stop here. Check the ZVOL and delete it if it is not needed."
    exit 1
fi

# Adjust VM settings
if ! VBoxManage modifyvm $VM --pae off --memory $memory --nic1 bridged --nictype1 virtio --usb on; then
    echo -e "\033[31mThere was an error trying to modify the VM \033[38;5;12m$VM\033[0m."
    echo -e "It's better I stop here. Check the ZVOL and VM and delete or correct as needed."
    exit 1
fi
if ! VBoxManage storagectl $VM --name SATA --add sata --hostiocache on; then
    echo -e "\033[31mThere was an error trying to modify the VM \033[38;5;12m$VM\033[0m."
    echo -e "It's better I stop here. Check the ZVOL and VM and delete or correct as needed."
    exit 1
fi

# Add ZVOL to VM
if ! VBoxManage internalcommands createrawvmdk -filename $VM_path/$VM.vmdk -rawdisk $zvol_root$zfs_pool$VM_path; then
    echo -e "\033[31mThere was an error trying to create the ZVOL VMDK file at \033[38;5;12m$VM_path/$VM.vmdk\033[0m."
    echo -e "It's better I stop here. Check the ZVOL and VM and delete or correct as needed."
    exit 1
fi
if ! VBoxManage storageattach $VM --storagectl SATA --port 0 --type hdd --medium $VM_path/$VM.vmdk; then
    echo -e "\033[31mThere was an error trying to attach the ZVOL VMDK file from \033[38;5;12m$VM_path/$VM.vmdk\033[0m."
    echo -e "It's better I stop here. Check the ZVOL and VM and delete or correct if needed."
    exit 1
fi

# Take a first snapshot
zfs snapshot $zfs_pool$VM@$curr

echo -e "\nIf there were no error message above, all seems to be fine and your VM is ready to be started."
echo -e "You might need to add a CD/DVD and boot it in visual mode to be able to install an OS."

