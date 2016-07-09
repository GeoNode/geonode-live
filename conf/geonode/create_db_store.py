from geoserver.catalog import Catalog

cat = Catalog('http://localhost:8081/geoserver/rest')
ds = cat.create_datastore('geonode_live','geonode')
ds.connection_parameters.update(host='localhost', port='5432', database='geonode_live', user='user', passwd='user', dbtype='postgis', schema='public')
cat.save(ds)
