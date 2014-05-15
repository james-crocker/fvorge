/*global $: false, console: false, VMW: false */
/*jslint browser: true, sloppy: true, forin: true, plusplus: true, maxerr: 50, indent: 4 */

/*

    Lightbox With Carousel
    VERSION 0.0.1
    AUTHOR G.S.

    DEPENDENCIES:

    - jQuery 1.8.3

    - VMW.Carousel
    - VMW.ButtonCarousel
    - VMW.Lightbox

    TODO:

    -

*/

VMW.LBCarousel = function (options) {
    var self = this,
        defaults,
        carouselMarkup = '',
        i,
        ii,
        item;

    // Options

    defaults = {
        // "triggers" is a list of anchors with thumbs for jumping to specific points in a carousel and defining its contents
        triggers: undefined,
        // "imageList" is an array of img sources for a standard carousel lightbox triggered from a single element
        imageList: undefined
    };

    $.extend(defaults, options);
    self.options = defaults;

    if (self.options.imageList) {
        self.populatedViaJSON = true;
    }

    // Build empty carousel

    carouselMarkup += '<div class="carouselWrapper hero" data-layout=\'{"0":1}\' data-lazyinit=\'true\'>';
    carouselMarkup += '    <div class="carousel"><div class="strip"></div></div>';
    carouselMarkup += '    <a href="#" class="carouselButton back">Back</a>';
    carouselMarkup += '    <a href="#" class="carouselButton next">Next</a>';
    carouselMarkup += '</div>';

    // Element references

    self.$triggers = $(self.options.triggers);
    self.$carousel = $(carouselMarkup);

    // Properties


    // Setup

    // Build out carousel contents

    if (!self.populatedViaJSON) {
        self.$triggers.each(function (index, element) {
            item = '<figure class="img-caption"><img src="' + $(element).attr('href') + '"/></figure>';

            self.$carousel.find('.strip').append(item);
        });
    } else {
        for (i = 0, ii = self.options.imageList.length; i < ii; i += 1) {
            item = '<figure class="img-caption"><img src="' + self.options.imageList[i] + '"/></figure>';

            self.$carousel.find('.strip').append(item);
        }
    }

    // Create lightbox for carousel

    self.lightbox = new VMW.Lightbox();
    self.lightbox.setContent(self.$carousel);


    // Event Delegation

    // Create a carousel once the lightbox has been opened for the first time
    self.lightbox.bind('open', function () {
        var options;

        if (!self.lightbox.carouselAttached) {
            options = {
                cssTransitioned: $.browser.msie && parseInt($.browser.version, 10) < 10 ? false : true,
                infinite: false,
                gutter: 0,
                slideLayouts: {'0': 1},
                hasDots: false
            };

            self.carousel = new VMW.ButtonCarousel(self.$carousel.find('.carousel'), self.$carousel.find('a.back'), self.$carousel.find('a.next'), options);

            $(window).on('resize', function (event) {
                self.carousel.scale();
            });

            self.lightbox.carouselAttached = true;
        }
    });

    // Using each to get the proper "index" -> index within entire page
    self.$triggers.each(function (index, element) {
        $(element).on('click', function (event) {
            event.preventDefault();
            self.lightbox.show();
            self.carousel.scale();

            if (!self.populatedViaJSON && self.carousel.realIndex !== index) {
                self.carousel.goto(index, undefined, false);
            }
        });
    });
};

VMW.LBCarousel.prototype = {};
