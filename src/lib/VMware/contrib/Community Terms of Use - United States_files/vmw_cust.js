var jQversion = jQuery.fn.jquery.split('.'),
jQversionM = parseInt(jQversion[0]),
jQversionI = parseInt(jQversion[1]);

jQuery('html').removeClass('video');

if(window.Shadowbox) {
	if((jQversionM === 1 && jQversionI > 3) || (jQversionM > 1)) {		
		try {
			var sbTmpCach,
			sbTmpObj;
			Shadowbox.init({ players:["html","img", "swf", "iframe"],
					onOpen : function(obj) {
						//console.log("Shadowbox opened " + obj.link.hash);
						sbTmpCach = jQuery(obj.link.hash).html();
						sbTmpObj = obj;
						jQuery(obj.link.hash).html('<span></span>');
						jQuery('.BrightcoveExperience').attr('style', 'visibility: visible;');	
					},
					onClose: function(obj) {
						//console.log("Shadowbox closed " + obj.link.hash);
						jQuery(obj.link.hash).html(sbTmpCach);
						sbTmpCach = '';
						sbTmpObj = null;
					},
					onChange: function(obj) {
						//console.log("Shadowbox changed " + obj.link.hash);			
						jQuery(sbTmpObj.link.hash).html(sbTmpCach);	
						sbTmpCach = jQuery(obj.link.hash).html();					
						sbTmpObj = obj;
						jQuery(obj.link.hash).html('<span></span>');
						jQuery('.BrightcoveExperience').attr('style', 'visibility: visible;');								
					} 
				}, function() {
				var sCache = this.cache,
				aStr,
				waitCache;
				fixCache();
			
				function fixCache() {
					if(jQuery.isEmptyObject(sCache)) {
						waitCache = setTimeout(fixCache, 1000);
					} else {
						clearTimeout(waitCache);
						jQuery.each(sCache, function(i, o) {
							var sUrl = jQuery.url(o.content),
								pUrl = jQuery.url(o.content).fsegment(1);
			
							if (typeof pUrl != "undefined" && pUrl.length != 0) {
								this.content = sUrl.attr("protocol") + "://" + sUrl.attr("host") + sUrl.attr("path") + "#" + pUrl;
								if(this.player == "iframe") this.player = "inline";
							}
						});				
					}
				}			
			});	
		} catch(e) {
			//console.log('Shadowbox Error: ' + e.message);
		}			
	} else {
		//console.log('jQuery 1.4+ is required');
		jQuery(document).ready(function() {
			jQuery('a[rel*="shadowbox"]').click(function(){
				var ccid = jQuery(this).attr("href"),
				oinfo,
				s_width = '720',
				s_height = '475',
				a_str = jQuery(this).attr("rel").split(";"),
				c, t;
				
				for (i = 0; i<a_str.length; i++){
    				c = a_str[i].split('=');
    				if (c[0] == 'width') s_width = c[1];
    				if (c[0] == 'height') s_height = c[1];
				}

				if (ccid.substring(0,1) == "#") {	
					oinfo = jQuery(ccid).html().replace('VISIBILITY: hidden',''); //IE
					oinfo = oinfo.replace('visibility: hidden;','');  

					t = jQuery(this).attr('title');
					if(Shadowbox.current != -1) {
						Shadowbox.gallery[Shadowbox.current].player = "html";
						Shadowbox.gallery[Shadowbox.current].content = oinfo;
						Shadowbox.open({player:"html",content:oinfo,width:s_width,height:s_height,title:t},Shadowbox.current);
					} else { 
						Shadowbox.open({player:"html",content:oinfo,width:s_width,height:s_height,title:t});
					}
				}
			});
		});
	}		
}
/* 
if(jQuery('.BrightcoveExperience').length > 0) {
	var pUrl,
	bcUrl,
	bcApi,
	bcProt;
	
	try {
		pUrl = jQuery.url();
		bcProt = pUrl.attr('protocol');
	} catch(e) {
		//console.log('jQuery.url not supported');
		//console.log('jQuery 1.4+ is required');
		bcProt = window.location.protocol;
	}	
		             
	if(bcProt == 'https') {					                        
		bcUrl = 'https://sadmin.brightcove.com/js/BrightcoveExperiences.js';  
		bcApi = 'https://sadmin.brightcove.com/js/APIModules_all.js';                      
	} else {
		bcUrl = 'http://admin.brightcove.com/js/BrightcoveExperiences.js';
		bcApi = 'http://admin.brightcove.com/js/APIModules_all.js';  
		//bcApi = 'http://admin.brightcove.com/js/api/SmartPlayerAPI.js';  
	}
	
	try {
		if((jQversionM === 1 && jQversionI > 3) || (jQversionM > 1)) {
			Modernizr.load({
	        	load: [bcUrl, bcApi],
	        	//load: [bcUrl],
				complete: function() {                  
					if (bcProt == 'https') {
						var bcParam = document.createElement('param');
						bcParam.name = 'secureConnections';
						bcParam.value = 'true';
						jQuery('.BrightcoveExperience').append(bcParam);
					}
					if(window.brightcove) {
						window.brightcove.createExperiences();
					} else {
						//console.log('Brightcove not loaded');
					}
				}                       
			});
		} else {
			jQuery.getScript(bcUrl, function() {
				if (bcProt == 'https') {
					var bcParam = document.createElement('param');
					bcParam.name = 'secureConnections';
					bcParam.value = 'true';
					jQuery('.BrightcoveExperience').append(bcParam);
				}
				if(window.brightcove) {
					window.brightcove.createExperiences();
				} else {
					//console.log('Brightcove not loaded');
				}
				
			});
		}				
	} catch(e) {
		//console.log('Brightcove Error: ' + e.message);
	}   
} */
var player, modVP, currentVideo;
// function onTemplateLoad(experienceID) {
onTemplateLoad= function (experienceID) {

      player = brightcove.getExperience(experienceID);
      
      captionsModule = player.getModule(brightcove.api.modules.APIModules.CAPTIONS);
      
      captionsModule.addEventListener(brightcove.api.events.CaptionsEvent.DFXP_LOAD_SUCCESS, onDFXPLoadSuccess);
      
      captionsModule.addEventListener(brightcove.api.events.CaptionsEvent.DFXP_LOAD_ERROR, onDFXPLoadError); 
      
      captionsModule.setLanguage(gObj[experienceID].language);
      
      captionsModule.loadDFXP(gObj[experienceID].href, gObj[experienceID].id);

      modVP = player.getModule(brightcove.api.modules.APIModules.VIDEO_PLAYER);

      
}

//function onTemplateReady(event){
onTemplateReadyPlayList = function (evt) {
      
      modVP.addEventListener(brightcove.api.events.MediaEvent.BEGIN, onMediaEventFired);
      
}

function onMediaEventFired(evt) {
   onVideoPlayBeginCallBack(modVP.getCurrentVideo(onVideoPlayBeginCallBack));
}

function onVideoPlayBeginCallBack(currentVideo){

                var cid = 'myExperience'+currentVideo.id;


                captionsModule.loadDFXP(gObj[cid].href);
}


onTemplateLoadPlayList = function (experienceID) {
	player = brightcove.getExperience(experienceID);
	captionsModule = player.getModule(brightcove.api.modules.APIModules.CAPTIONS);
	captionsModule.addEventListener(brightcove.api.events.CaptionsEvent.DFXP_LOAD_SUCCESS, onDFXPLoadSuccess);
	captionsModule.addEventListener(brightcove.api.events.CaptionsEvent.DFXP_LOAD_ERROR, onDFXPLoadError); 
	modVP = player.getModule(brightcove.api.modules.APIModules.VIDEO_PLAYER);
	modVP.addEventListener(brightcove.api.events.MediaEvent.BEGIN, onMediaEventFired);
}

function onDFXPLoadSuccess(event) {
	captionsModule.getLanguages(null, log);
}
 
function onDFXPLoadError(event) {
    log(event);
}
 
function log(object) {
    if (window.console) {
        console.log(object);
    }
}
/* 
var gblPlayingVideo;
$('a[data-is-video=true]').click(function(){
		var $this = $(this);
		var object = $this.siblings('.overlay-content').find('object').parent().addClass('video-div');
		gblPlayingVideo = object.html();
		object.html('');
		$(".overlay,.close-btn").live("click",function(){                                                  
			$('.video-div').html(gblPlayingVideo);
			$('.video-div').removeClass("video-div");
			gblPlayingVideo = null;
		});
}); */

var gblPlayingVideo;
$('a[data-is-video=true]').click(function(){
		var $this = $(this);
		var object = $this.siblings('.overlay-content').find('object').parent().addClass('video-div');
		gblPlayingVideo = object.html();
		object.html('');
		$(".overlay,.close-btn").live("click",function(){                                                  
						$('.video-div').html(gblPlayingVideo);
						$('.video-div').removeClass("video-div");
						gblPlayingVideo = null;
		});
		window.setTimeout(function(){
			var protocol, bcApi;
			try {
				var pUrl = jQuery.url();
				protocol = pUrl.attr('protocol');
			} catch(e) {
				protocol = window.location.protocol;
			}
			
			if(protocol == 'https') {                    
				bcUrl = 'https://sadmin.brightcove.com/js/BrightcoveExperiences.js';  
				bcApi = 'https://sadmin.brightcove.com/js/APIModules_all.js';  				
			} else {
				bcUrl = 'http://admin.brightcove.com/js/BrightcoveExperiences.js';
				bcApi = 'http://admin.brightcove.com/js/APIModules_all.js';  				
			}	
			if(!window.brightcove) {
				$.getScript(bcUrl, function(data, textStatus, jqxhr) {
					//console.log('Brightcove loaded');
				});
			}
			
			$.getScript(bcApi, function(data, textStatus, jqxhr) {
				if (protocol == 'https') {
					var bcParam = document.createElement('param');
					bcParam.name = 'secureConnections';
					bcParam.value = 'true';
					$('.BrightcoveExperience').append(bcParam);
				}
				if(window.brightcove) {
					window.brightcove.createExperiences();
				} else {
					//console.log('Brightcove not loaded');
				}   
			});																														
		}, 251);
});
