import 'dart:html';
import 'dart:convert' show JSON;
import 'dart:js' show context, JsObject;
import 'cellform/CellForm.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'Constants.dart';

JsObject mMap;
JsObject mMainLayer;
JsObject mHeatmapLayer;
JsObject mLegendControl;
CellForm mCellFormController;

HttpRequest _heatmapLoader;

void main() {
  
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  
  final JsObject leaflet = context['L'];
  mMap = new JsObject(leaflet['map'], ['map-canvas']);
  mMainLayer = _createMainLayer();
  mHeatmapLayer = _createHeatmapLayer();
  mLegendControl = _createLegendControl();
  mCellFormController = new CellForm();
   
  
  mMap.callMethod('setView',
      [new JsObject.jsify(MAP_DEFAULT_CENTER),  MAP_DEFAULT_ZOOM]); 
  mMainLayer.callMethod('addTo', [mMap]);
  mMap.callMethod("addLayer", [mHeatmapLayer]);
  mLegendControl.callMethod("addTo", [mMap]);
  mCellFormController.leafletControl.callMethod("addTo", [mMap]);
  mCellFormController.valueNotificator.listen((data) {
    _setData("[]");
    _loadHeatmapData();
  });
  
  _loadHeatmapData();
}

JsObject _createMainLayer() {
  final JsObject leaflet = context['L'];
  return new JsObject(
      leaflet['tileLayer'], 
      ['http://api.tiles.mapbox.com/v3/$MAPBOX_API_KEY/{z}/{x}/{y}.png',
       new JsObject.jsify({'attribution':
         '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
         })
      ]);
}

JsObject _createHeatmapLayer() {
  final JsObject leaflet = context['L'];           
  final heatmapConfig = {
       'radius': 10,
       'useAbsoluteRadius': true,
       'opacity': 0.5,
       'noMask': true
  };
  
  var heatMapF = leaflet['TileLayer']['maskCanvas']; 
  
  return new JsObject(
      heatMapF,
      [new JsObject.jsify(heatmapConfig)]);
}

JsObject _createLegendControl() {
  
  JsObject legendControl = new JsObject(context['L']['Control'],
      [new JsObject.jsify({'position': 'bottomright'})]);
  
  legendControl['onAdd'] = (map) {
    final colors = ['#00FF00', '#FFFF00', '#FF0000'];
    final labels = ['-60&ndash;-40', '-85&ndash;-60', '-120&ndash;-60'];
        
    var container = new DivElement();
    container.classes.addAll(['info', 'legend']);
    
    for (int i=0; i<colors.length; ++i) {
      container.appendHtml("""
        <i style="background: ${colors[i]}"></i>${labels[i]}<br>
      """);
    }
    return container;
  };
  
  return legendControl; 
}

JsObject _createCellsFormControl() {
  JsObject cellsFormControl = new JsObject(context['L']['Control'],
      [new JsObject.jsify({'position': 'topleft'})]);
  
  cellsFormControl['onAdd'] = (map) {
    Element container = new Element.tag("cellsform");
    container.classes.addAll(['info', 'cells_form']);
    
    JsObject domEvent = context['L']['DomEvent'];
    var stop = context['L']['DomEvent']['stopPropagation'];
    domEvent.callMethod("on", [container, 'click', stop]);
    domEvent.callMethod("on", [container, 'mousedown', stop]);
    
    return container;
  };
  return cellsFormControl;
}

void _setData(String jsonData) {
  var data = JSON.decode(jsonData);
  mHeatmapLayer.callMethod("setData",
      [new JsObject.jsify(data)]);
}

void _loadHeatmapData() {
  //String uri = HEATMAP_CELLS_URI.toString() + "?mnc=7&mcc=250&cid=5331";
  String uri = mCellFormController.value.asCoverageUrl();
  
  if (_heatmapLoader != null) {
    _heatmapLoader.abort();
  }
  
  _heatmapLoader = new HttpRequest()
    ..open('GET', uri)
    ..onLoad.listen((event) {
      _setData(event.target.responseText);
    })
    ..send();
}



