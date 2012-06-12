var fs = require('fs');
var KEY_DELIM = '/';

function readJson(file, debug) {
  try {
    var bytes = fs.readFileSync(file);
    return eval('(' + bytes + ')');
  }
  catch (e) {
    if (debug) console.log("Error reading file: "+e);
    return null;
  }
}

function getValue(o, k, d) {
  if (!o || !k) return null;
  var i = k.indexOf(KEY_DELIM);
  if (i < 0) return o[k] || null;
  return getValue(o[k.substr(0,i)], k.substr(i+1), d);
}

module.exports = {
  getValue: getValue,
  readJson: readJson,
  KEY_DELIM: KEY_DELIM
}


