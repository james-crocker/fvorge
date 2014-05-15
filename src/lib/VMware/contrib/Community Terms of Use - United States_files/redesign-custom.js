
/*

    VMWare CUSTOM JS
    VERSION 0.0.1
    AUTHOR KARTHIK NAIDU

    DEPENDENCIES:
    - jQuery 1.8.3

    TODO:
    - ADDITIONAL FUNCTIONALITIES OTHER THAN MAIN.JS

*/
Redesign = {},
Redesign.CustomFn = {
	init: function () {
		var self = this;
		
		//Fix for tabs issue starts - base plug in - jQuery UI
		tabLinks        = $('#tabs .pd-main:first-child').find('h3').next('ul').find('li > a');
		numOfTabs       = tabLinks.length;
		for (index = 0; index < numOfTabs; index ++)
		{
			oldAnchor       = $(tabLinks[index]).attr('href');
			hashPos         = oldAnchor.indexOf('#');
			newAnchor       = oldAnchor.substr(hashPos);
			$(tabLinks[index]).attr('href', newAnchor);
		}
		
		if($('#hideMega').length) $('#menu-primary li.has-subnav').find('ul').addClass('hideMega');
		
		if($('#hideHead').length){
			setTimeout(function(){
				var hideHead = $.trim($('#hideHead').attr('value'));
				if($('h1.h-1.b-wid-75').text() == '') $('h1.h-1.b-wid-75').text(hideHead);
			},10);
		}
		
		if($('#TheForm').length){
			$('#TheForm').parents('.b-row').each(function(){
				$(this).addClass('row').removeClass('b-row');
			});
			
			$('#TheForm').find('.b-row').each(function(){
				$(this).addClass('row').removeClass('b-row');
			});
		}
		
		if($('#footer .a-row .a-1of2').length){
			$('#footer').find('.a-row > .a-1of2:even').addClass('a-clear');
		}
			// Submit for login button
			var $login = $('#login');
			if($login.length){
			$login.on('submit', function (event) {
				var $errMsg = $('.errMsg'),
					$username = $('#username'),
					$password = $('#password');
				$errMsg.html('');
				var username = $.trim($username.val()),
					userplace = $.trim($username.attr('placeholder')),
					password = $.trim($password.val()),
					passplace = $.trim($password.attr('placeholder'));
				if(username == '' || username == userplace || password == '' || password == passplace){		
					if(username == '' || username == userplace){
						$errMsg.append('<span class="user">Please enter user name</span>');
					}else{
						$errMsg.find('.user').remove();
					}
					if(password == '' || password == passplace){
						$errMsg.append('<span class="pass">Please enter password</span>');
					}else{
						$errMsg.find('.pass').remove();
					}		
					return false;
				}else {								
					self.setStartUrl();
					return true;
				}
			});
			}
		//free form tables manipulation
		self.$securityTable = $('.security_content table');
		if(self.$securityTable.length){
			self.$securityTable.each(function(){ 
				var $table = $(this),
					$tr = $(this).find('tr'),
					$td = $(this).find('tr td'),
					trCount = 0,
					trEmpty = false;
					$table.wrap('<div class="freeform-table" />');
				$tr.each(function(){
					trCount++;
					if(trCount == 1) $(this).addClass('firstTr').addClass('tableHead');
					if(trCount == 2) $(this).addClass('secondTr').addClass('tableHead');
					$(this).find('td').each(function(){
						var tdCont = $.trim($(this).text());
						if(tdCont == '') trEmpty = true;
						else trEmpty = false;				
					})
					if(trEmpty) $(this).hide();
				});
				$td.each(function(){
					var $tdCont = $.trim($(this).html());
					if  ($tdCont.indexOf("====") >= 0) $(this).parent('tr').addClass('tableDivider');
				});
			});
		}
				
		//Change the action attr of form on dropdown change
		/* if($('form#job-search-form').length){
			$('select#job-categories').change(function(){
				var sel = $(this).val();
				$(this).parents('form#job-search-form').attr('action', sel);
			});
		}	 */
		
		if($('.freeform-table').length){
			$('.freeform-table').wrap('<div class="freeform-wrap" />').after('<div class="shadow" />');
		}
		
		//Events feed ajax call
		var $eventsFeed = $('#EventsModule');
		if($eventsFeed.length){
			var count = parseInt($eventsFeed.attr('count')),
				pageUrl = window.location.href.split('.com/'),
				conCode = pageUrl[1].split('/'),
				country = conCode[0],
				jsonUrl = '/events',
				eventsUrl = jsonUrl+'/json:true';
			//events/country:united+states/num:15/json:true	

			// Start 
				var urlLocaleMapper = {};
				urlLocaleMapper["de"] = "/de/events/company/country:europe";
				urlLocaleMapper["at"] = "/de/events/company/country:europe";
				urlLocaleMapper["be/nl"] = "/events/region:europe";
				urlLocaleMapper["be/fr"] = "/fr/events/company/country:europe";
				urlLocaleMapper["cz"] = "/events/region:europe";
				urlLocaleMapper["fr"] = "/fr/events/company/country:europe";
				urlLocaleMapper["hu"] = "/events/region:europe";
				urlLocaleMapper["it"] = "/it/events/company/country:europe";
				urlLocaleMapper["nl"] = "/events/region:europe";
				urlLocaleMapper["ru"] = "/ru/events/company/country:europe";
				urlLocaleMapper["pl"] = "/events/region:europe"
				urlLocaleMapper["es"] = "/es/events/company/country:europe";
				urlLocaleMapper["se"] = "/events/region:europe";
				urlLocaleMapper["ch"] = "/de/events/company/country:europe";
				urlLocaleMapper["tr"] = "/events/region:europe";
				urlLocaleMapper["uk"] = "/uk/events/company/country:europe";
				urlLocaleMapper["ar"] = "/latam/events/region:americas";
				urlLocaleMapper["br"] = "/br/events/country:brazil";
				urlLocaleMapper["cl"] = "/latam/events/region:americas";
				urlLocaleMapper["co"] = "/latam/events/region:americas";
				urlLocaleMapper["latam"] = "/latam/events/region:americas";
				urlLocaleMapper["pe"] = "/latam/events/region:americas";
				urlLocaleMapper["ve"] = "/latam/events/region:americas";
				urlLocaleMapper["il"] = "/events/region:europe";
				urlLocaleMapper["mena"] = "/events/country:united+arab+emirates";
                                urlLocaleMapper["mx"] = "/mx/events/country:mexico";
				urlLocaleMapper["ap"] = "/ap/events/region:asia+pacific";
				urlLocaleMapper["au"] = "/au/events/region:asia+pacific";
				urlLocaleMapper["cn"] = "/cn/events/country:china";
				urlLocaleMapper["in"] = "/in/events/region:asia+pacific";
				urlLocaleMapper["jp"] = "/jp/events/country:japan";
				urlLocaleMapper["kr"] = "/kr/events/region:asia+pacific";
				urlLocaleMapper["tw"] = "/tw/events/region:asia+pacific";
				urlLocaleMapper["ca/en"] = "/events/region:americas";
				urlLocaleMapper["ca/fr"] = "/events/region:americas";
							
				if(country != "company")
				{
					if(country == "be" || country == "ca")
					{
						var locale = conCode[1];
						jsonUrl = urlLocaleMapper[country+"/"+locale];
					}
					else
					{
						jsonUrl = urlLocaleMapper[country];
					}
				}
				else
				{
					jsonUrl = '/events/country:united+states';	
				}
				
			// End 
			/*if(country != 'company'){
				jsonUrl = '/'+country+'/event'
			}else{
				jsonUrl = '/events/country:united+states'
			}*/
			if(count){
				if(count < 10) count = '0'+count;
				else if(count > 99) count = '01';
				eventsUrl = jsonUrl+'/num:'+count+'/json:true';
			}
			
			$.getJSON(eventsUrl, function(data) {
				var items = [];
				$.each(data, function(key, val) {
					if(val.event_registration_link.length){//check of links are available for events
						var splitLink = val.event_registration_link.split("target='_blank'>");
						var eventLink = splitLink[0]+"target='_blank'>"+val.event_name+"</a>";
					}else{
						var eventLink = val.event_name;
					}
					items.push('<div class="bd-t1-gray pd-t10 pd-b10"><p class="c-body pd-b5">' + val.event_start_date + '</p>'+ eventLink + '</div>');
				});
				$('<div/>', {
				'class': 'eventsFeedDisplay',
				html: items.join('')
				}).appendTo($eventsFeed);
			}).fail(function(){
				//$eventsFeed.html('Failed to load events');
			});
		}	
		
		var $feedback = $('.footer-feedback');
		if($feedback.length){
			$feedback.live("click", function(event){
                var l = this.href;
				/*http://support.microsoft.com/kb/257321*/
				if(this.href.indexOf("void(0)") < 0)
				{
								this.href = this.href+" void(0);";
				}
                if(l.indexOf('(') && l.indexOf(')')) 
                {
					var o = (l.split('(')[1].split(')')[0]).split(",");
					window.open(o[0].replace(/'/g,""), o[1], (o[2]+","+o[3]+","+o[3]+","+o[4]+","+o[5]+","+o[6]+","+o[7]+","+o[8]+","+o[9]).replace(/'/g,""));
				}
                event.preventDefault();
                return false;
			});
		}	
		

		//Change mouseover text as per country
	/*	var split = location.search.replace('?', '').split('apac='),
			urlcode = split[1];
		if(!urlcode) var countryname = $.trim($('.menu-item-country > a').text());
		else var countryname = $.trim(urlcode);
		if(countryname.length){
			$.getJSON('/files/js/framework/countryhover.json', function(data) {
				if(data!=null){				
					 $.each(data, function(i, item) {
						var country = $.trim(item.country),
							locale = item.locale,
							hover = item.hover;
						if(country == countryname) {
							if(urlcode) $('.menu-item-country > a').attr('title', hover).text(locale).prepend('<span class="icon icon-usa" />');
							else $('.menu-item-country > a').attr('title', hover);
						}
					 });
				}
			})
		}
		*/
		
		
		//Custom Select Box
		var $selectBox = $('select'),
			$lang = $('html').attr('lang');
		if($selectBox.length && $lang!= 'ja' && $lang!= 'zh' && $lang!= 'ko'){
			$.getScript("/files/js/framework/jquery-selectbox.js", function(){
				$('select').selectbox();
			})
			.fail(function(jqxhr, settings, exception) {
				//alert('unable to load custom dropdowns');
			});
		}
		
		//Fallback tooltips
		if($('a').length){
			$.getScript("/files/js/framework/vmw.jquery.fallback.tooltip.js", function(){
				//do nothing
			})
			.fail(function(jqxhr, settings, exception) {
				//alert('unable to fall back tooltips');
			});
		}
		
		if($('.pd-main form').length){
			$.getScript("/files/templates/inc/forms/forms.js", function(){
				Forms.validations.init();
			})
			.fail(function(jqxhr, settings, exception) {
				//alert('unable to load form validations');
			});
		}
		
		// free form html dropdowns hide issue fix in list of items view and job module page
		var $listDiv = $('#lists'),
			$jobFormSearch = $('#job-search-form');		
		if($listDiv.length) $listDiv.parents('.pd-main').find('.b-row').removeClass('b-row');
		if($jobFormSearch.length) $jobFormSearch.parents('.pd-main').find('.b-row').removeClass('b-row');
		
		//debugger;
		var filterButtons = $("a.support-search-button");
		if(filterButtons.length){
			$(filterButtons).each(function(){
				if($(this).html() == "Hide Filters"){
					$(this).html("Show Filters");
					$(this).removeAttr("href");					
					$(this).click(function(){						
						if($(this).html() == "Show Filters"){
							$(this).html("Hide Filters");
							$("#filter-content").parent().removeClass("a-hide-block");
						}else if($(this).html() == "Hide Filters"){
							$(this).html("Show Filters");
							$("#filter-content").parent().addClass("a-hide-block");
						}						
					});
				}
			});
		}
		
		if($('h1.h-1').length){	//temp fix for label issue
			var h1 = $('h1.h-1.b-wid-75'),
				h1text = $.trim(h1.text());
			h1.html(h1text);
		}
		
		if($("#menu-share").length){
			/*http://support.sharethis.com/customer/portal/articles/475097-ssl-support#sthash.3JFJGYaK.dpbs */
			var switchTo5x=true;
			var url = document.location.protocol == "http" ? "http://w.sharethis.com/button/buttons.js" : "https://ws.sharethis.com/button/buttons.js";
			$.getScript(url, function(){
				//console.log('loaded');
			})
			.done(function(){
				stLight.options({publisher: "ur-7d4b1f76-45d-c891-c19-c2924529ce2", doNotHash: false, doNotCopy: false, hashAddressBar: false});
			})
			.fail(function(jqxhr, settings, exception) {
			   //console.log("Failed to load share widgets");
			});
		}

			window.setTimeout(function(){
				$("body").append("<div id='ph-locale-text-holder' style='display:none'></div>");
				$("[placeholder]").each(function(){
					var placeholder = $(this).attr("placeholder");
					placeholder = placeholder === null ? "" : placeholder;
					$("#ph-locale-text-holder").empty();
					$("#ph-locale-text-holder").html(placeholder);
					placeholder = $("#ph-locale-text-holder").text();
					if($.browser.msie && $.browser.version == "8.0")
					{
						$(this).val(placeholder);
					}
					else
					{
						if(!$(this).val())
						$(this).attr("placeholder", placeholder);
					}
				});	
			},521);
	},
	setStartUrl: function(){ //Old function imported from vmware.com
		startURLst=window.location.search.substring(1);		
		document.getElementById("startURL").value=startURLst;		
	}
	
}

/*

    AUTHOR WENDY
    TODO:
    - add SAT required js files

*/

window.vmf=function(){
var _1=function(id){
return $("#"+id);
};
var _3=function(_4){
document.write("<script src=\"",_4,"\" type=\"text/javascript\"></script>");
};
var _5=[];
return {loadJs:function(_6,_7,_8){
if(($.inArray(_6,_5)<0)){
(_7)?$.getScript(_6,_8):_3(_6);
}
},loadCss:function(_9){
var _a=document.createElement("link");
_a.setAttribute("rel","stylesheet");
_a.setAttribute("type","text/css");
_a.setAttribute("href",_9);
document.getElementsByTagName("head")[0].appendChild(_a);
},dom:function(){
return {onload:function(_b){
$(document).ready(_b);
},unload:function(_c){
$(window).unload(_c);
},id:function(id){
return document.getElementById(id);
},getHtml:function(id){
return _1(id).html();
},setHtml:function(id,val,pos){
switch(pos){
case "before":
_1(id).prepend(val);
break;
case "after":
_1(id).append(val);
break;
default:
_1(id).html(val);
}
},addHandler:function(_12,_13,_14){
(_12 instanceof jQuery?_12:jQuery(_12)).bind(_13,_14);
},removeHandler:function(_15,_16,_17){
(_15 instanceof jQuery?_15:jQuery(_15)).unbind(_16,_17);
},get:function(_18){
return $(_18);
},serialize:function(_19){
return jQuery(_19).serialize();
},trigger:function(_1a,_1b){
(_1a instanceof jQuery?_1a:jQuery(_1a)).trigger(_1b);
}};
}(),cookie:function(){
return {read:function(_1c){
var _1d=_1c+"=";
var ca=document.cookie.split(";");
for(var i=0;i<ca.length;i++){
var c=ca[i];
while(c.charAt(0)==" "){
c=c.substring(1,c.length);
}
if(c.indexOf(_1d)==0){
return c.substring(_1d.length,c.length);
}
}
return null;
},write:function(_21,_22,_23){
var _24="";
if(_23){
var _25=new Date();
_25.setTime(_25.getTime()+(_23*24*60*60*1000));
_24="; expires="+_25.toGMTString();
}else{
_24="";
}
document.cookie=_21+"="+_22+_24+"; path=/";
},clear:function(_26){
vmf.cookie.write(_26,"",-1);
}};
}(),json:function(){
return {txtToObj:function(txt){
try{
return $.evalJSON(txt);
}
catch(ex){
return null;
}
},objToTxt:function(obj){
return $.toJSON(obj);
}};
}(),array:function(){
return {contains:function(val,_2a){
return ($.inArray(val,_2a)>-1);
},txtToAry:function(txt){
return txt.split(",");
},aryToTxt:function(_2c){
return _2c.join(",");
},objToAry:function(obj){
return $.makeArray(obj);
}};
}(),string:function(){
return {setCharAt:function(str,i,c){
if(i>=str.length){
return str;
}else{
var n=str.substring(0,i);
n+=c;
n+=str.substring(i+1,str.length);
return n;
}
},trim:function(str){
return $.trim(str);
}};
}(),ns:function(){
return {use:function(_33){
var ary=_33.split(".");
var obj=window;
for(var i in ary){
if(!obj[ary[i]]){
obj[ary[i]]={};
obj=obj[ary[i]];
}else{
obj=obj[ary[i]];
}
}
}};
}(),ajax:function(){
return {connect:function(o){
$.ajax(o);
},get:function(url,_39,_3a,_3b,_3c,_3d){
var o={type:"GET",url:url,data:_39,success:_3a,error:_3b,complete:_3c};
if(_3d){
o.timeout=_3d;
}
jQuery.ajax(o);
},post:function(url,_40,_41,_42,_43,_44){
var o={type:"POST",url:url,data:_40,success:_41,error:_42,complete:_43};
if(_44){
o.timeout=_44;
}
jQuery.ajax(o);
}};
}(),form:function(){
return {serialize:function(id,_47){

var _48=vmf.dom.id(id)||document.forms[id];

if(!_48){

return null;

}

if(_47){

var _49=[];
for(var i in _47){
_49.push(_48[_47[i]]);
}
return jQuery(_49).serialize();
}else{
return jQuery(_48).serialize();
}
},getRadioBtn:function(id,_4c){
var _4d=vmf.dom.id(id)||document.forms[id];
if(!_4d){
return null;
}
return jQuery("input[@name='"+_4c+"']:checked").val();

},getCbk:function(id,_4f){

var _50=vmf.dom.id(id)||document.forms[id];

if(!_50){

return false;

}

return _50[_4f].checked;

},setCbk:function(id,_52,val){

val=val||true;

var _54=vmf.dom.id(id)||document.forms[id];

if(_54){

_54[_52].checked=val;

}

}};

}(),url:function(){

return {getParam:function(_55){

var url=window.location.toString();

var _57=url.indexOf("?");

if(_57<0){

return null;

}
var _58=url.substring(_57+1,url.length).split("&");
for(var i in _58){
var _5a=_58[i].split("=");
if(_5a[0]==_55){
return _5a[1];
}
}
return null;
},hasAnchor:function(_5b){
var url=window.location.toString();
var _5d=url.indexOf("#");
if(_5d<0){
return false;
}else{
return (url.substring(_5d+1,url.length)==_5b);
}
},redirect:function(_5e){
if(!_5e.url){
return;
}
switch(_5e.target){
case "new":
window.open(_5e.url);
break;
default:
document.location=_5e.url;
}
}};
}()};
}();

$(document).ready(function(){
	jQuery.getScriptCache = function(url, callback) {
		return jQuery.ajax({
			type: "GET",
			url: url,
			data: null,
			success: callback,
			dataType: "script",
			cache: true
		});
	};
    vmf.hostname = window.location.protocol+"//www.vmware.com";
    switch (window.location.hostname) {
        /* PROD */
        case 'www.vmware.com':
        case 'downloads.vmware.com':
            vmf.hostname = window.location.protocol+"//www.vmware.com";
            break;
        /* STAGE, UAT, and LT */
        case 'phnx-portal-stage.vmware.com':
        case 'downloads-stage.vmware.com':
            vmf.hostname = window.location.protocol+"//phnx-portal-stage.vmware.com";
            break;
        case 'www-uat.vmware.com':
            //vmf.hostname = window.location.protocol+"//www-uat.vmware.com";
              vmf.hostname = "http://wwwa-qa-lamp-1.vmware.com";            
              break;
        case 'www-lt.vmware.com':
            vmf.hostname = window.location.protocol+"//www-lt.vmware.com";
            break;
        case 'www-test2.vmware.com':
            vmf.hostname = window.location.protocol+"//www-test2.vmware.com";
            break;
			/* QA */
        case 'portal-vmwperf.vmware.com':
		case 'www-test6.vmware.com':
		case 'iwov-dev-preview-1.vmware.com':
		case 'iwov-stage-preview-1.vmware.com':
		case 'www-redesign.vmware.com':
		case 'www-dev12.vmware.com':
		case 'www-test12.vmware.com':
        case 'downloads-qa.vmware.com':
            vmf.hostname = "http://wwwa-qa-lamp-1.vmware.com";
            break;
        /* DEV */
        case 'newcastle.vmware.com':
		case 'www-dev6.vmware.com':
        case 'wwwa-dev-sso-1.vmware.com':
            /* lmpimage2 does not support https, force http */
            vmf.hostname = "http://lmpimage2.vmware.com";
            break;
        case 'serafina.vmware.com':
           vmf.hostname = window.location.protocol+"//serafina-home.vmware.com";
            break;
        default:
            vmf.hostname = window.location.protocol+"//www.vmware.com";
            break;
    }

    /* Load all the files that the SAT module requires */
    jQuery.getScriptCache(vmf.hostname+"/files/include/vmf/plugin/jquery.md5.js", function(script) {
        if (jQuery.md5 === undefined) { eval(script); }  // work around for bug in jQuery 1.2.x
        jQuery.getScriptCache(vmf.hostname+"/files/include/vmf/plugin/jquery.cookie.1.0.js", function(script) {
            if (jQuery.cookie === undefined) { eval(script); }  // work around for bug in jQuery 1.2.x
            jQuery.getScriptCache(vmf.hostname+"/files/include/vmf/plugin/javascript-xpath.js", function(script) {
                if (document.evaluate === undefined) { eval(script); }  // work around for bug in jQuery 1.2.x
                jQuery.getScriptCache(vmf.hostname+"/files/include/vmf/module/core/js/log.js", function(script) {
                    if (vmf.log === undefined) { eval(script); }  // work around for bug in jQuery 1.2.x
                    jQuery.getScriptCache(vmf.hostname+"/files/include/vmf/module/sat/sat.js", function(script) {
                        if (vmf.sat === undefined) { eval(script); }  // work around for bug in jQuery 1.2.x
                        vmf.sat.fetchAlerts();
                    });
                });
            });
        });
    });	
});

var p1='profile.company='+unescape(company_name);
var p2='profile.industry='+unescape(industry);
var p3='profile.subindustry='+unescape(sub_industry);
var p4='profile.employeerange='+unescape(employee_range);
var p5='profile.city='+unescape(city);
var p6='profile.state='+unescape(state);
var p7='profile.country='+unescape(country);
var p8='profile.audience='+unescape(audience);
