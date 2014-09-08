#!/usr/local/bin/bash
#
# Clone an existing VM with disks on ZVOL
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
# $1: the full VM path, it can take subdirectories under $zvol_path
if [ -z $1 ]; then
    echo -e "\033[31mPlease provide a VM name/path to make a snapshot.\033[0m"
    exit 1
fi
VM_path=$1
VM=${VM_path/*\//}

# $2: the full path for the new VM, it can take subdirectories under $zvol_path
if [ -z $2 ]; then
    echo -e "\033[31mPlease provide a VM name/path for the new VM.\033[0m"
    exit 1
fi
new_VM_path=$2
new_VM=${new_VM_path/*\//}

echo -e "We're going to clone \033[38;5;12m$VM_path\033[0m@\033[38;5;12m$curr\033[0m into \033[38;5;12m$new_VM_path\033[0m@\033[38;5;12m$curr\033[0m to make a new VM named \033[38;5;12m$new_VM\033[0m."
# Check VM exists, has ZVOL disks and the $curr snapshot exists
VBoxManage showvminfo $VM > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m doesn't seem to be existing.\033[0m"
    exit 1
fi
zfs list $zvol_path$VM_path@$curr > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m doesn't seem to have a snapshot of ZVOL disks at \033[38;5;12m$VM_path@$curr\033[0m"
    exit 1
fi

# Check there's no existing VM with the new name
VBoxManage showvminfo $new_VM > /dev/null 2> /dev/null
ret=$?
if [ $ret -eq 0 ]; then
    echo -e "\033[31mThere is already a VM named \033[38;5;12m$new_VM\033[0m, please provide another name."
    exit 1
fi
if [ $ret -ne 1 ]; then
    echo -e "\033[38;5;214mThis was not the return code that I was expecting ($return) for \033[38;5;12m$new_VM\033[0m"
    echo "I continue anyway, but something might go wrong later."
fi

# First we clone the ZVOL
# Second we create a new VMDK
# Third we create a new VM
# Forth we attach the VMDK to the newly created VM

# All done!
