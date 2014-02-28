//***************************************************************************************************
//     Script for tracking file downloads
//     Author: Brian J Clifton @ Omega Digital Media Ltd
//     Adjusted by Allaedin Ezzedin @ E-Nor to make the code work with Asynchronous & Event Tracking
//***************************************************************************************************

var CurrentPage = getDomain (window.location.href);
var as = document.getElementsByTagName("a");
var extTrack = ["vmware.com"];
var extDoc = [".exe",".zip",".wav",".mp3",".mov",".mpg",".avi",".wmv",".pdf",".doc",".docx",".xls",".xlsx",".ppt",".pptx",".iso",".rar",".gz",".tar",".gzip",".jar",".ovf",".dmg",".msi",".bundle"];
	  
function getDomain (thestring)
{
var urlpattern = new RegExp("(.*)/(.*)?(.*)");
var parsedurl = thestring.match(urlpattern);
return parsedurl[2];
}

for (var i = 0; i < as.length; i++) {
	var flag = 0;
	var tmp = as[i].getAttribute("onclick");
	
	if (tmp != null) {
		tmp = String(tmp);
		if (tmp.indexOf('_gaq.push') > -1) 
			continue;
	}
		
// Tracking electronic documents - doc, xls, pdf, exe, zip
	 for (var j = 0; j < extDoc.length; j++) {
		if (as[i].href.indexOf(extTrack[0]) != -1 && as[i].href.indexOf(extDoc[j]) != -1) {
			as[i].onclick = function(){
				var splitResult = this.href.split(extTrack[0]);
			    _gaq.push(['_trackPageview', '/vp/downloads' + splitResult[1]]) + ';' +  _gaq.push(['_trackEvent', 'Downloads', splitResult[1], '/'+CurrentPage]) + ';' + ((tmp != null) ? tmp + ';' : '');				
			}
			break;
		}
	}		
}