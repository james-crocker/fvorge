/*global $: false, console: false, VMW: true */
/*jslint browser: true, sloppy: true, forin: true, plusplus: true, maxerr: 50, indent: 4 */
/*

    Navigation Component
    VERSION 0.1
    AUTHORS: N.K., G.S.

    DEPENDENCIES:
    - vmw.main.js
    - jQuery

*/

VMW.nav = {
    init: function () {
        // fn init
        var self = this,
            key;

        // ELEMENTS
        self.elPrimaryTrigger       = $('<a href="#menu-primary" class="menu-link menu-link-primary">Menu</a>');
        self.elSearchTrigger        = $('<a href="#menu-search" class="menu-link menu-link-search">Menu</a>');
        self.elQuickLinksTrigger    = $('<a href="#menu-quick" class="menu-link menu-link-eyebrow menu-link-quick">Quick Links</a>');
        self.elShareTrigger         = $('<a href="#menu-share" class="menu-link menu-link-eyebrow menu-link-share">Share</a>');
        //self.elSubMenuItem        = $('.has-subnav > a').not(".menu-section-link");
		self.elSubMenuItem          = $('.has-subnav > a');
        self.elPrimaryMenu          = $('#menu-primary');
        self.elSearchMenu           = $('#menu-search');
        self.elQuickLinksMenu       = $('#menu-quick');
        self.elShareMenu            = $('#menu-share');

        // PROPERTIES
        self.isMobile           = false;
        self.visibleMenu        = null;
        self.triggersInserted   = false;
		self.mobileBreak		= 1023;
        self.mobileInit         = false;
        self.desktopInit        = false;

        // SETUP
        if (VMW.getMediaWidth() < self.mobileBreak) {
            self.mobileOn();
        } else {
            self.mobileOff();
        }

        // OBJECTS
        self.menus = {
            primary: {
                $menu: self.elPrimaryMenu,
                $trigger: self.elPrimaryTrigger
            },
            search: {
                $menu: self.elSearchMenu,
                $trigger: self.elSearchTrigger
            },
            quick: {
                $menu: self.elQuickLinksMenu,
                $trigger: self.elQuickLinksTrigger
            },
            share: {
                $menu: self.elShareMenu,
                $trigger: self.elShareTrigger
            }
        };

        // EVENT DELEGATION
        function bindTrigger(trigger, menuName) {
            trigger.click(function (event) {
                event.preventDefault();

                if (self.visibleMenu !== menuName) {
                    self.showNav(menuName);
                } else {
                    self.hideNav(menuName);
                }
            });
        }

        for (key in self.menus) {
            //bindTrigger(self.menus[key].$trigger, key);
        }
    },
    resize: function () {
        // fn hideNav
        var self = this;

        if (VMW.getMediaWidth() < self.mobileBreak) {
            self.mobileOn();
        } else {
            self.mobileOff();
        }

        if(self.visibleMenu) {
            self.menus[self.visibleMenu].$menu.removeClass('is-active');
            self.menus[self.visibleMenu].$trigger.removeClass('is-active');
            self.visibleMenu = null;
            $(".page-main").css("margin-top", "0px");   
        }
        
    },
    mobileOn: function () {
        // fn mobileOn
        var self = this;
		
        if (!self.triggersInserted) {
            self.elPrimaryMenu.before(self.elPrimaryTrigger);
            self.elSearchMenu.before(self.elSearchTrigger);
            self.elQuickLinksMenu.before(self.elQuickLinksTrigger);
            self.elShareMenu.before(self.elShareTrigger);

            self.triggersInserted = true;
        } else {
            self.elPrimaryTrigger.show();
            self.elSearchTrigger.show();
            self.elQuickLinksTrigger.show();
            self.elShareTrigger.show();
        }

        if(self.mobileInit == true) {
            return;
        }	

        self.elSubMenuItem.live('click',function (event) {
			event.preventDefault();
            if (VMW.getMediaWidth() < self.mobileBreak) {               
				var $this = $(this),
					$nextUL = $this.next('ul'),
					$sublinks = $nextUL.find('.has-subnav > ul');
				if(!$sublinks.hasClass('is-active')){
					$this.addClass('is-active');
					$nextUL.addClass('is-active');
					$sublinks.addClass('is-active');
				}else{
					$this.removeClass('is-active');
					$nextUL.removeClass('is-active');
					$sublinks.removeClass('is-active');
				}                
                self.movePage();
            }
        });
	 

        self.isMobile = true;
        self.mobileInit = true;
    },
    mobileOff: function () {
        // fn mobileOff
        var self = this;
		if($('.menu-link-share').length == 0)
		{
			self.elShareMenu.before(self.elShareTrigger);
		}
        if (self.triggersInserted) {
            self.elPrimaryTrigger.hide();
            self.elSearchTrigger.hide();
            self.elQuickLinksTrigger.hide();
            self.elShareTrigger.hide();
			$('#menu-search.menu.is-active').removeClass('is-active');
			$('#menu-quick.menu.menu-eyebrow.is-active').removeClass('is-active');
			$('.menu.menu-eyebrow.is-active#menu-share').removeClass('is-active');
			$('.menu-link-search.is-active').removeClass('is-active');
			$('.menu-link-quick.is-active').removeClass('is-active');
			$('.menu-link-share.is-active').removeClass('is-active');
        }
		
		self.elSubMenuItem.die('click'); // unbind click function on desktop view		
		
		if($('.page-header').length){
			$('.page-header').next('.page-main').css('margin-top','0'); //remove margin top
		}	
		
        if(self.desktopInit == true) {
            return;
        }
		
		self.elSubMenuItem.hover(function (event) {            
            if (VMW.getMediaWidth() > self.mobileBreak) {
                event.preventDefault();
				if($(this).hasClass("menu-section-link")) return; // rightnav hover fix
				if($(this).hasClass("menu-section-sublink")) return; // rightnav hover fix
                if($(this).hasClass("is-active")) return; // rightnav selected page bold link fix.
                $(this).removeClass('is-active');
                $(this).next('ul').removeClass('is-active');
                $(this).next('ul').find('.has-subnav').children('ul').removeClass('is-active');
                //console.log("value: " + self.elSubMenuItem.offset().left);
                // This is the container: $(this).next('ul').offset().left
                // This is the button: $(this).offset().left
                //console.log("Button: " + $(this).offset().left + " Dropdown: " + $(this).next('ul').offset().left);
                if($(this).offset().left < $(this).next('ul').offset().left) {
                    var diff = $(this).next('ul').offset().left - $(this).offset().left;
                    $(this).next('ul').css("right", diff);
                }
            }            
        });			

		/* Expand and collapse for right nav links*/
		/*http://iwov-stage-preview-1.vmware.com:83/preview/321529?areavpath=/generated/news/latest*/
		if(!$("a.menu-section-link.is-active").parent().find("ul").hasClass("is-active")) {$("a.menu-section-link").removeClass("is-active");}
		$(".has-subnav > a.menu-section-link").live("click", function(event){
			event.preventDefault();
			var $self = $(this);
			var $parLi = $self.parent();
			var $ulLinks = $parLi.find("ul").first();
			
			if($self.hasClass("is-active"))
			{
				// menu expanded state
				$self.removeClass("is-active");
				$ulLinks.removeClass("is-active");
			}
			else
			{
				// menu collapsed state
				$self.addClass("is-active");
				$ulLinks.addClass("is-active");
			}
		});
		/* Expand and collapse for right nav links*/


        self.isMobile = false;
        self.desktopInit = true;
    },

    movePage: function () {
        var menu_height = $("#menu-primary").css("height");
        $(".page-main").css("margin-top", menu_height);
    },

    hideNav: function (menu) {
        // fn hideNav
        var self = this;

        self.menus[self.visibleMenu].$menu.removeClass('is-active');
        self.menus[self.visibleMenu].$trigger.removeClass('is-active');
        self.visibleMenu = null;
        $(".page-main").css("margin-top", "0px");
    },
    showNav: function (menu) {
        // fn showNav 
        var self = this;
        
        if (self.visibleMenu !== null) {
            self.hideNav(self.visibleMenu);
        }

        self.menus[menu].$menu.addClass('is-active');
        self.menus[menu].$trigger.addClass('is-active');
        self.visibleMenu = menu;

        if(self.isMobile == false) {
            //console.log("self.menus[menu].$trigger.left: " + self.menus[menu].$trigger.css("left"));
        }

        self.movePage();
    }
};