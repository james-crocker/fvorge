/*global $: false, console: false, VMW: true */
/*jslint browser: true, sloppy: true, forin: true, plusplus: true, maxerr: 50, indent: 4 */

/*

    VMWare
    VERSION 1.0.0
    AUTHOR G.S, N.K., M.M.

    DEPENDENCIES:

    - jQuery 1.7.2

    TODO:

    - Refactor menu (D.R.Y.)

*/

window.VMW = {
    init: function () {
        var self = this;

        self.events.parent = this;
		self.mobileBreak		= 1023;

        // Init Components

        self.nav.init();
        self.initMenu();
        self.initPhone();

		Redesign.CustomFn.init(); // call for redesign-custom.js		

        if ($('.carouselWrapper').length) {
            self.initCarousels();
        }
		
		if ($('.row').has('.match')) {
            (self.matchHeights.init());
        }

        if ($('.l-overlay').length || $('.carouselThumb').length) {
            self.initLightboxes();
        }
		
		if ($('.alerts-contain').length) {
            self.initAlerts();

            $('.alerts-contain').accordion({
                collapsible: true,
                active: true,
                animate: false,
                header: "h4",
                heightStyle: "content"
            });
        }

        if ($('.dropdown-content').length) {
            self.initDropdown();

            $('.dropdown-content').accordion({
                collapsible: true,
                active: false,
                animate: false,
                header: "h4",
                heightStyle: "content"
            });
        }

        if ($('#tabs').length) {
            $('#tabs').tabs();
        }

        if ($('.tooltip').length) {
            $(".tooltip").tooltip({tooltipClass: "tooltip-container"}, {position: {my: "left top+10", at: "left bottom", collision: "none"}});
        }
		
		//tool tip for try vmware
  		if ($('.productTooltip').length){
			var $trytip = $('.productTooltip');
			$trytip.hover(function(){
				var $this = $(this),
					toolCont = $this.find('.productTooltip-cont'),				
					topTool = toolCont.height();
				toolCont.css('top', -(topTool/2)).show();
			},
			function(e){		
				var $this = $(this),
					toolCont = $this.find('.productTooltip-cont');
				toolCont.hide();
			});
			$trytip.parents('.b-row').each(function(){
				$(this).removeClass('b-row').addClass('row');
			});
		}


        if ($('.row').has('.match')) {
            (self.matchHeights.init());
        }

        // EVENT DELEGATION
        $(window).bind('resize', function (event) {
            self.events.windowResize({width: self.getMediaWidth()});
        });

        $(window).triggerHandler('resize');
    },
    events: {
        windowResize: function (event) {
            var self = this.parent,
                i,
                ii;

            if (event.width >= self.mobileBreak && self.nav.isMobile) {
                self.nav.mobileOff();
            } else if (event.width < self.mobileBreak && !self.nav.isMobile) {
                self.nav.mobileOn();
            }
	    self.initPhone();
            self.nav.resize();
            self.intAutosuggest(); //Priyankshu

            //self.runHeightMatches();
        }
    },
    //Priyankshu
    intAutosuggest: function(){
        $('#autoCompleteUl ul').css("display" , "none");
    },
    getMediaWidth: function () {
        var self = this,
            width;

        if (typeof matchMedia !== 'undefined') {
            width = self.bruteForceMediaWidth();
        } else {
            width = window.innerWidth || document.documentElement.clientWidth;
        }

        return width;
    },
    bruteForceMediaWidth: function () {
        var i = 0,
            found = false;

        while (!found) {
            if (matchMedia('(width: ' + i + 'px)').matches) {
                found = true;
            } else {
                i++;
            }

            // Prevent infinite loop if something goes horribly wrong
            if (i === 9999) {
                break;
            }
        }

        return i;
    },
    initAlerts: function () {
        var self = this,
            $trigger            = $('.l-alerts'),
            $close              = $('.close-btn'),
            $alertContain       = $('.alerts-contain');

        self.alertsVisible  = true;

        //$alertContain.hide();

        $trigger.click(function (e) {
            if (!self.alertsVisible) {
                e.preventDefault();
                $alertContain.show();
                $trigger.addClass('active');
                self.alertsVisible = true;
            } else {
                e.preventDefault();
                $alertContain.hide();
                $trigger.removeClass('active');
                self.alertsVisible = false;
            }
        });

        $close.click(function (e) {
            e.preventDefault();
            $alertContain.hide();
            $trigger.removeClass('active');
            if (self.alertsVisible === true) {
                self.alertsVisible = false;
            }
        });
    },
    initDropdown: function () {
        var self = this,
            $ddtrigger           = $('.explore-all-button'),
            $dropdownContent       = $('.dropdown-content');

        self.dropdownVisible  = false;

        $dropdownContent.hide();

        $ddtrigger.click(function (e) {
            if (!self.dropdownVisible) {
                e.preventDefault();
                $dropdownContent.show();
                $ddtrigger.addClass('active');
                self.dropdownVisible = true;
            } else {
                e.preventDefault();
                $dropdownContent.hide();
                $ddtrigger.removeClass('active');
                self.dropdownVisible = false;
            }
		}).find($dropdownContent).click(function(e) { 
                e.stopPropagation();
        });
    },
    initCarousels: function () {
        var self = this,
            i,
            ii,
            layout;

        self.buttonCarousels = [];

        $('.carouselWrapper').each(function () {
            // Carousels in lightboxes need to be init'ed later
            if (!$(this).data('lazyinit')) {
                // Standard Carousel
                var options = {
                    cssTransitioned: $.browser.msie && parseInt($.browser.version, 10) < 10 ? false : true,
                    infinite: false,
                    gutter: 0.02,
                    slideLayouts: $(this).data('layout') || {'0': 2, '1023': 4}
                };

                // Hero Carousel config overrides
                if ($(this).hasClass('hero')) {
                    /*options.gutter = 0;
                    if ($(this).find('figure').length > 1) {
                        options.hasDots = true;
                    }*/

					// aravulavaru@deloitte.com - Hero Carousel Plugin Change - Infinity Scroll.
					$(".carouselWrapper.hero").vmwIHeroCarousel(); 	
                }
				else
				{
					self.buttonCarousels.push(new VMW.ButtonCarousel($(this).find('.carousel'), $(this).find('a.back'), $(this).find('a.next'), options));
				}
            }
        });

        $(window).bind('resize', function () {
            for (i = 0, ii = self.buttonCarousels.length; i < ii; i += 1) {
                self.buttonCarousels[i].scale();
            }
        });
    },
    initLightboxes: function () {
        var self = this,
            $triggers = $('.l-overlay');

        $triggers.each(function (index) {
            var lightbox,
				videobox,
                images;			
			
            // Only instantiate non-video lightboxes unless you're not on mobile (<= 320px viewport)
            if (!($(this).data('is-video'))) {
				if($(window).width() <= 320){					
					if (!$(this).data('is-carousel')) {
						lightbox = new VMW.Lightbox();
						lightbox.setContent($('#' + $(this).data('target-content')).html());
						
						$(this).click(function (event) {
							event.preventDefault();
							lightbox.show();
						});
					} else {
						images = JSON.parse($('#' + $(this).data('target-content')).find('script').html()).images;

						lightbox = new VMW.LBCarousel({
							triggers: $(this),
							imageList: images
						});
					}
				}
            }else{//make a seperate call for video lightboxes
				videobox = new VMW.Lightbox();
				videobox.setContent($('#' + $(this).data('target-content')).html());
				videobox.minHeight('450');//Provide min height for window as video take some time to load
				$(this).click(function (event) {
					event.preventDefault();
					videobox.show();
				});
			}
			
        });

        // Create lightbox w. carousel populated via thumbnail triggers
        if ($('.carouselThumb').length) {
            new VMW.LBCarousel({
                triggers: $('.carouselThumb')
            });
        }

    },
    initPhone: function(){		
		$('.page-contact-phone').click(function(e){
			if ($(window).width() < 700) {
				return true;
			}else{
				e.preventDefault();
			}
		});		
	},
	initMenu: function () {
        var self = this,
            $menuPri = $('#menu-primary'),
            $menulinkPri = $('.menu-link-primary');

        $menulinkPri.live("click", function (e) {
            e.preventDefault();
			//hidMenuLink();
            /*$(this).toggleClass('is-active');
            $menuPri.toggleClass('is-active');			
			if(!$menuPri.hasClass("is-active")){
				$(".page-main").css("margin-top", "0px");
			}*/
			

		if($menuPri.hasClass('is-active'))
			{
				$menulinkPri.removeClass('is-active');
				$menuPri.removeClass('is-active');
				$(".page-main").css("margin-top", "0px");
			}
			else
			{
				hidMenuLink();				
				$menulinkPri.addClass('is-active');
				$menuPri.addClass('is-active');
				$(".page-main").css("margin-top",$menuPri.height());
			}			
        });	

		/** 25th July - fix for showing dropdown on re-size of screen ****/
		// Modified the event binder from .click() to .live()

        // Search
        var $menuSearch = $('#menu-search'),
            $menulinkSearch = $('.menu-link-search');

		// Quick Links
        var $menuQuick = $('#menu-quick'),
            $menulinkQuick = $('.menu-link-quick');
		
		// Share
        var $menuShare = $('#menu-share'),
            $menulinkShare = $('.menu-link-share');

		var hidMenuLink = function(){
			$menulinkSearch.removeClass('is-active');
			$menuSearch.removeClass('is-active');
			$menulinkQuick.removeClass('is-active');
			$menuQuick.removeClass('is-active');
			$menulinkShare.removeClass('is-active');
			$menuShare.removeClass('is-active');
			$menuPri.removeClass('is-active');
			$menulinkPri.removeClass('is-active');
			if(parseInt($(".page-main").css("margin-top").replace("px","")) > 0) $(".page-main").css("margin-top", "0px");
		}

        $menulinkSearch.live("click",function () {			
            if($menulinkSearch.hasClass('is-active'))
			{
				$menulinkSearch.removeClass('is-active');
				$menuSearch.removeClass('is-active');
			}
			else
			{
				hidMenuLink();
				$menulinkSearch.addClass('is-active');
				$menuSearch.addClass('is-active');
			}
			return false;
        });

        
        $menulinkQuick.live("click",function () {			
            if($menulinkQuick.hasClass('is-active'))
			{
				$menulinkQuick.removeClass('is-active');
				$menuQuick.removeClass('is-active');
			}
			else
			{
				hidMenuLink();
				$menulinkQuick.addClass('is-active');
				$menuQuick.addClass('is-active');
			}			
            return false;
        });

        $menulinkShare.live("click",function () {			
            if($menulinkShare.hasClass('is-active'))
			{
				$menulinkShare.removeClass('is-active');
				$menuShare.removeClass('is-active');
			}
			else
			{
				hidMenuLink();
				$menulinkShare.addClass('is-active');
				$menuShare.addClass('is-active');
			}			
            return false;
        });
		
		/** 25th July - fix for showing dropdown on re-size of screen ****/
    }
};
