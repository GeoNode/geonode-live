#!/bin/sh
#############################################################################
#
# Purpose: This script bootstraps the GeoNode-Live build procedure.
#
#############################################################################
# Copyright (c) 2009-2016 Open Source Geospatial Foundation (OSGeo)
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
# Usage:
# sudo ./boostrap.sh [git_branch (default=master)] [GitHub_username (default=OSGeo)]
#############################################################################

SCRIPT_DIR=/usr/local/share

if [ -z "$USER_NAME" ] ; then 
    USER_NAME="user" 
fi 
USER_HOME="/home/$USER_NAME"

# Parse arguments to be able to build specific branch from specific git repository.
# Defaults to master branch and official OSGeo git repository.
if [ "$#" -eq 2 ]; then
    GIT_USER="$2"
    GIT_BRANCH="$1"
elif [ "$#" -eq 1 ]; then
    GIT_USER="terranodo"
    GIT_BRANCH="$1"
else
    GIT_USER="terranodo"
    GIT_BRANCH="master"
fi

# Check if user provided a clone url
if echo "$GIT_USER" | grep -q "://"; then
    GIT_REPO="$GIT_USER"
else
    GIT_REPO="https://github.com/$GIT_USER/geonode-live.git"
fi

echo "Running bootstrap.sh with the following settings:"
echo "GIT_REPO: $GIT_REPO"
echo "GIT_BRANCH: $GIT_BRANCH"

# Install git
apt-get --assume-yes install git

# Clone git repository to specified branch
cd "$SCRIPT_DIR"
git clone -b "$GIT_BRANCH" "$GIT_REPO" geonode-live
echo "Git clone finished."

chown -R "$USER_NAME":"$USER_NAME" geonode-live
cd "$USER_HOME"
ln -s "$SCRIPT_DIR/geonode-live" "$USER_HOME/geonode-live"
ln -s "$SCRIPT_DIR/geonode-live" /etc/skel/geonode-live

# make a directory for the install logs
mkdir -p /var/log/geonode-live/
chmod ug+wr /var/log/geonode-live/
chgrp adm /var/log/geonode-live/

