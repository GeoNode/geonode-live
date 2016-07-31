# geonode-live

This section describes how to build GeoNode-Live as described in [official ubuntu wiki](https://help.ubuntu.com/community/LiveCDCustomization). This document is based on the [OSGeo-Live build process](https://wiki.osgeo.org/wiki/Live_GIS_Build#Build_the_Live_DVD_ISO_image)

All you need is a running Ubuntu/Xubuntu/Kubuntu/Lubuntu installation at the exact same version as the target live system (even within a virtual machine as long as it has ~20GB free disk space).

All needed to be done are the following steps under a "user" account:

## Bootstrap the host operating system.

If you use the system to build more than once, then this must be done only for the first build

	host$ cd /tmp
	host$ wget https://github.com/terranodo/geonode-live/raw/master/bin/bootstrap.sh
	host$ chmod a+x bootstrap.sh
	host$ sudo ./bootstrap.sh

This will install Git and the install scripts, and create a link to them from your home directory.

## Build the iso.

	host$ cd ~/geonode-live/bin
	host$ sudo ./build_chroot.sh amd64 release master terranodo 2>&1 | tee /var/log/chroot-build.log

After the completion of the above script the new iso file is located in ~/livecdtmp.

## Repeat the process (Development mode).

In case you wish to rerun the build process, do not remove or move the lubuntu official iso located in this folder to skip downloading it again.
The folder ~/geonode-live is a git clone of the original repository so you can commit, pull and push changes to it.

	host$ cd ~/geonode-live
	host$ git pull origin master
	host$ cd bin
	host$ sudo ./build_chroot.sh amd64 nightly master terranodo 2>&1 | tee /var/log/chroot-build.log
