from django.conf.urls import patterns, url
from django.views.generic import TemplateView
from osgeo_importer.urls import urlpatterns as importer_urlpatterns
from tastypie.api import Api

from geonode.urls import *


importer_api = Api(api_name='importer-api')
#importer_api.register(UploadedLayerResource())

urlpatterns = patterns('',
   url(r'^/?$',
       TemplateView.as_view(template_name='site_index.html'),
       name='home'),
 ) + urlpatterns

urlpatterns += patterns("", url(r'', include(importer_api.urls)))

urlpatterns += importer_urlpatterns
