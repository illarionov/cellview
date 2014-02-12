library cellform;

import 'dart:async';
import 'dart:html';
import 'dart:js' show context, JsObject;
import '../CellInfo.dart';
import '../Constants.dart';
import 'package:logging/logging.dart';
import 'CellFormData.dart';

class CellForm {
  
  static final LEAFLET_CONTROL_PARAMS = {'position': 'topleft'};
  
  static OptionElement get OPTION_ELEMENT_ALL => new OptionElement(value: "", data: "All");
  
  static const TEMPLATE = '''
<form>
      <fieldset>
        <ul>
          <li>
            <label for="select_mcc">MCC:</label>
            <select id="select_mcc"></select>
          </li>
        <li>
            <label for="select_mnc">MNC:</label>
            <select id="select_mnc"></select>
          </li>
        <li>
            <label for="select_radio">Radio:</label>
            <select id="select_radio"></select>
        </li>
        <li>
            <label for="select_lac">LAC:</label>
            <select id="select_lac"></select>
          </li>
          <li>
            <label for="select_cid">CID:</label>
            <select id="select_cid"></select>
          </li>
        </ul>
      </fieldset>
</form>
''';
  
  final Logger log = new Logger('CellForm');
  
  /**
   * Leaflet controller
   */
  final JsObject leafletControl;
  
  /**
   * Loaded list of cells
   */
  List<CellInfo> cells = new List<CellInfo>(0);
  
  StreamController<CellFormData> _notificator = new StreamController<CellFormData>();

  SelectElement selectMncField;
  SelectElement selectMccField;
  SelectElement selectLacField;
  SelectElement selectCidField;
  SelectElement selectRadioField;
  
  CellForm()
      : leafletControl = new JsObject(context['L']['Control'],
          [new JsObject.jsify(LEAFLET_CONTROL_PARAMS)]) {
    leafletControl['onAdd'] = (map) {
      FormElement container = new DocumentFragment.html(TEMPLATE).firstChild;
      container.classes.addAll(['info', 'cells_form']);
      selectMncField = container.querySelector('#select_mnc');
      selectMccField = container.querySelector('#select_mcc');
      selectLacField = container.querySelector('#select_lac');
      selectCidField = container.querySelector('#select_cid');
      selectRadioField = container.querySelector('#select_radio');
      
      selectMncField.onChange.listen(_onMncSelectionChanged);
      selectMccField.onChange.listen(_onMccSelectionChanged);
      selectLacField.onChange.listen(_onLacSelectionChanged);
      selectCidField.onChange.listen(_onCidSelectionChanged);
      selectRadioField.onChange.listen(_onRadioSelectionChanged);

      _loadCellsInfo().then((String fileContents){
        refreshFormData();
      });
      return container;
    };
    
  }
  
  int _getIntOrNullValue(SelectElement el) {
    if (el.value == null || el.value == "") {
      return null;
    }else {
      return int.parse(el.value);
    }
  }
  
  int getSelectedMnc() =>  _getIntOrNullValue(selectMncField);
  int getSelectedMcc() =>  _getIntOrNullValue(selectMccField);
  int getSelectedLac() =>  _getIntOrNullValue(selectLacField);
  int getSelectedCid() =>  _getIntOrNullValue(selectCidField);
  String getSelectedRadio() => selectRadioField.value == null 
      || selectRadioField.value == "" ? null : selectRadioField.value;
   
  CellFormData get value {
    return new CellFormData(mnc: getSelectedMnc(),
        mcc: getSelectedMcc(),
        lac: getSelectedLac(),
        cid: getSelectedCid(),
        radio: getSelectedRadio()
        );
  }
  
  Stream<CellFormData> get valueNotificator => _notificator.stream;
  
  void refreshFormData() {
    _refreshMccList();
    _refreshMncList();
    _refreshCidList();
    _refreshLacList();
    _refreshRadioList();
  }
  
  Future _loadCellsInfo() {
    _setStatusLoadingCellList(true);
    return HttpRequest.getString(API_CELLS_URL)
      .then((String fileContents) {
        cells = CellInfo.listFromJsonString(fileContents);
      }).whenComplete(() {
        _setStatusLoadingCellList(false);
      });
  }
  
  void _setStatusLoadingCellList(bool loading) {
    selectMncField.disabled = loading;
    selectMccField.disabled = loading;
    selectLacField.disabled = loading;
    selectLacField.disabled = loading;
    selectCidField.disabled = loading;
    selectRadioField.disabled = loading;
  }
  
  void _refreshMccList() {
    Map mccMap = new Map();
    List<CellInfo> cellsSorted;
    List<OptionElement> mccValues = new List<OptionElement>();
    
    cells.forEach((e) => mccMap[e.mcc] = e);
    cellsSorted = mccMap.values.toList();
    cellsSorted.sort((a, b) => a.mcc.compareTo(b.mcc));
    
    mccValues.add(OPTION_ELEMENT_ALL);
    for (CellInfo item in cellsSorted) {
      mccValues.add(new OptionElement(value: item.mcc.toString(),
          data: item.mcc_name()));
    }
    selectMccField.nodes = mccValues;
  }
  
  void _refreshMncList() {
    Map mncMap = new Map();
    List<CellInfo> cellsSorted;
    Iterable<CellInfo> cellsFiltered;
    List<OptionElement> mncValues = new List<OptionElement>();
    
    cellsFiltered = _grepCurrentMcc(cells);
    
    cellsFiltered.forEach((e) => mncMap[e.mnc] = e);
    cellsSorted = mncMap.values.toList();
    cellsSorted.sort((a,b) => a.mnc.compareTo(b.mnc));
    
    mncValues.add(OPTION_ELEMENT_ALL);
    for (CellInfo item in cellsSorted) {
      mncValues.add(new OptionElement(value: item.mnc.toString(),
          data: item.mnc_name()));
    }
    selectMncField.nodes = mncValues;
  }
  
  void _refreshRadioList() {
    Map radioMap = new Map();
    List<CellInfo> cellsSorted;
    Iterable<CellInfo> cellsFiltered;
    
    cellsFiltered = _grepCurrentMcc(cells);
    cellsFiltered = _grepCurrentMnc(cellsFiltered);
    
    cellsFiltered.forEach((e) => radioMap[e.network_radio] = e);
    cellsSorted = radioMap.values.toList();
    cellsSorted.sort((a,b) => a.network_radio.compareTo(b.network_radio));   
    
    List<OptionElement> radioValues = new List<OptionElement>();
    radioValues.add(OPTION_ELEMENT_ALL);
    for (CellInfo item in cellsSorted) {
      radioValues.add(new OptionElement(value: item.network_radio,
          data: item.network_radio));
    }
    selectRadioField.nodes = radioValues;
  }

  void _refreshLacList() {
    List<CellInfo> cellsSorted;
    Iterable<CellInfo> cellsFiltered;
    
    cellsFiltered = _grepCurrentMcc(cells);
    cellsFiltered = _grepCurrentMnc(cellsFiltered);
    cellsFiltered = _grepCurrentRadio(cellsFiltered);
    
    Map lacMap = new Map();
    cellsFiltered.forEach((e) => lacMap[e.lac] = e);
    cellsSorted = lacMap.values.toList();
    cellsSorted.sort((a,b) => a.lac.compareTo(b.lac));
    
    List<OptionElement> lacValues = new List<OptionElement>();
    lacValues.add(OPTION_ELEMENT_ALL);
    for (CellInfo item in cellsSorted) {
      lacValues.add(new OptionElement(value: item.lac.toString(),
          data: item.lac.toString()));
    }
    selectLacField.nodes = lacValues;
  }
    
  void _refreshCidList() {
    List<CellInfo> cellsSorted;
    
    Iterable<CellInfo> cellsFiltered;
    cellsFiltered = _grepCurrentMcc(cells);
    cellsFiltered = _grepCurrentMnc(cellsFiltered);
    cellsFiltered = _grepCurrentRadio(cellsFiltered);
    cellsFiltered = _grepCurrentLac(cellsFiltered);
    
    Map cidMap = new Map();
    cellsFiltered.forEach((e) => cidMap[e.cid] = e);
    cellsSorted = cidMap.values.toList();
    cellsSorted.sort((a,b) => a.cid.compareTo(b.cid));
    
    List<OptionElement> cidValues = new List<OptionElement>();
    cidValues.add(OPTION_ELEMENT_ALL);
    for (CellInfo item in cellsSorted) {
      cidValues.add(new OptionElement(value: item.cid.toString(),
          data: item.cid.toString()));
    }
    selectCidField.nodes = cidValues;
  }
      
  Iterable<CellInfo> _grepCurrentMcc(Iterable<CellInfo> iterable) {
    int selectedMcc = getSelectedMcc();
    return selectedMcc == null ? 
        iterable : iterable.where((ci) => ci.mcc == selectedMcc);
  }
  
  Iterable<CellInfo> _grepCurrentMnc(Iterable<CellInfo> iterable) {
    int selectedMnc = getSelectedMnc();
    return selectedMnc == null ? 
        iterable : iterable.where((ci) => ci.mnc == selectedMnc);
  }
  
  Iterable<CellInfo> _grepCurrentLac(Iterable<CellInfo> iterable) {
    int selectedLac = getSelectedLac();
    return selectedLac == null ? 
        iterable : iterable.where((ci) => ci.lac == selectedLac);
  }
  
  Iterable<CellInfo> _grepCurrentRadio(Iterable<CellInfo> iterable) {
    String selectedRadio = getSelectedRadio();
    return selectedRadio == null ? 
        iterable : iterable.where((ci) => ci.network_radio == selectedRadio);
  }
  
  void notifyFormSelectionChanged() {
    _notificator.add(value);
  }
  
  void _onMccSelectionChanged(Event e) {
    _refreshMncList();
    _refreshRadioList();
    _refreshLacList();
    _refreshCidList();
    notifyFormSelectionChanged();
  }
  
  void _onMncSelectionChanged(Event e) {
    _refreshRadioList();
    _refreshLacList();
    _refreshCidList();
    notifyFormSelectionChanged();
  }

  void _onRadioSelectionChanged(Event e) {
    _refreshLacList();
    _refreshCidList();
    notifyFormSelectionChanged();
  }
  
  void _onLacSelectionChanged(Event e) {
    _refreshCidList();
    notifyFormSelectionChanged();
  }
  
  void _onCidSelectionChanged(Event e) {
    notifyFormSelectionChanged();
  }
  
}