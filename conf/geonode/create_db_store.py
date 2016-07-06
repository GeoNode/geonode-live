from geoserver.catalog import Catalog

cat = Catalog('http://localhost:8080/geoserver/rest')
ds = cat.create_datastore('my_geonode','geonode')
ds.connection_parameters.update(host='localhost', port='5432', database='my_geonode', user='user', passwd='user', dbtype='postgis', schema='public')
cat.save(ds)
