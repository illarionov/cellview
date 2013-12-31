// mongo localhost:27017/test req.js
conn = new Mongo();
db = conn.getDB("mozstumbler-server-development");
/*
items = db.cells.find(
    {"mnc": 7, "mcc":250, "cid": 1131},
    {"loc":1, "asu":1, "_id":0}
    );
*/

cond = {"mnc": 7, "mcc":250, "cid": 1131};

keyf = function(doc) {
  PRECISION = 1e5
  lng = Math.round(doc.loc[0] * PRECISION) / PRECISION;
  lat = Math.round(doc.loc[1] * PRECISION) / PRECISION;
  return {
     "loc": [ lng, lat  ]
  };
}

reducef = function(curr, result) {
   result.total_asu += curr.asu;
   result.count += 1;
}

finalizef = function(result) {
  result.avg_asu = Math.round(100 * result.total_asu / result.count) / 100;
}

items = db.cells.group({
    "$keyf": keyf,
    "cond": cond,
    "$reduce": reducef,
    "initial": { total_asu: 0, count: 0 },
    "finalize": finalizef
});

size=0
items.forEach(
    function(myDoc) {
      printjson(myDoc);
      size += 1;
    }
)

printjson(size);

