import os

PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))

SITEURL = "geonode_live"

DATABASES = {
    'default': {
         'ENGINE': 'django.db.backends.postgresql_psycopg2',
         'NAME': 'geonode_live_app',
         'USER': 'user',
         'PASSWORD': 'user',
     },
    # vector datastore for uploads
    'geonode_live' : {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': 'geonode_live',
        'USER' : 'user',
        'PASSWORD' : 'user',
        'HOST' : 'localhost',
        'PORT' : 5432
    }
}

# OGC (WMS/WFS/WCS) Server Settings
OGC_SERVER = {
    'default' : {
        'BACKEND' : 'geonode.geoserver',
        'LOCATION' : 'http://localhost:8081/geoserver/',
        'PUBLIC_LOCATION' : 'http://localhost/geoserver/',
        'USER' : 'admin',
        'PASSWORD' : 'geoserver',
        'MAPFISH_PRINT_ENABLED' : True,
        'PRINT_NG_ENABLED' : True,
        'GEONODE_SECURITY_ENABLED' : True,
        'GEOGIG_ENABLED' : False,
        'WMST_ENABLED' : False,
        'BACKEND_WRITE_ENABLED': True,
        'WPS_ENABLED' : False,
        'LOG_FILE': '%s/geoserver/data/logs/geoserver.log' % os.path.abspath(os.path.join(PROJECT_ROOT, os.pardir)),
        # Set to name of database in DATABASES dictionary to enable
        'DATASTORE': 'geonode_live', #'datastore',
    }
}

CATALOGUE = {
    'default': {
        'ENGINE': 'geonode.catalogue.backends.pycsw_local',
        'URL': '%scatalogue/csw' % SITEURL,
    }
}

MEDIA_ROOT = "/var/www/geonode_live/uploaded"
STATIC_ROOT = "/var/www/geonode_live/static"
