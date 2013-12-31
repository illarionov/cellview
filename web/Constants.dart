library constants;

import 'cellform/CellFormData.dart';

final String MAPBOX_API_KEY = "lsillarionov.ghk4pdd0";
final API_URL = "http://moz.0xdc.ru";
final API_COVERAGE_URL = API_URL + "/v1/coverage";
final API_CELLS_URL = API_URL + "/v1/cells";

final dynamic MAP_DEFAULT_CENTER = [56.1130, 47.2714];
final int MAP_DEFAULT_ZOOM = 11;
final CELL_FORM_DEFAULT_VALUE = new CellFormData(
    mnc: 1,
    mcc: 250
    );

