/*global $: false, console: false, VMW: true */
/*jslint browser: true, sloppy: true, forin: true, plusplus: true, maxerr: 50, indent: 4 */

/*

	Button Carousel
	VERSION 0.1.1
	AUTHOR G.S.

	DEPENDENCIES:

	- VMW.carousel
	- jQuery 1.7.2

	TODO:

	-
*/

VMW.ButtonCarousel = function (target, backTarget, nextTarget, options) {
	var self = this,
		i,
		ii;

	// Run parent constructor

	VMW.Carousel.call(self, target, options);

	// Element Cache

	self.$next = $(nextTarget);
	self.$back = $(backTarget);

	// Properties

	self.backEnabled = false;
	self.nextEnabled = true;

	// Setup

	if (options.hasDots && self.slideCount > 1) {
		self.$dots = $('<div class="carouselDots"></div>');

		for (i = 0; i < self.slideCount; i++) {
			if (i === 0) {
				self.$dots.append('<a class="active" href="#">&#9679;</a>');
			} else {
				self.$dots.append('<a href="#">&#9679;</a>');
			}
		}

		self.$target.append(self.$dots);

		self.$dots.on('click', 'a', function (event) {
			var index = $(this).index();
			event.preventDefault();

			if (index !== self.realIndex) {
				self.goto(index);
			}
		});
	}

	if (self.slideCount === 1) {
		self.$next.hide();
	}

	if (!self.options.infinite) {
		self.updateUI();
	}

	// Event delegation

	self.$next.bind('click', function (event) {
		event.preventDefault();

		if (self.nextEnabled || self.options.infinite) {
			self.next();
		}
	});

	self.$back.bind('click', function (event) {
		event.preventDefault();

		if (self.backEnabled || self.options.infinite) {
			self.back();
		}
	});

	if (!self.options.infinite) {
		self.bind('slideChange', function (event) {
			self.updateUI();
		});

		self.bind('scaled', function (event) {
			self.updateUI();
		});
	}
};

VMW.ButtonCarousel.prototype.updateUI = function () {
	var self = this;

	if (self.positionIndex === 0) {
		self.$next.removeClass('disabled');
		self.$back.addClass('disabled');
		self.nextEnabled = true;
		self.backEnabled = false;
	} else if (self.positionIndex + self.slidesVisible + 1 > self.slideCount) {
		self.$next.addClass('disabled');
		self.$back.removeClass('disabled');
		self.nextEnabled = false;
		self.backEnabled = true;
	} else {
		self.$next.removeClass('disabled');
		self.$back.removeClass('disabled');
		self.nextEnabled = true;
		self.backEnabled = true;
	}

	// Hide next button for "carousels" with all items currently visible
	if (self.slideCount <= self.slidesVisible) {
		self.$next.addClass('disabled');
	}

	if (self.options.hasDots) {
		self.$dots.find('a.active').removeClass('active');
		self.$dots.find('a:eq(' +  self.realIndex + ')').addClass('active');
	}
};

VMW.ButtonCarousel.prototype.events = VMW.Carousel.prototype.events;
VMW.ButtonCarousel.prototype.next = VMW.Carousel.prototype.next;
VMW.ButtonCarousel.prototype.back = VMW.Carousel.prototype.back;
VMW.ButtonCarousel.prototype.moveRelative = VMW.Carousel.prototype.moveRelative;
VMW.ButtonCarousel.prototype.goto = VMW.Carousel.prototype.goto;
VMW.ButtonCarousel.prototype.scale = VMW.Carousel.prototype.scale;
VMW.ButtonCarousel.prototype.bind = VMW.Carousel.prototype.bind;
VMW.ButtonCarousel.prototype.unbind = VMW.Carousel.prototype.unbind;
VMW.ButtonCarousel.prototype.runCallbacks = VMW.Carousel.prototype.runCallbacks;


/**************************************************************************************************************************************/
/*
    Infinity Hero Carousel
    VERSION 1.0
    AUTHOR: aravulavaru@deloitte.com.

    DEPENDENCIES:
    - jQuery

*/
// Create closure to maintain private functions.
(function($) {
 
    $.fn.vmwIHeroCarousel = function( options ) {
		var $self = $(this);
		var defaults = {
			"animDuration" : 521,
			"autoplay" : true,
			"timer" : -1,
			"slideShowDuration" : 9000
		};
		$self.options = $.extend( {}, defaults, options );
		$self.$cWrapper = $(".carouselWrapper.hero");
		$self.$hCarousel = $self.$cWrapper.find(".carousel");
		$self.$hcStrip = $self.$cWrapper.find(".strip");
		$self.$hcPrev = $self.$cWrapper.find(".carouselButton.back");
		$self.$hcNext = $self.$cWrapper.find(".carouselButton.next");
		window.vmwHeroCarousel = $self;
		if($self.$hcStrip.find("figure").length == 1)
		{
			$self.$hcPrev.hide();
			$self.$hcNext.hide();
			return false;
		}
		init($self);
		if($self.options.autoplay)
		{
			initSlideshow($self);
		}
    };

	var init = function(self){
		self.$hcPrev.removeClass("disabled");
		self.$hcStrip.find("figure").first().before(self.$hcStrip.find("figure").last());
		var figWidth = self.$cWrapper.width();
		self.$hcStrip.css("margin-left", -figWidth);
		$("figure").each(function(k,v){
			$(this).attr("id", k);
		});

		self.$hcPrev.click(function(e){prev(e,self);});
		self.$hcNext.click(function(e){next(e,self);});
		$(window).resize(function() {
		  scale(window.vmwHeroCarousel);
		});
		if(self.options.autoplay)
		{
			self.$hcStrip.find("figure").hover(
			  function (e) {
				hoverpause(window.vmwHeroCarousel);
			  },
			  function (e) {
				resetTimer(window.vmwHeroCarousel);
			  }
			);
		}
	 };
    
	var prev = function(e, self){
		e.preventDefault();		
		var figWidth = self.$hcStrip.find("figure").outerWidth();
		var indent = parseInt(self.$hcStrip.css("margin-left").replace("px","")) + figWidth;
		self.$hcStrip 
			.animate(
			{"margin-left" : indent}, 
			{duration: self.options.animDuration, queue: false, complete: function(){ 
				self.$hcStrip.find("figure").first().before(self.$hcStrip.find("figure").last());
				self.$hcStrip.css({"margin-left" : -figWidth});
		}});
		
		// reset timer
		if(self.options.autoplay)
		{
			resetTimer(self);
		}
	};

	var next =  function(e, self){
		if(e) e.preventDefault();
		var figWidth = self.$hcStrip.find("figure").outerWidth();
		var indent = parseInt(self.$hcStrip.css("margin-left").replace("px","")) - figWidth;
		self.$hcStrip.animate(
			{"margin-left" : indent}, 
			{duration: self.options.animDuration, queue: false, complete: function(){ 
				self.$hcStrip.find("figure").first().css("left","0px").insertAfter(self.$hcStrip.find("figure").last());
				self.$hcStrip.css({"margin-left" : -figWidth});
		}});

		// reset timer
		if(self.options.autoplay)
		{
			resetTimer(self);
		}
	}
	
	var scale = function(self){
		 self.$hcStrip.find("figure").width(self.$cWrapper.width());
		 self.$hcStrip.css("margin-left", -self.$cWrapper.width());
	}

	 var initSlideshow= function(self){
		if(self.options.timer < 0)
			{
				self.options.timer = window.setInterval(function(){	
					var self = window.vmwHeroCarousel;
					var figWidth = self.$hcStrip.find("figure").outerWidth();
					var indent = parseInt(self.$hcStrip.css("margin-left").replace("px","")) - figWidth;
					self.$hcStrip.animate(
						{"margin-left" : indent}, 
						{duration: self.options.animDuration, queue: false, complete: function(){ 
							self.$hcStrip.find("figure").first().css("left","0px").insertAfter(self.$hcStrip.find("figure").last());
							self.$hcStrip.css({"margin-left" : -figWidth});
					}});
				}, self.options.slideShowDuration);	
			}	 
	 }; 
	
	var resetTimer = function(self){
		window.clearInterval(self.options.timer);
		self.options.timer = -1
		initSlideshow(self);
	};

	var hoverpause = function(self){
		window.clearInterval(self.options.timer);
	};

})( jQuery );
/**************************************************************************************************************************************/