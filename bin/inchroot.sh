#!/bin/sh
#############################################################################
#
# Purpose: Creating GeoNode-Live as an Ubuntu customization. In chroot part
#     https://help.ubuntu.com/community/LiveCDCustomization
#
#############################################################################
# Copyright (c) 2010-2016 Open Source Geospatial Foundation (OSGeo)
# Copyright (c) 2009 LISAsoft
#
# Licensed under the GNU LGPL version >= 2.1.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 2.1 of the License,
# or any later version.  This library is distributed in the hope that
# it will be useful, but WITHOUT ANY WARRANTY, without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Lesser General Public License for more details, either
# in the "LICENSE.LGPL.txt" file distributed with this software or at
# web page "http://www.fsf.org/licenses/lgpl.html".
#############################################################################

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Wrong number of arguments"
    echo "Usage: inchroot.sh ARCH(i386 or amd64) MODE(release or nightly) [git_branch (default=master)] [github_username (default=terranodo) or git clone url]"
    exit 1
fi

if [ "$1" != "i386" ] && [ "$1" != "amd64" ] ; then
    echo "Did not specify build architecture, try using i386 or amd64 as an argument"
    echo "Usage: inchroot.sh ARCH(i386 or amd64) MODE(release or nightly) [git_branch (default=master)] [github_username (default=terranodo) or git clone url]"
    exit 1
fi
ARCH="$1"

if [ "$2" != "release" ] && [ "$2" != "nightly" ] ; then
    echo "Did not specify build mode, try using release or nightly as an argument"
    echo "Usage: inchroot.sh ARCH(i386 or amd64) MODE(release or nightly) [git_branch (default=master)] [github_username (default=terranodo) or git clone url]"
    exit 1
fi
BUILD_MODE="$2"

if [ "$#" -eq 4 ]; then
    GIT_BRANCH="$3"
    GIT_USER="$4"
elif [ "$#" -eq 3 ]; then
    GIT_BRANCH="$3"
    GIT_USER="terranodo"
else
    GIT_BRANCH="master"
    GIT_USER="terranodo"
fi

run_installer()
{
  SCRIPT=$1
  echo "===================================================================="
  echo "Starting: $SCRIPT"
  echo "===================================================================="
  sh "$SCRIPT"
}

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts

# To avoid locale issues and in order to import GPG keys
export HOME=/roots
export LC_ALL=C

# TODO: Check/ask if this needs to be done in 16.04
dbus-uuidgen > /var/lib/dbus/machines-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# Adding "user" to help the build process
adduser user --disabled-password --gecos user

# Change ID under 999 so that iso boot does not fail
# usermod -u 500 user
mkdir -p /home/user/Desktop
chown user:user /home/user/Desktop

# Fixing some IPv6 problems for the build server
mv /etc/gai.conf /etc/gai.conf.orig
cat << EOF > /etc/gai.conf
precedence ::ffff:0:0/96  100
EOF

cd /tmp/

chmod a+x bootstrap.sh

./bootstrap.sh "$GIT_BRANCH" "$GIT_USER"

cd /usr/local/share/geonode-live/bin

# Copy external version information to be able to rename the builds
cp /tmp/VERSION.txt /usr/local/share/geonode-live/
cp /tmp/CHANGES.txt /usr/local/share/geonode-live/

#######################################################
# Replacement for main.sh
#######################################################
USER_NAME="user"
export USER_NAME

#./setup.sh "$BUILD_MODE"

#######################################################
# End of main.sh
#######################################################

# Save space on ISO by removing the .git dir
#NEAR_RC=1
#if [ "$NEAR_RC" -eq 1 ] ; then
#    rm -rf /usr/local/share/geonode-live/.git
#fi

# user shouldn't own outside of /home, but a group can
chown -R root.staff /usr/local/share/geonode-live
chmod -R g+w /usr/local/share/geonode-live

# Update the file search index
updatedb

# Experimental dist variant, comment out and swap to backup below
# Do we need to change the user to ubuntu in all scripts for this method?
# -- No, set user in casper.conf
tar -zcf /tmp/user_home.tar.gz -C /home/user .
tar -zxf /tmp/user_home.tar.gz -C /etc/skel .
rm /tmp/user_home.tar.gz
cp -a /home/user/*  /etc/skel
chown -hR root:root /etc/skel

deluser --remove-home user

# Copy casper.conf with default username and hostname
cp /usr/local/share/geonode-live/conf/chroot/casper.conf /etc/casper.conf

# After the build
# Check for users above 999
awk -F: '$3 > 999' /etc/passwd

#### Cleanup ####

# Be sure to remove any temporary files which are no longer needed, as space on a CD is limited
apt-get clean

# Delete temporary files
rm -rf /tmp/* ~/.bash_history

# Delete hosts file
rm /etc/hosts

# Nameserver settings
rm /etc/resolv.conf
ln -s /run/resolvconf/resolv.conf /etc/resolv.conf

# If you installed software, be sure to run 
rm /var/lib/dbus/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

# Now umount (unmount) special filesystems and exit chroot 
umount /proc || umount -lf /proc
umount /sys
umount /dev/pts
