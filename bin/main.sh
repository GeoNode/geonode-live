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
   #cp ../sources.list.d/osgeolive-nightly.list /etc/apt/sources.list.d/
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
  patch vim nano screen iotop htop zenity sed


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

apt-get clean
apt-get -q update

# Install C development packages
apt-get install --yes build-essential pkg-config libxml2-dev libxslt-dev \
    libpq-dev postgresql-client-common postgresql-client gettext zlib1g-dev \
    libjpeg-dev libpng-dev

# Install OSGeo C stack libraries
apt-get install --yes libgdal20 gdal-bin proj-bin libgeos-c1v5 geotiff-bin \
    libgeos-dev libproj-dev

# Install Python development packages
apt-get install --yes python-all-dev python-virtualenv virtualenv python-pip \
    python-imaging python-lxml python-pyproj python-shapely python-nose \
    python-httplib2 python-psycopg2 python-software-properties virtualenvwrapper

# Install Python GDAL packages
apt-get install --yes python-gdal python-rasterio python-fiona fiona rasterio

# Install Ansible
apt-get install --yes ansible

# Install Docker
apt-get install --yes docker docker-compose



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

# Switch apache port not to conflict with nginx
sed -i -e 's|Listen 80|Listen 81|' \
   /etc/apache2/ports.conf

service apache2 restart



#############################################################################
do_hr
echo "Installing nginx"
do_hr
#############################################################################
cd "$BUILD_DIR"

apt-get install --yes nginx
cp ../conf/nginx/nginx.conf /etc/nginx/sites-available/default

service nginx stop



#############################################################################
do_hr
echo "Installing uwsgi"
do_hr
#############################################################################
cd "$BUILD_DIR"

apt-get install --yes uwsgi-emperor uwsgi-plugin-python

service uwsgi-emperor stop


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
sed -i -e 's/port="8080"/port="8081"/' /etc/tomcat8/server.xml



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

apt-get install --yes postgresql-"$PG_VERSION" pgadmin3 postgresql-contrib

### config ###
cp "$BUILD_DIR"/../conf/postgresql/pg_hba.conf /etc/postgresql/"$PG_VERSION"/main/pg_hba.conf

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

apt-get install --yes postgis postgis-gui "postgresql-$PG_VERSION-postgis-2.2"

#enable gdal drivers
cat << EOF >> "/var/lib/postgresql/$PG_VERSION/main/postgresql.auto.conf"

## https://trac.osgeo.org/gdal/wiki/SecurityIssues
postgis.gdal_enabled_drivers = 'ENABLE_ALL'
postgis.enable_outdb_rasters = TRUE

EOF

# #shp2pgsql-gui desktop launcher
# cat << EOF > /usr/share/applications/shp2pgsql-gui.desktop
# [Desktop Entry]
# Type=Application
# Name=shp2pgsql
# Comment=Shapefile to PostGIS Import Tool
# Categories=Application;Geography;Geoscience;Education;
# Exec=shp2pgsql-gui
# Icon=pgadmin3
# Terminal=false
# EOF

# cp -a /usr/share/applications/shp2pgsql-gui.desktop "$USER_HOME/Desktop/Geospatial/"
# chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/Desktop/Geospatial/shp2pgsql-gui.desktop"



#############################################################################
do_hr
echo "Installing OpenLayers"
do_hr
#############################################################################
cd "$BUILD_DIR"

apt-get install --yes libjs-openlayers javascript-common



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

apt-get install --yes --no-install-recommends osm2pgsql osmosis

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

MAPSERVER_DATA="/usr/local/share/mapserver"
MS_APACHE_CONF_FILE="mapserver.conf"
APACHE_CONF_DIR="/etc/apache2/conf-available/"
APACHE_CONF_ENABLED_DIR="/etc/apache2/conf-enabled/"
MS_APACHE_CONF=$APACHE_CONF_DIR$MS_APACHE_CONF_FILE

apt-get install --yes cgi-mapserver mapserver-bin python-mapscript

cd /tmp
wget -c --progress=dot:mega \
   "http://download.osgeo.org/livedvd/data/mapserver/mapserver-itasca-ms70.zip"

# Install demos
if [ ! -d "$MAPSERVER_DATA" ] ; then
    mkdir -p "$MAPSERVER_DATA"/demos

    echo -n "Done\nExtracting MapServer itasca demo in $MAPSERVER_DATA/demos/..."
    unzip -q "/tmp/mapserver-itasca-ms70.zip" -d "$MAPSERVER_DATA"/demos/
    echo "Done"

    mv "$MAPSERVER_DATA/demos/mapserver-demo-master" "$MAPSERVER_DATA/demos/itasca"
    rm -rf "$MAPSERVER_DATA/demos/ms4w"

    echo -n "Patching itasca.map to enable WMS..."
    rm "$MAPSERVER_DATA"/demos/itasca/itasca.map
    wget -c --progress=dot:mega \
        "https://github.com/mapserver/mapserver-demo/raw/master/itasca.map" \
        -O "$MAPSERVER_DATA"/demos/itasca/itasca.map
    echo -n "Done"

    echo "Configuring the system...."
    # Itasca Demo hacks
    mkdir -p /usr/local/www/docs_maps/
    ln -s "$MAPSERVER_DATA"/demos/itasca "$MAPSERVER_DATA"/demos/workshop
    ln -s /usr/local/share/mapserver/demos /usr/local/www/docs_maps/mapserver_demos
    ln -s /tmp /usr/local/www/docs_maps/tmp
    ln -s /tmp /var/www/html/tmp
fi

# Copy Mapserver demo files
mkdir -p /var/www/html/demo/mapserver
cp "$BUILD_DIR"/../conf/mapserver/* /var/www/html/demo/mapserver/
mv /var/www/html/demo/mapserver/mapserver_demo.html /var/www/html/demo/mapserver/index.html

# Add 4326 to WMS Capabilities
sed -i -e 's/WMS_SRS "EPSG:26915"/WMS_SRS "EPSG:26915 EPSG:4326"/' /usr/local/www/docs_maps/mapserver_demos/workshop/itasca.map

# Add MapServer apache configuration
cat << EOF > "$MS_APACHE_CONF"
EnableSendfile off
DirectoryIndex index.phtml
Alias /mapserver "/usr/local/share/mapserver"
Alias /ms_tmp "/tmp"
Alias /tmp "/tmp"
Alias /mapserver_demos "/usr/local/share/mapserver/demos"

<Directory "/usr/local/share/mapserver">
  Require all granted
  Options +Indexes
</Directory>

<Directory "/usr/local/share/mapserver/demos">
  Require all granted
  Options +Indexes
</Directory>

<Directory "/tmp">
  Require all granted
  Options +Indexes
</Directory>
EOF

a2enconf $MS_APACHE_CONF_FILE
echo "Finished configuring Apache"

cat << EOF > "/usr/share/applications/mapserver.desktop"
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=MapServer Demo
Comment=Mapserver
Categories=Application;Geography;Geoscience;Education;
Exec=firefox "http://localhost/demo/mapserver/"
Icon=gnome-globe
Terminal=false
StartupNotify=false
EOF

cp /usr/share/applications/mapserver.desktop "$USER_HOME/Desktop/Geospatial/"
chown "$USER_NAME.$USER_NAME" "$USER_HOME/Desktop/Geospatial/mapserver.desktop"

# share data with the rest of the disc
ln -s /usr/local/share/mapserver/demos/itasca/data \
      /usr/local/share/data/itasca

service apache2 --full-restart



#############################################################################
do_hr
echo "Installing Mapnik"
do_hr
#############################################################################
cd "$BUILD_DIR"

MAPNIK_DATA="/usr/local/share/mapnik"

apt-get install --yes libmapnik3.0 mapnik-utils python-mapnik \
      python-werkzeug tilestache python-modestmaps libjs-modestmaps

cd /tmp
# download Tilestache demo
wget -N --progress=dot:mega \
   "http://download.osgeo.org/livedvd/data/mapnik/tilestache_demo.tar.gz"

tar zxf tilestache_demo.tar.gz
mkdir -p "$MAPNIK_DATA"/demo/
cp demo/* "$MAPNIK_DATA"/demo/
rm -rf demo

# # Create startup script for TileStache Mapnik Server
# cat << EOF > "/usr/local/bin/mapnik_start_tilestache.sh"
# #!/bin/sh
# tilestache-server -c /usr/local/share/mapnik/demo/tilestache.cfg -p 8012
# EOF

# chmod 755 "/usr/local/bin/mapnik_start_tilestache.sh"

mkdir -p /var/www/html/demo/tilestache
cp "$BUILD_DIR"/../conf/tilestache/index.html /var/www/html/demo/tilestache/

## Create Desktop Shortcut for starting Tilestache Server in shell
cat << EOF > /usr/share/applications/mapnik-start.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=TileStache Demo
Comment=Mapnik tile-serving using TileStache Server
Categories=Application;Geography;Geoscience;Education;
Exec=firefox "http://localhost/demo/tilestache/"
Icon=gnome-globe
Terminal=false
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
   "http://download.osgeo.org/livedvd/data/qgis/python-qgis-osgeolive_10.0-1_all.deb"
dpkg -i python-qgis-osgeolive_10.0-1_all.deb
rm -rf python-qgis-osgeolive_10.0-1_all.deb

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

mkdir -p /usr/local/share/qgis
cp "$BUILD_DIR/../conf/qgis/QGIS-Itasca-Example.qgs" /usr/local/share/qgis/
cp "$BUILD_DIR/../conf/qgis/QGIS-NaturalEarth-Example.qgs" /usr/local/share/qgis/
chmod 664 /usr/local/share/qgis/*.qgs
chgrp users /usr/local/share/qgis/*.qgs

# Load default settings
mkdir -p "$USER_HOME"/.config/QGIS
cp "$BUILD_DIR/../conf/qgis/QGIS2.conf" "$USER_HOME"/.config/QGIS/



#############################################################################
do_hr
echo "Installing QGIS Server"
do_hr
#############################################################################
cd "$BUILD_DIR"

## get qgis_mapserver
apt-get install --assume-yes qgis-server libapache2-mod-fcgid

# Make sure Apache has cgi-bin setup, and that fcgid is enabled
a2enmod cgi
a2enmod fcgid

cp "$BUILD_DIR"/../conf/qgis-server/qgis-fcgid.conf /etc/apache2/conf-available/
a2enconf qgis-fcgid.conf

#Sample project
ln -s /usr/local/share/qgis/QGIS-Itasca-Example.qgs /usr/lib/cgi-bin/

QGIS_SERVER_PKG_DATA=/usr/local/share/qgis_mapserver
mkdir -p "$QGIS_SERVER_PKG_DATA"
cd "$QGIS_SERVER_PKG_DATA"
cp "$BUILD_DIR"/../conf/qgis-server/mapviewer.html .
tar xzf "$BUILD_DIR"/../conf/qgis-server/mapfish-client-libs.tgz --no-same-owner

# Create link to www folder
ln -s /usr/local/share/qgis_mapserver /var/www/html/demo/qgis-server
ln -s /usr/local/share/qgis_mapserver/mapviewer.html /usr/local/share/qgis_mapserver/index.html

# Create Desktop Shortcut for Demo viewer
cat << EOF > /usr/share/applications/qgis-mapserver.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=QGIS Server Demo
Comment=QGIS Server
Categories=Application;Geography;Geoscience;Education;
Exec=firefox "http://localhost/demo/qgis-server/"
Icon=gnome-globe
Terminal=false
StartupNotify=false
EOF

cp -a /usr/share/applications/qgis-mapserver.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R $USER_NAME:$USER_NAME "$USER_HOME/Desktop/Geospatial/qgis-mapserver.desktop"

# cat << EOF > /usr/share/applications/qgis-mapserver-wms.desktop
# [Desktop Entry]
# Type=Application
# Encoding=UTF-8
# Name=QGIS Server WMS
# Comment=QGIS Server
# Categories=Application;Geography;Geoscience;Education;
# Exec=firefox "http://localhost/qgis/QGIS-NaturalEarth-Example?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetCapabilities"
# Icon=gnome-globe
# Terminal=false
# StartupNotify=false
# EOF

# cp -a /usr/share/applications/qgis-mapserver-wms.desktop "$USER_HOME/Desktop/Geospatial/"
# chown -R $USER_NAME:$USER_NAME "$USER_HOME/Desktop/Geospatial/qgis-mapserver-wms.desktop"

# Reload Apache
service apache2 --full-restart



#############################################################################
do_hr
echo "Installing MapProxy"
do_hr
#############################################################################
cd "$BUILD_DIR"

MAPPROXY_DIR="/usr/local/share/mapproxy"
mkdir -p $MAPPROXY_DIR

apt-get install --yes python-mapproxy

# # Create startup script for MapProxy Server
# cat << EOF > /usr/local/bin/mapproxy_start.sh
# #!/bin/sh
# mapproxy-util serve-develop -b 0.0.0.0:8011 /usr/local/share/mapproxy/mapproxy.yaml
# EOF

# chmod 755 /usr/local/bin/mapproxy_start.sh

# ## Create Desktop Shortcut for starting MapProxy Server in shell
# cat << EOF > /usr/share/applications/mapproxy-start.desktop
# [Desktop Entry]
# Type=Application
# Encoding=UTF-8
# Name=MapProxy Start
# Comment=MapProxy
# Categories=Application;Geography;Geoscience;Education;
# Exec=lxterminal -e mapproxy_start.sh
# Icon=gnome-globe
# Terminal=false
# StartupNotify=false
# EOF

# cp -a /usr/share/applications/mapproxy-start.desktop "$USER_HOME/Desktop/Geospatial/"
# chown -R $USER_NAME:$USER_NAME "$USER_HOME/Desktop/Geospatial/mapproxy-start.desktop"

cat << EOF > /usr/share/applications/mapproxy-demo.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=MapProxy Demo
Comment=MapProxy
Categories=Application;Geography;Geoscience;Education;
Exec=firefox "http://localhost/mapproxy/mapproxy/demo/"
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

service tomcat8 start
sleep 40
service tomcat8 stop

# # Add GeoNode plugins
# cd /tmp
# wget -c --progress=dot:mega \
#    "http://build.geonode.org/geoserver/latest/geonode-geoserver-ext-2.7.4-geoserver-plugin.zip"
# unzip geonode-geoserver-ext-2.7.4-geoserver-plugin.zip
# rm /tmp/geonode-geoserver-ext-2.7.4-geoserver-plugin.zip
# mv /tmp/geonode-geoserver-ext-2.7.4.jar "/var/lib/${TOMCAT_USER_NAME}/webapps/geoserver/WEB-INF/lib/"
# mv /tmp/gt-process-13.4.jar "/var/lib/${TOMCAT_USER_NAME}/webapps/geoserver/WEB-INF/lib/"
# cd "$BUILD_DIR"

#TODO: Add sample data

# Create startup script for GeoServer
if [ ! -e /usr/local/bin/geoserver_start.sh ] ; then
    cat << EOF > /usr/local/bin/geoserver_start.sh
    #!/bin/bash
    STAT=\`sudo service "$TOMCAT_USER_NAME" status | grep "(running)"\`
    if [ -z "\$STAT" ] ; then
        sudo service "$TOMCAT_USER_NAME" start
        (sleep 2; echo "25"; sleep 2; echo "50"; sleep 2; echo "75"; sleep 2; echo "100") \
     | zenity --progress --auto-close --text "GeoServer starting"
    fi
    firefox "http://localhost/geoserver/"
EOF
fi

# Create shutdown script for GeoServer
if [ ! -e /usr/local/bin/geoserver_stop.sh ] ; then
    cat << EOF > /usr/local/bin/geoserver_stop.sh
    #!/bin/bash
    STAT=\`sudo service "$TOMCAT_USER_NAME" status | grep "(running)"\`
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
Exec=firefox "http://localhost/geoserver/"
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

#sudo -u "$USER_NAME" git clone https://github.com/GeoNode/GeoNode.git geonode
sudo -u "$USER_NAME" git clone -b djmp https://github.com/terranodo/geonode.git geonode

echo "Creating Virtualenv..."
sudo -u "$USER_NAME" mkdir -p "$USER_HOME"/.virtualenvs
sudo -u "$USER_NAME" virtualenv --system-site-packages "$USER_HOME"/.virtualenvs/geonode_live

echo "Installing Django..."
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/pip install Django==1.8.7

echo "Creating GeoNode template project..."
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/django-admin.py startproject geonode_live --template=https://github.com/GeoNode/geonode-project/archive/master.zip -epy,rst,yml -n Vagrantfile
cp "$BUILD_DIR"/../conf/geonode/local_settings.py "$USER_HOME"/geonode_live/geonode_live/
cp "$BUILD_DIR"/../conf/geonode/urls.py "$USER_HOME"/geonode_live/geonode_live/
echo 'INSTALLED_APPS += ("osgeo_importer",)' >> "$USER_HOME"/geonode_live/geonode_live/settings.py
echo "DJMP_AUTHORIZATION_CLASS = 'djmp.guardian_auth.GuardianAuthorization'" >> "$USER_HOME"/geonode_live/geonode_live/settings.py
echo "TILESET_CACHE_DIRECTORY = os.path.join(LOCAL_ROOT, 'cache/layers')" >> "$USER_HOME"/geonode_live/geonode_live/settings.py
echo "USE_DISK_CACHE=True" >> "$USER_HOME"/geonode_live/geonode_live/settings.py
echo "LAYER_PREVIEW_LIBRARY = 'geoext'" >> "$USER_HOME"/geonode_live/geonode_live/settings.py

echo "Installing GeoNode..."
cd "$USER_HOME"/geonode
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/pip install -e .
cd ..
sudo -u "$USER_NAME" sed -i -e '25,28d' "$USER_HOME"/geonode_live/setup.py
cd "$USER_HOME"/geonode_live
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/pip install -e .
cd ..
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/pip install git+https://github.com/terranodo/django-mapproxy.git
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/pip install git+https://github.com/ProminentEdge/django-osgeo-importer.git@master#egg=osgeo-importer

echo "Creating www folders..."
#TODO: Clean up not needed folders
mkdir -p /var/www/geonode_live/static
mkdir -p /var/www/geonode_live/uploaded/layers
mkdir -p /var/www/geonode_live/uploaded/thumbs
chown -R www-data:www-data /var/www/geonode_live
chmod -R 777 /var/www/geonode_live
mkdir -p "$USER_HOME"/geonode_live/cache
chmod -R 777 "$USER_HOME"/geonode_live/cache
mkdir -p "$USER_HOME"/geonode_live/geonode_live/cache/layers
chown -R www-data:www-data "$USER_HOME"/geonode_live/geonode_live/cache

echo "Creating GeoNode databases..."
sudo -u $USER_NAME createdb -E UTF8 geonode_live_app
sudo -u $USER_NAME psql geonode_live_app -c 'create extension postgis;'
sudo -u $USER_NAME createdb -E UTF8 geonode_live
sudo -u $USER_NAME psql geonode_live -c 'create extension postgis;'
sudo -u $USER_NAME psql geonode_live -c 'GRANT ALL ON geometry_columns TO PUBLIC;'
sudo -u $USER_NAME psql geonode_live -c 'GRANT ALL ON spatial_ref_sys TO PUBLIC;'

sudo -u "$USER_NAME" mkdir -p "$USER_HOME"/.virtualenvs/geonode_live/local/lib/python2.7/site-packages/geonode/static
cd "$USER_HOME"/geonode_live

echo "Making migrations..."
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py makemigrations --noinput

echo "Applying migrations..."
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate people
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate sites
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate auth
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate account
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate layers
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate documents
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate actstream
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate admin
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate guardian
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate sessions
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate tastypie
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate maps
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate contenttypes
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate base
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate upload
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate groups
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate services
# sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate taggit

echo "Migrate..."
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py migrate --noinput
echo "Sync database..."
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py syncdb --noinput

echo "Collecting static files..."
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py collectstatic --noinput

echo "Installing fixures..."
sudo -u "$USER_NAME" cp "$BUILD_DIR"/../conf/geonode/fixtures.json "$USER_HOME"/geonode_live/
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py loaddata fixtures.json

echo "Creating anonymous user..."
cat << EOF > create-anonymous.py
from geonode.people.models import Profile
Profile.objects.create(username="AnonymousUser")
EOF

sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python manage.py shell < create-anonymous.py
rm create-anonymous.py

echo "Starting GeoServer..."
service tomcat8 start
sleep 30

echo "Creating DB store..."
sudo -u "$USER_NAME" cp "$BUILD_DIR"/../conf/geonode/create_db_store.py "$USER_HOME"/geonode_live/
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/python create_db_store.py

echo "Stoping GeoServer..."
service tomcat8 stop
sleep 5

echo "Configuring uWSGI..."
cp "$BUILD_DIR"/../conf/uwsgi/vassals-default.skel /etc/uwsgi-emperor/vassals/geonode_live.ini
#service uwsgi-emperor restart

# Install desktop icon
echo "Installing GeoNode icon"
cp "$BUILD_DIR"/../conf/geonode/geonode.png /usr/share/icons/

# ## start launcher
# cat << EOF > /usr/share/applications/geonode-start.desktop
# [Desktop Entry]
# Type=Application
# Encoding=UTF-8
# Name=GeoNode Start
# Comment=GeoNode
# Categories=Application;Geography;Geoscience;Education;
# Exec=cd /home/user && uwsgi --plugin http,python --http :8000 --module geonode_live.wsgi --virtualenv /home/user/.virtualenvs/geonode_live
# Icon=/usr/share/icons/geonode.png
# Terminal=true
# EOF

# cp -a /usr/share/applications/geonode-start.desktop "$USER_HOME/Desktop/Geospatial/"
# chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/Desktop/Geospatial/geonode-start.desktop"

# home launcher
cat << EOF > /usr/share/applications/geonode-admin.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=GeoNode Home
Comment=GeoNode Home
Categories=Application;Geography;Geoscience;Education;
Exec=firefox http://localhost/
Icon=/usr/share/icons/geonode.png
Terminal=false
StartupNotify=false
EOF

cp /usr/share/applications/geonode-admin.desktop "$USER_HOME/Desktop/Geospatial/"
chown -R $USER_NAME.$USER_NAME "$USER_HOME/Desktop/Geospatial/geonode-admin.desktop"



#############################################################################
do_hr
echo "Installing Eventkit/Tegola"
do_hr
#############################################################################
cd "$USER_HOME"

# Bring in proper Debian packages required from requirements.txt
apt-get install --yes python-gunicorn gunicorn python-eventlet python-rtree python-imposm \
    python-decorator python-click python-webtest python-numpy python-backports.ssl-match-hostname

wget https://github.com/terranodo/eventkit/raw/master/requirements.txt
sudo -u "$USER_NAME" sed -i -e '15d' requirements.txt
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/pip install -r requirements.txt
rm requirements.txt
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/pip install django-tastypie==0.12.2
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/pip install --upgrade gunicorn
sudo -u "$USER_NAME" "$USER_HOME"/.virtualenvs/geonode_live/bin/pip install --upgrade eventlet

apt-get install --yes supervisor curl

sudo -u "$USER_NAME" mkdir -p "$USER_HOME"/config
sudo -u "$USER_NAME" mkdir -p "$USER_HOME"/config/mapproxy/apps
cd "$USER_HOME"/config/mapproxy
sudo -u "$USER_NAME" wget http://download.omniscale.de/magnacarto/rel/dev-20160406-012a66a/magnacarto-dev-20160406-012a66a-linux-amd64.tar.gz
sudo -u "$USER_NAME" tar -xzvf magnacarto-dev-20160406-012a66a-linux-amd64.tar.gz
sudo -u "$USER_NAME" mv magnacarto-dev-20160406-012a66a-linux-amd64 magnacarto
sudo -u "$USER_NAME" rm magnacarto-dev-20160406-012a66a-linux-amd64.tar.gz

apt-get install --yes golang
cd /usr/local/bin
wget -c --progress=dot:mega \
   -O tegola-v0.1.0-linux-amd64.zip \
   "https://github.com/terranodo/tegola/releases/download/v0.1.0/tegola-v0.1.0-linux-amd64.zip"
unzip tegola-v0.1.0-linux-amd64.zip
rm tegola-v0.1.0-linux-amd64.zip
rm config.toml
cd "$USER_HOME"
cp "$BUILD_DIR"/../conf/tegola/config.toml /usr/local/bin/
mkdir -p /var/www/html/demo/tegola/js
cp "$BUILD_DIR"/../conf/tegola/open-layers-example.html /var/www/html/demo/tegola/index.html
cp "$BUILD_DIR"/../conf/tegola/style.js /var/www/html/demo/tegola/js/style.js

cat << EOF > "/usr/share/applications/tegola.desktop"
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Tegola Demo
Comment=Tegola
Categories=Application;Geography;Geoscience;Education;
Exec=firefox "http://localhost/demo/tegola/"
Icon=gnome-globe
Terminal=false
StartupNotify=false
EOF

cp /usr/share/applications/tegola.desktop "$USER_HOME/Desktop/Geospatial/"
chown "$USER_NAME.$USER_NAME" "$USER_HOME/Desktop/Geospatial/tegola.desktop"

#apt-get remove --yes libmapnik-dev
apt-get autoremove --yes

echo "from mapproxy.multiapp import make_wsgi_app
application = make_wsgi_app('/home/user/config/mapproxy/apps', allow_listing=True)" > "$USER_HOME"/.virtualenvs/geonode_live/src/mapproxy/mapproxy/wsgi.py

cp "$BUILD_DIR"/../conf/mapproxy/mapproxy.yaml /home/user/config/mapproxy/apps/mapproxy.yaml

cp "$BUILD_DIR"/../conf/supervisor/eventkit.conf /etc/supervisor/conf.d/
systemctl enable supervisor.service



#############################################################################
do_hr
echo "Installing Data"
do_hr
#############################################################################
cd "$BUILD_DIR"

DATA_FOLDER="/usr/local/share/data"
NE2_DATA_FOLDER="$DATA_FOLDER/natural_earth2"
mkdir -p "$NE2_DATA_FOLDER"
cd /tmp
wget -c --progress=dot:mega http://download.osgeo.org/livedvd/data/natural_earth2/all_10m_20.tgz
tar xzf all_10m_20.tgz
for tDir in ne_10m_*; do
   mv "$tDir"/* "$NE2_DATA_FOLDER"/
done
rm all_10m_20.tgz

wget -c --progress=dot:mega \
   "http://download.osgeo.org/livedvd/data/natural_earth2/HYP_50M_SR_W_reduced.zip"
unzip HYP_50M_SR_W_reduced.zip
rm HYP_50M_SR_W_reduced.zip
mv HYP_* "$NE2_DATA_FOLDER"/

# Adding more BONN OSM data...
# cd "$USER_HOME"/.virtualenvs/geonode_live/src/osm-extract/
# sudo -u "$USER_NAME" make clean all NAME=bonn URL=https://s3.amazonaws.com/metro-extracts.mapzen.com/bonn_germany.osm.pbf

# Adding pre-generated BONN OSM data to save build time
sudo -u $USER_NAME createdb -E UTF8 bonn_osm
sudo -u $USER_NAME psql bonn_osm -c 'create extension postgis;'
sudo -u $USER_NAME psql bonn_osm -c 'create extension hstore;'
cd /tmp
wget -c --progress=dot:mega \
   "http://aiolos.survey.ntua.gr/gisvm/dev/bonn_osm.sql.tar.gz"
tar zxf bonn_osm.sql.tar.gz
rm bonn_osm.sql.tar.gz
sudo -u $USER_NAME psql bonn_osm < bonn_osm.dump

# Tegola needs 3857 layers...
POLYGON_LAYERS="buildings farms aerodromes_polygon forest grassland lakes medical_polygon military residential schools_polygon"
LINE_LAYERS="all_roads rivers main_roads"

for LAYER in $POLYGON_LAYERS ; do
   sudo -u $USER_NAME psql bonn_osm -c "CREATE TABLE ${LAYER}_3857 AS SELECT * FROM ${LAYER};"
   sudo -u $USER_NAME psql bonn_osm -c "ALTER TABLE ${LAYER}_3857 ALTER COLUMN wkb_geometry TYPE Geometry(MultiPolygon, 3857) USING ST_Transform(wkb_geometry, 3857);"
done

for LAYER in $LINE_LAYERS ; do
   sudo -u $USER_NAME psql bonn_osm -c "CREATE TABLE ${LAYER}_3857 AS SELECT * FROM ${LAYER};"
   sudo -u $USER_NAME psql bonn_osm -c "ALTER TABLE ${LAYER}_3857 ALTER COLUMN wkb_geometry TYPE Geometry(LineString, 3857) USING ST_Transform(wkb_geometry, 3857);"
done



#############################################################################
do_hr
echo "Configuring Desktop"
do_hr
#############################################################################
cd "$BUILD_DIR"

# tweak the lower taskbar
LXPANEL="/usr/share/lxpanel/profile/Lubuntu/panels/panel"
cp "$LXPANEL" "$LXPANEL.bak"
cp "$BUILD_DIR"/../conf/desktop/panel "$LXPANEL"
mkdir -p /etc/skel/.config/lxpanel/Lubuntu/panels
cp "$LXPANEL" /etc/skel/.config/lxpanel/Lubuntu/panels/

#### since KDE is removed we copy in some icons for the menus by hand
cd /
if [ ! -e /usr/share/icons/hicolor/48x48/apps/knetattach.png ] ; then
   tar xf "$BUILD_DIR"/../conf/desktop/knetattach_icons.tar --no-same-owner
fi
if [ ! -e /usr/share/icons/hicolor/48x48/apps/ktip.png ] ; then
   tar xf "$BUILD_DIR"/../conf/desktop/ktip_icons.tar --no-same-owner
fi

mkdir -p /usr/local/share/icons
cp "$BUILD_DIR"/../conf/desktop/gnome-globe16blue.svg /usr/local/share/icons/
cd "$BUILD_DIR"

# Default password list on the desktop to be replaced by html help in the future.
cp ../conf/desktop/passwords.txt "$USER_HOME/Desktop/"
chown "$USER_NAME"."$USER_NAME" "$USER_HOME/Desktop/passwords.txt"

# Setup the default desktop background image
cp ../conf/desktop/geonode-desktop.png \
    /usr/share/lubuntu/wallpapers/

### set the desktop background, turn on keyboard layout select control
sed -i -e 's|^bg=.*|bg=/usr/share/lubuntu/wallpapers/geonode-desktop.png|' \
       -e 's|^keyboard=0$|keyboard=1|' \
    /etc/xdg/lubuntu/lxdm/lxdm.conf

sed -i -e 's|^wallpaper_mode=.*|wallpaper_mode=fit|' \
       -e 's|^wallpaper=.*|wallpaper=/usr/share/lubuntu/wallpapers/geonode-desktop.png|' \
       -e 's|^desktop_fg=.*|desktop_fg=#232323|' \
       -e 's|^desktop_shadow=.*|desktop_shadow=#ffffff|' \
       -e 's|^desktop_bg=.*|desktop_bg=#ffffff|' \
       -e 's|^show_trash=.*|show_trash=0|' \
   /etc/xdg/pcmanfm/lubuntu/pcmanfm.conf

echo "desktop_folder_new_win=1" >> /etc/xdg/pcmanfm/lubuntu/pcmanfm.conf

sed -i -e 's|^background=.*|background=/usr/share/lubuntu/wallpapers/geonode-desktop.png|' \
   /etc/lightdm/lightdm-gtk-greeter.conf

apt-get install --yes gxmessage

mkdir -p /usr/local/share/geonode-desktop

cat << EOF > "/usr/local/share/geonode-desktop/welcome_message.desktop"
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Welcome message
Comment=Live Demo welcome message
Exec=/usr/local/share/geonode-desktop/welcome_message.sh
Terminal=false
StartupNotify=false
Hidden=false
EOF

mkdir -p "$USER_HOME"/.config/autostart
cp /usr/local/share/geonode-desktop/welcome_message.desktop \
   "$USER_HOME"/.config/autostart/
mkdir -p /etc/skel/.config/autostart
cp /usr/local/share/geonode-desktop/welcome_message.desktop \
   /etc/skel/.config/autostart/

cp "$BUILD_DIR/../conf/desktop/welcome_message.sh" \
   /usr/local/share/geonode-desktop/

cp "$BUILD_DIR/../conf/desktop/welcome_message.txt" \
   /usr/local/share/geonode-desktop/

cp /usr/local/share/geonode-desktop/welcome_message.txt "$USER_HOME"/
chown "$USER_NAME"."$USER_NAME" "$USER_HOME"/welcome_message.txt
cp /usr/local/share/geonode-desktop/welcome_message.txt /etc/skel/

# xdg nm-applet not loading by default, re-add it to user autostart
cp /etc/xdg/autostart/nm-applet.desktop  /etc/skel/.config/autostart/

# Tweak (non-default) theme so that window borders are wider so easier to grab.
sed -i -e 's|^border.width: 1|border.width: 2|' \
   /usr/share/themes/Mikachu/openbox-3/themerc

# Long live the classic X11 keybindings
cat << EOF > /etc/skel/.xinitrc
setxkbmap -option keypad:pointerkeys
setxkbmap -option terminate:ctrl_alt_bksp
EOF

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
#service tomcat8 start
#sleep 60
#service tomcat8 stop

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

# Remove symlink
rm -rf "$USER_HOME"/geonode-live
rm -rf /etc/skel/geonode-live

# stop PostgreSQL and Apache to avoid them thinking a crash happened next boot
service postgresql stop
service apache2 stop
service nginx stop
service uwsgi-emperor stop
