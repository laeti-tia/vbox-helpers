vbox.helpers
============

A collection of bash scripts to help with managing VirtualBox guests through the UNIX CLI.

These are designed to work on FreeBSD 10 with VirtualBox 5 and using ZFS ZVOL devices as VM disks.


Usage
-----
The provided scripts need to be run as the user owning the VM.

Most of these scripts assume you have VirtualBox and zfs installed and in your path.  ZFS is used to create ZVOL that act as raw devices to be used as VM disks.  You'll need a setup where the VM user can create new ZVOL and make snapshots (see below).

See documentation within each script for more information.


Prerequisite
------------
For the ZVOL commands to work for the VM owner, this user (or the `vboxusers` group in FreeBSD, for example) need to have access to some zfs management commands.  Usually you can allow that with the following command (provided `tank/vm/disks` is the root of the ZVOL hierarchy):

    zfs allow -g vboxusers clone,create,destroy,mount,rename,rollback,snapshot tank/vm/disks


Compatibility
-------------
The scripts have been tested under FreeBSD 10.3 running VirtualBox 5.1.22.  They need a working bash installation.


Copyright and License
---------------------
© 2017 — Antoine Delvaux — All rights reserved.

See enclosed LICENSE file.
