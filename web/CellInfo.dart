import 'package:json_object/json_object.dart';
import 'dart:convert' show JSON;
 
class CellInfo extends JsonObject {
  
  static Map<int, String> MCC_NAMES = {
          250: "Russia"
  };
        
  static Map<int, String> MNC_NAMES = {
          1: "MTS",
          2: "Megafon",
          7: "Smarts",
          39: "Rostelecom",
          99: "Beeline"
  };
  
  int mcc;
  int mnc;
  int lac;
  int cid;
  String netwok_radio;
  num asu_min;
  num asu_max;
  
  CellInfo();
  
  CellInfo.fromMap(Map json) :
    mcc = json['mcc'] == null ? -1 : json['mcc'], 
    mnc = json['mnc'] == null ? -1 : json['mnc'],
    lac = json['lac'] == null ? -1 : json['lac'],
    cid = json['cid'] == null ? -1 : json['cid'],
    netwok_radio = json['network_radio']
    {
    if (json.containsKey('asu_min')) asu_min = json['asu_min'];
    if (json.containsKey('asu_max')) asu_max = json['asu_max'];
  }
  
  factory CellInfo.fromJsonString(string) {
    return new JsonObject.fromJsonString(string, new CellInfo());
  }
  
  String mcc_name() => MCC_NAMES.containsKey(mcc) ? "$mcc ${MCC_NAMES[mcc]}" : mcc.toString(); 

  String mnc_name() => MNC_NAMES.containsKey(mnc) ? "$mnc ${MNC_NAMES[mnc]}" : mnc.toString();
  
  static List<CellInfo> listFromJsonString(String string) {
    var items = JSON.decode(string);
    List<CellInfo> res = new List<CellInfo>();
    for (Map item in items) {
      res.add(new CellInfo.fromMap(item));
    }
    return res;
  }
}
