var wms_layer = new OpenLayers.Layer.WMS( "MapServer WMS",
                    "http://localhost/mapserver",
                    {layers: 'ctybdpy2,twprgpy3,lakespy2,dlgstln2,roads', version: '1.3.0'},
                    {singleTile: false}
);

var map = new OpenLayers.Map({
    div: "map",
    layers: [wms_layer],
    controls: [
        new OpenLayers.Control.Navigation({
            dragPanOptions: {
                enableKinetic: true
            }
        }),
        new OpenLayers.Control.PanZoom(),
        new OpenLayers.Control.Attribution()
    ],
});

var extent = new OpenLayers.Bounds(-94.50,46.97,-92.98,47.94);
map.zoomToExtent(extent, true);
