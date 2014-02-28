/* OnlineOpinion v5.4.7 */

var oo_site_us = new OOo.Ocode({
	  events: {
//		  onEntry: 40
//		, delayEntry:
//		, onSingleClick: 
		  onExit:  0
		, disableLinks: /(vmware\.com)/i
//		, disableFormElements: 
	  }    
	, cookie: {
		  name: 'oo_site_us' // 'oo_event_entry' 'oo_event_click'
		, type: 'domain'
		, expiration: 60*60*24*365 //60*60*24*365 - 365 days
	  }
	, referrerRewrite: {
		  searchPattern: null
		, replacePattern: 'http://oous.vmware.com/'
	  }
//	, onPageCard: {
//		  closeWithOverlay: true
//	  }
//	, tunnel: {
//		  path:
//		, cookieName: 
//	  }
//	, abandonment: {
//		  startPage:
//		, middle:
//		, endPage:
//	  }
	, asm: 2
//	, tealeafCookieName:
//	, clickTalePID:
	, newWindowSize: [660,780]
//	, customVariables: {
//		  Name1:
//		, Name2:
//		, Name3:
//	  }
//	, commentCardUrl:'https://survey.opinionlab.com/survey/s?s=6675'  expiration: 60 * 60 * 24 * 30 = 2592000
	, thirdPartyCookies: [{name: 'oo_site_vmw', read: true, value: '1'}, {name: 'oo_site_vmw', value: '1', set: true, expiration: 2592000}] 	
}); 

