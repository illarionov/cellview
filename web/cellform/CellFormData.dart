library cellform;
import '../Constants.dart';

class CellFormData {
  static const int VALUE_ALL = null;
  
  final int mnc;
  
  final int mcc;
 
  final int lac;
  
  final int cid;
  
  final String radio;
  
  CellFormData({this.mnc: VALUE_ALL, 
    this.mcc: VALUE_ALL, this.lac: VALUE_ALL,
    this.cid: VALUE_ALL,
    this.radio: null
    }) {
  }
  
  String asCoverageUrl() {
    Map<String, String> queryParams = new Map<String, String>();
    if (mnc != VALUE_ALL) queryParams["mnc"] = mnc == -1 ? "null" : mnc.toString();
    if (mcc != VALUE_ALL) queryParams["mcc"] = mcc == -1 ? "null" : mcc.toString();
    if (cid != VALUE_ALL) queryParams["cid"] = cid == -1 ? "null" : cid.toString();
    if (lac != VALUE_ALL) queryParams["lac"] = lac == -1 ? "null" : lac.toString();
    if (radio != null) queryParams["network_radio"] = radio;
    if (queryParams.isEmpty) {
      return API_COVERAGE_URL;
    }else {
      List<String> params = new List<String>();
      queryParams.forEach((key, val) => params.add("${Uri.encodeComponent(key)}=${Uri.encodeComponent(val)}"));
      params.sort((a, b) => a.compareTo(b));
      return API_COVERAGE_URL + "/?" + params.join("&");
    }
  }
}
