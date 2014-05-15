var ignore_data = function(data) {};
(function() {
  var dbase_url = "//api.demandbase.com/api/v2/ip.json";
  dbase_url += "?token=191807";
  dbase_url += "&page=" + encodeURIComponent(document.location.href);
  dbase_url += "&referrer=" + encodeURIComponent(document.referrer);
  dbase_url += "&page_title=" + encodeURIComponent(document.title);
  dbase_url += "&callback=ignore_data";
  var protocol = "https:" == document.location.protocol ? 'https:' : 'http:';
  if(navigator.userAgent.indexOf("Slurp") == -1) {
    document.write(unescape("%3Cscript type='text/javascript' src='") + protocol + dbase_url + unescape("'%3E%3C/script%3E"));
  }
}());
