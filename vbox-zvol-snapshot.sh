#!/usr/local/bin/bash
# This script creates a new ZFS ZVOL snapshot for an existing VM
# See the README.md file for general documentation
#
# This script takes one argument:
#  - the VM name, with an optional path prefix

### Constants
# The zfs mount point where are stored the ZVOLs
zvol_path='tank/vm/disks/'
curr='Clean'
prev='Previous'

### User supplied variables
# The full VM path, it can take subdirectories under $zvol_path
VM_path=$1
VM=${VM_path/*\//}

echo -e "We're going to rotate the \033[38;5;12m@$curr\033[0m snapshot of \033[38;5;12m$VM\033[0m."
# Check VM exists, has ZVOL disks and is not running
VBoxManage showvminfo $VM > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m doesn't seem to be existing.\033[0m"
    exit
fi
zfs list $zvol_path$VM_path > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m doesn't seem to have ZVOL disks at \033[38;5;12m$VM_path\033[0m"
    exit
fi
VBoxManage list runningvms | grep $VM > /dev/null
if [ $? -eq 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m seems to be running, it is not recommended I take a ZVOL snapshot now.\033[0m"
    exit
fi

# Rotate existing snapshot and take a new one
# TODO: add the possibilty to use other snapshot names
zfs destroy $zvol_path$VM_path@$prev
if [ $? -ne 0 ]; then
    echo -e "\033[38;5;214mSomething went wrong trying to destroy \033[38;5;12m$zvol_path$VM_path@$prev\033[0m"
    echo "I continue anyway, but something might go wrong later."
fi
zfs rename $zvol_path$VM_path@$curr $zvol_path$VM_path@$prev
if [ $? -ne 0 ]; then
    echo -e "\033[31mSomething went wrong trying to rename \033[38;5;12m$zvol_path$VM_path@$curr to $zvol_path$VM_path@$prev\033[0m"
    echo "I quit!"
    exit
fi
zfs snapshot $zvol_path$VM_path@$curr
if [ $? -ne 0 ]; then
    echo -e "\033[31mSomething went wrong trying to create \033[38;5;12m$zvol_path$VM_path@$curr\033[0m"
else
    echo -e "We took a new snapshot of \033[1m$VM\033[0m at \033[38;5;12m$zvol_path$VM_path@$curr\033[0m and rotated the previous one at \033[38;5;12m$zvol_path$VM_path@$prev\033[0m"
fi

