var wms_layer = new OpenLayers.Layer.WMS( "MapServer WMS",
                    "http://localhost/mapserver",
                    {layers: 'city_poly', 'county_borders', 'parcels'} );

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
//    center: [0, 0],
//    zoom: 3
});

//map.addControl(new OpenLayers.Control.LayerSwitcher());
map.zoomToMaxExtent();
