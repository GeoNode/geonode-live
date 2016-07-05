#!/bin/sh
#############################################################################
#
# Purpose: This is the main install script
#
#############################################################################
# Copyright (c) 2009-2016 Open Source Geospatial Foundation (OSGeo)
#
# Licensed under the GNU LGPL.
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


if [ "$#" -lt 2 ] || [ "$#" -gt 2 ]; then
    echo "Wrong number of arguments"
    echo "Usage: main.sh ARCH(i386 or amd64) MODE(release or nightly)"
    exit 1
fi

if [ "$1" != "i386" ] && [ "$1" != "amd64" ] ; then
    echo "Did not specify build architecture, try using i386 or amd64 as an argument"
    echo "Usage: main.sh ARCH(i386 or amd64) MODE(release or nightly)"
    exit 1
fi
ARCH="$1"

if [ "$2" != "release" ] && [ "$2" != "nightly" ] ; then
    echo "Did not specify build mode, try using release or nightly as an argument"
    echo "Usage: main.sh ARCH(i386 or amd64) MODE(release or nightly)"
    exit 1
fi
BUILD_MODE="$2"

echo "Running main.sh with the following settings:"
echo "ARCH: $ARCH"
echo "BUILD_MODE: $BUILD_MODE"

do_hr() {
   echo "==============================================================="
}

BUILD_DIR=`pwd`
if [ -z "$USER_NAME" ] ; then
   USER_NAME="user"
fi
USER_HOME="/home/$USER_NAME"



#############################################################################
do_hr
echo "Initial system setup"
do_hr
#############################################################################

# Don't install the kitchen sink
if [ ! -e /etc/apt/apt.conf.d/depends_only ] ; then
   cat << EOF > /etc/apt/apt.conf.d/depends_only
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
fi

# Only look for updates once a week
sed -i -e 's|\(APT::Periodic::Update-Package-Lists\) "1";|\1 "7";|' \
   /etc/apt/apt.conf.d/10periodic

# Pin down kernel version
echo "linux-image-generic hold" | dpkg --set-selections

# Install latest greatest security packages etc.
#TODO: Enabled or Disabled?
apt-get -q update
#apt-get --yes upgrade

# Add ppas
if [ "$BUILD_MODE" = "release" ] ; then
   cp ../sources.list.d/osgeolive.list /etc/apt/sources.list.d/
else
   cp ../sources.list.d/osgeolive-nightly.list /etc/apt/sources.list.d/
fi


# Add keys for repositories
# OSGeoLive key
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FADA29F7
# UbuntuGIS key
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160

apt-get -q update


# Install some useful stuff
apt-get install --yes wget less zip unzip git \
  patch vim nano screen iotop htop zenity


# Install virtualbox guest additions
apt-get install --yes virtualbox-guest-dkms virtualbox-guest-x11 virtualbox-guest-utils


# Add /usr/local/lib to /etc/ld.so.conf if needed, then run ldconfig
if [ -d /etc/ld.so.conf.d ] ; then
   echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local.conf
else
   if [ `grep -c '/usr/local/lib' /etc/ld.so.conf` -eq 0 ] ; then
      echo "/usr/local/lib" >> /etc/ld.so.conf
   fi
fi
ldconfig

# so we can see why things fail to start..
sed -i -e 's/^VERBOSE=no/VERBOSE=yes/' /etc/default/rcS


# Uninstall large applications installed by default
apt-get remove --yes \
   pidgin-data libsane libsane-common libsane-hpaio libieee1284-3 \
   gnumeric-common abiword-common gnumeric abiword

# regen initrd
depmod

# Remove unused home directories
#rm -fr "$USER_HOME"/Documents
rm -fr "$USER_HOME"/Pictures
rm -fr "$USER_HOME"/Music
rm -fr "$USER_HOME"/Public
rm -fr "$USER_HOME"/Templates
rm -fr "$USER_HOME"/Videos
# and don't come back now
apt-get --assume-yes remove xdg-user-dirs

# .. and remove any left-over package cruft
apt-get --assume-yes autoremove

# Create Geospatial folder on Desktop
mkdir -p "$USER_HOME"/Desktop/Geospatial

# Link to the project data files
cd "$USER_HOME"
mkdir -p /usr/local/share/data --verbose
ln -s /usr/local/share/data data
chown -h "$USER_NAME":"$USER_NAME" data
ln -s /usr/local/share/data /etc/skel/data


# and there was music and laughter and much rejoicing
adduser user audio

# highly useful tricks
#  (/etc/skel/.bashrc seems to be clobbered by the copy in USER_HOME)
cat << EOF >> "$USER_HOME"/.bashrc

# help avoid dumb mistakes
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

EOF
sed -i -e 's/ls --color=auto/ls --color=auto -F/' "$USER_HOME"/.bashrc
chown "$USER_NAME":"$USER_NAME" "$USER_HOME"/.bashrc


cat << EOF >> "$USER_HOME"/.inputrc
# a conference talk full of terminal beeps is no good
set prefer-visible-bell

# -------- Bind page up/down with history search ---------
"\e[5~": history-search-backward
"\e[6~": history-search-forward
EOF
chown "$USER_NAME":"$USER_NAME" "$USER_HOME"/.inputrc
cp "$USER_HOME"/.inputrc /etc/skel/
cp "$USER_HOME"/.inputrc /root/



#############################################################################
do_hr
echo "Installing C/Python Development files"
do_hr
#############################################################################
cd "$BUILD_DIR"

apt-get -q update

# Install C development packages
apt-get install --yes build-essential pkg-config libxml2-dev libxslt-dev

# Install OSGeo C stack libraries
apt-get install --yes libgdal20 gdal-bin proj-bin libgeos-c1v5 geotiff-bin

# Install Python development packages
apt-get install --yes python-all-dev python-virtualenv

# Install Python GDAL packages
apt-get install --yes python-gdal python-rasterio python-fiona fiona rasterio



#############################################################################
do_hr
echo "Installing Java"
do_hr
#############################################################################
cd "$BUILD_DIR"

#apt-get install --yes default-jdk default-jre
apt-get install --yes openjdk-8-jdk openjdk-8-jre default-jre

# Detect build architecture for JAVA_HOME default
if [ "$ARCH" = "i386" ] ; then
    ln -s /usr/lib/jvm/java-8-openjdk-i386 /usr/lib/jvm/default-java
fi

if [ "$ARCH" = "amd64" ] ; then
    ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/default-java
fi



#############################################################################
do_hr
echo "Installing Apache"
do_hr
#############################################################################
cd "$BUILD_DIR"

apt-get install --yes apache2
adduser "$USER_NAME" www-data



#############################################################################
do_hr
echo "Installing Tomcat"
do_hr
#############################################################################
cd "$BUILD_DIR"

apt-get install --yes tomcat8 tomcat8-admin

cp ../conf/tomcat/tomcat-users.xml \
   /etc/tomcat8/tomcat-users.xml

chown tomcat8:tomcat8 /etc/tomcat8/tomcat-users.xml

# something screwed up with the ISO permissions:
chgrp tomcat8 /usr/share/tomcat8/bin/*.sh
adduser "$USER_NAME" tomcat8

service tomcat8 stop

# Assign 1GB of RAM to default tomcat
sed -i -e 's/-Xmx128m/-Xmx1024m/' /etc/default/tomcat8



#############################################################################
do_hr
echo "Installing PostgreSQL"
do_hr
#############################################################################
cd "$BUILD_DIR"
PG_VERSION="9.5"

# debug
echo "#DEBUG The locale settings are currently:"
locale
echo "------------------------------------"

# DB is created in the current locale, which was reset to "C". Put it
# back to UTF so the templates will be created using UTF8 encoding.
unset LC_ALL
update-locale LC_ALL=en_US.UTF-8
export LC_NUMERIC="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_PAPER="en_US.UTF-8"
export LC_NAME="en_US.UTF-8"
export LC_ADDRESS="en_US.UTF-8"
export LC_TELEPHONE="en_US.UTF-8"
export LC_MEASUREMENT="en_US.UTF-8"
export LC_IDENTIFICATION="en_US.UTF-8"

# debug
echo "#DEBUG The locale settings updated:"
locale
echo "------------------------------------"

apt-get install --yes postgresql-"$PG_VERSION" pgadmin3

### config ###
service postgresql start
#set default user/password to the system user for easy login
sudo -u postgres createuser --superuser $USER_NAME

echo "alter role \"user\" with password 'user'" > /tmp/build_postgres.sql
sudo -u postgres psql -f /tmp/build_postgres.sql
# rm /tmp/build_postgre.sql

#add a gratuitous db called user to avoid psql inconveniences
sudo -u $USER_NAME createdb -E UTF8 $USER_NAME
sudo -u "$USER_NAME" psql -d "$USER_NAME" -c 'VACUUM ANALYZE;'

#include pgadmin3 profile for connection
for FILE in  pgadmin3  pgpass  ; do
    cp ../conf/postgresql/"$FILE" "$USER_HOME/.$FILE"

    chown $USER_NAME:$USER_NAME "$USER_HOME/.$FILE"
    chmod 600 "$USER_HOME/.$FILE"
done



#############################################################################
do_hr
echo "Installing PostGIS"
do_hr
#############################################################################
cd "$BUILD_DIR"

apt-get install --yes postgis "postgresql-$PG_VERSION-postgis-2.2"

#enable gdal drivers
cat << EOF >> "/var/lib/postgresql/$PG_VERSION/main/postgresql.auto.conf"

## https://trac.osgeo.org/gdal/wiki/SecurityIssues
postgis.gdal_enabled_drivers = 'ENABLE_ALL'
postgis.enable_outdb_rasters = TRUE

EOF

#shp2pgsql-gui desktop launcher
cat << EOF > /usr/share/applications/shp2pgsql-gui.desktop
[Desktop Entry]
Type=Application
Name=shp2pgsql
Comment=Shapefile to PostGIS Import Tool
Categories=Application;Geography;Geoscience;Education;
Exec=shp2pgsql-gui
Icon=pgadmin3
Terminal=false
EOF

cp -a /usr/share/applications/shp2pgsql-gui.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/Desktop/Geospatial/shp2pgsql-gui.desktop"



#############################################################################
do_hr
echo "Installing OSM sample data"
do_hr
#############################################################################
cd "$BUILD_DIR"

CITY="BONN_DE"

mkdir -p /usr/local/share/osm
cd /usr/local/share/osm

wget -N --progress=dot:mega \
   "http://download.osgeo.org/livedvd/data/osm/$CITY/$CITY.osm.bz2"

mkdir -p /usr/local/share/data/osm --verbose
ln -s /usr/local/share/osm/"$CITY.osm.bz2" /usr/local/share/data/osm/
ln -s /usr/local/share/data/osm/"$CITY.osm.bz2" \
   /usr/local/share/data/osm/feature_city.osm.bz2

apt-get install --yes --no-install-recommends osm2pgsql

sudo -u $USER_NAME createdb osm_local
sudo -u $USER_NAME psql osm_local -c 'create extension postgis;'

sudo -u $USER_NAME osm2pgsql -U $USER_NAME \
     --database osm_local --latlong \
     --style /usr/share/osm2pgsql/default.style \
     /usr/local/share/data/osm/feature_city.osm.bz2



#############################################################################
do_hr
echo "Installing MapServer"
do_hr
#############################################################################
cd "$BUILD_DIR"

apt-get install --yes cgi-mapserver mapserver-bin python-mapscript

service apache2 --full-restart



#############################################################################
do_hr
echo "Installing Mapnik"
do_hr
#############################################################################
cd "$BUILD_DIR"

MAPNIK_DATA="/usr/local/share/mapnik"

apt-get install --yes libmapnik3.0 mapnik-utils python-mapnik \
      python-werkzeug tilestache python-modestmaps

cd /tmp
# download Tilestache demo
wget -N --progress=dot:mega \
   "http://download.osgeo.org/livedvd/data/mapnik/tilestache_demo.tar.gz"

tar zxf tilestache_demo.tar.gz
mkdir -p "$MAPNIK_DATA"/demo/
cp demo/* "$MAPNIK_DATA"/demo/
rm -rf demo

# Create startup script for TileStache Mapnik Server
cat << EOF > "/usr/local/bin/mapnik_start_tilestache.sh"
#!/bin/sh
tilestache-server -c /usr/local/share/mapnik/demo/tilestache.cfg -p 8012
EOF

chmod 755 "/usr/local/bin/mapnik_start_tilestache.sh"

## Create Desktop Shortcut for starting Tilestache Server in shell
cat << EOF > /usr/share/applications/mapnik-start.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Mapnik & TileStache Start
Comment=Mapnik tile-serving using TileStache Server
Categories=Application;Geography;Geoscience;Education;
Exec=mapnik_start_tilestache.sh
Icon=gnome-globe
Terminal=true
StartupNotify=false
EOF

cp -a /usr/share/applications/mapnik-start.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R $USER_NAME:$USER_NAME "$USER_HOME/Desktop/Geospatial/mapnik-start.desktop"

# share data with the rest of the disc
mkdir -p /usr/local/share/data/vector
rm -f /usr/local/share/data/vector/world_merc
ln -s /usr/local/share/mapnik/demo \
      /usr/local/share/data/vector/world_merc

#############################################################################
do_hr
echo "Installing QGIS"
do_hr
#############################################################################
cd "$BUILD_DIR"

apt-get install --yes qgis qgis-common python-qgis python-qgis-common

# Install optional packages that some plugins use
apt-get --assume-yes install python-psycopg2 \
   python-gdal python-matplotlib python-qt4-sql \
   libqt4-sql-psql python-qwt5-qt4 python-tk \
   python-sqlalchemy python-owslib python-shapely

# Install selected plugins
cd /tmp
wget -c --progress=dot:mega \
   "http://download.osgeo.org/livedvd/data/qgis/python-qgis-osgeolive_9.5-1_all.deb"
dpkg -i python-qgis-osgeolive_9.5-1_all.deb
rm -rf python-qgis-osgeolive_9.5-1_all.deb

#Make sure old qt uim isn't installed
apt-get --assume-yes remove uim-qt uim-qt3

#### install desktop icon ####
QGIS_VERSION=`dpkg -s qgis | grep '^Version:' | awk '{print $2}' | cut -f1 -d~`
if [ ! -e /usr/share/applications/qgis.desktop ] ; then
   cat << EOF > /usr/share/applications/qgis.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Quantum GIS
Comment=QGIS $QGIS_VERSION
Categories=Application;Education;Geography;
Exec=/usr/bin/qgis %F
Icon=/usr/share/icons/qgis-icon.xpm
Terminal=false
StartupNotify=false
Categories=Education;Geography;Qt;
MimeType=application/x-qgis-project;image/tiff;image/jpeg;image/jp2;application/x-raster-aig;application/x-mapinfo-mif;application/x-esri-shape;
EOF
else
   sed -i -e 's/^Name=QGIS Desktop/Name=QGIS/' \
      /usr/share/applications/qgis.desktop
fi

cp /usr/share/applications/qgis.desktop "$USER_HOME/Desktop/Geospatial/"
cp /usr/share/applications/qbrowser.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R $USER_NAME.$USER_NAME "$USER_HOME/Desktop/Geospatial/qgis.desktop"
chown -R $USER_NAME.$USER_NAME "$USER_HOME/Desktop/Geospatial/qbrowser.desktop"



#############################################################################
do_hr
echo "Installing MapProxy"
do_hr
#############################################################################
cd "$BUILD_DIR"

MAPPROXY_DIR="/usr/local/share/mapproxy"
mkdir -p $MAPPROXY_DIR

apt-get install --yes python-mapproxy

# Create startup script for MapProxy Server
cat << EOF > /usr/local/bin/mapproxy_start.sh
#!/bin/sh
mapproxy-util serve-develop -b 0.0.0.0:8011 /usr/local/share/mapproxy/mapproxy.yaml
EOF

chmod 755 /usr/local/bin/mapproxy_start.sh

## Create Desktop Shortcut for starting MapProxy Server in shell
cat << EOF > /usr/share/applications/mapproxy-start.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=MapProxy Start
Comment=MapProxy
Categories=Application;Geography;Geoscience;Education;
Exec=lxterminal -e mapproxy_start.sh
Icon=gnome-globe
Terminal=false
StartupNotify=false
EOF

cp -a /usr/share/applications/mapproxy-start.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R $USER_NAME:$USER_NAME "$USER_HOME/Desktop/Geospatial/mapproxy-start.desktop"

cat << EOF > /usr/share/applications/mapproxy-demo.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=MapProxy demo
Comment=MapProxy
Categories=Application;Geography;Geoscience;Education;
Exec=firefox "http://localhost:8011/demo/"
Icon=gnome-globe
Terminal=false
EOF

cp -a /usr/share/applications/mapproxy-demo.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R $USER_NAME:$USER_NAME "$USER_HOME/Desktop/Geospatial/mapproxy-demo.desktop"

echo "Creating Configuration"
cp ../conf/mapproxy/mapproxy.yaml "$MAPPROXY_DIR/mapproxy.yaml"

# allow the user to write to it, via group permissions
chgrp users "$MAPPROXY_DIR/mapproxy.yaml"
chmod g+w "$MAPPROXY_DIR/mapproxy.yaml"



#############################################################################
do_hr
echo "Installing GeoServer"
do_hr
#############################################################################
cd "$BUILD_DIR"

TOMCAT_USER_NAME="tomcat8"
TOMCAT_INSTALL_DIR="/var/lib/${TOMCAT_USER_NAME}/webapps"


wget -c --progress=dot:mega \
   -O "$TOMCAT_INSTALL_DIR"/geoserver.war \
   "http://build.geonode.org/geoserver/latest/geoserver.war"

# Create startup script for GeoServer
if [ ! -e /usr/local/bin/geoserver_start.sh ] ; then
    cat << EOF > /usr/local/bin/geoserver_start.sh
    #!/bin/bash
    STAT=\`sudo service "$TOMCAT_USER_NAME" status | grep pid\`
    if [ -z "\$STAT" ] ; then
        sudo service "$TOMCAT_USER_NAME" start
        (sleep 2; echo "25"; sleep 2; echo "50"; sleep 2; echo "75"; sleep 2; echo "100") \
     | zenity --progress --auto-close --text "GeoServer starting"
    fi
    firefox "http://localhost:8080/geoserver/"
EOF
fi

# Create shutdown script for GeoServer
if [ ! -e /usr/local/bin/geoserver_stop.sh ] ; then
    cat << EOF > /usr/local/bin/geoserver_stop.sh
    #!/bin/bash
    STAT=\`sudo service "$TOMCAT_USER_NAME" status | grep pid\`
    if [ -n "\$STAT" ] ; then
        sudo service "$TOMCAT_USER_NAME" stop
        zenity --info --text "GeoServer stopped"
    fi
EOF
fi

chmod 755 /usr/local/bin/geoserver_start.sh
chmod 755 /usr/local/bin/geoserver_stop.sh

echo "Installing GeoServer icons"
cp -f "$BUILD_DIR/../conf/geoserver/geoserver_48x48.logo.png" \
       /usr/share/icons/

## start icon
cat << EOF > /usr/share/applications/geoserver-start.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=GeoServer Start
Comment=GeoServer
Categories=Application;Geography;Geoscience;Education;
Exec=/usr/local/bin/geoserver_start.sh
Icon=/usr/share/icons/geoserver_48x48.logo.png
Terminal=false
EOF

cp -a /usr/share/applications/geoserver-start.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/Desktop/Geospatial/geoserver-start.desktop"

## stop icon
cat << EOF > /usr/share/applications/geoserver-stop.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=GeoServer Stop
Comment=GeoServer
Categories=Application;Geography;Geoscience;Education;
Exec=/usr/local/bin/geoserver_stop.sh
Icon=/usr/share/icons/geoserver_48x48.logo.png
Terminal=false
EOF

cp -a /usr/share/applications/geoserver-stop.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/Desktop/Geospatial/geoserver-stop.desktop"

## admin console icon
cat << EOF > /usr/share/applications/geoserver-admin.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=GeoServer Admin
Comment=GeoServer
Categories=Application;Geography;Geoscience;Education;
Exec=firefox "http://localhost:8080/geoserver/"
Icon=/usr/share/icons/geoserver_48x48.logo.png
Terminal=false
EOF

cp -a /usr/share/applications/geoserver-admin.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/Desktop/Geospatial/geoserver-admin.desktop"



#############################################################################
do_hr
echo "Installing GeoNode"
do_hr
#############################################################################
cd "$USER_HOME"




#############################################################################
do_hr
echo "Configuring Desktop"
do_hr
#############################################################################
cd "$BUILD_DIR"





#############################################################################
do_hr
echo "Cleanup"
do_hr
#############################################################################
cd "$BUILD_DIR"

# by removing the 'user', it also meant that 'user' was removed from /etc/group
#  so we have to put it back at boot time.
if [ `grep -c 'adduser' /etc/rc.local` -eq 0 ] ; then
    sed -i -e 's|exit 0||' /etc/rc.local

    GRPS="users tomcat8 www-data staff fuse plugdev audio dialout pulse"

    for GRP in $GRPS ; do
       echo "adduser $USER_NAME $GRP" >> /etc/rc.local
    done
    echo >> /etc/rc.local
    echo "exit 0" >> /etc/rc.local
fi

# remove any leftover orphans
apt-get --yes autoremove

chmod g-w /usr
chmod g-w /usr/bin
chmod g-w /usr/lib
chmod g-w /usr/share

# now that everything is installed rebuild library search cache
ldconfig

# srcpkgcache.bin can be dropped; not updating it all the time helps save
# space on persistent USBs. https://wiki.ubuntu.com/ReducingDiskFootprint
rm -f /var/cache/apt/srcpkgcache.bin
cat << EOF > /etc/apt/apt.conf.d/02nocache
Dir::Cache {
  srcpkgcache "";
}
EOF

# remove the apt-get cache
apt-get clean

echo "linux-image-generic install" | dpkg --set-selections

rm -fr \
  "$USER_HOME"/.bash_history \
  "$USER_HOME"/.ssh \

# clean out ssh keys which should be machine-unique
rm -f /etc/ssh/ssh_host_*_key*
# change a stupid sshd default
if [ -e /etc/ssh/sshd_config ] ; then
   sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
fi

# Start tomcat to ensure all applications are deployed
service tomcat8 start
sleep 120
service tomcat8 stop

# Disable auto-deploy to prevent applications to get removed after removing war files
# TODO: Add some note to wiki for users that want to deploy their own tomcat applications
sed -i -e 's/unpackWARs="true"/unpackWARs="false"/' -e 's/autoDeploy="true"/autoDeploy="false"/' \
    /etc/tomcat8/server.xml

# Cleaning up war files to save disk space
rm -f /var/lib/tomcat8/webapps/*.war

# Disabling default tomcat startup
#update-rc.d -f tomcat7 remove
systemctl disable tomcat8.service

if [ ! -e /etc/sudoers.d/tomcat ] ; then
   cat << EOF > /etc/sudoers.d/tomcat
%users ALL=(root) NOPASSWD: /usr/sbin/service tomcat8 start,/usr/sbin/service tomcat8 stop,/usr/sbin/service tomcat8 status
EOF
fi
chmod 440 /etc/sudoers.d/tomcat

# Switching to default IPv6
rm /etc/gai.conf
mv /etc/gai.conf.orig /etc/gai.conf

# stop PostgreSQL and Apache to avoid them thinking a crash happened next boot
service postgresql stop
service apache2 stop
