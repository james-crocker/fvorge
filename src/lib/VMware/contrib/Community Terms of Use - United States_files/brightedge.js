// load the JS file only after the page is loaded (non-blocking)
vmf.dom.onload(function(){
    vmf.ajax.connect({
        url: ((window.location.protocol == 'https:') ? 'https://' : 'http://edge.')+'analytics.brightedge.com/brightedge_analytics.js',
        dataType: 'script',
        timeout: 5000, // Give a 5 seconds timeout for the ajax call
        success: function() {
			// evaluate the script resonse if brightedge is not load
			if (!_bright) { eval(response); }
            // Execute the tracking function only if the library file is loaded
            var track = _bright._initialize('f5d802b1be8ac32');
            track._trackBright();
        }
    });
});