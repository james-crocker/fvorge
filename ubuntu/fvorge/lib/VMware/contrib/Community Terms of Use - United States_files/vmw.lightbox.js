/*global $: false, console: false, VMW: true */
/*jslint browser: true, sloppy: true, forin: true, plusplus: true, maxerr: 50, indent: 4 */

/*

    Lightbox
    VERSION 0.1.1
    AUTHOR G.S.

    DEPENDENCIES:

    - jQuery 1.8.3

    TODO:

    - can push lightbox beyond bottom of page

    FUTURE:

    - margin option

*/

VMW.Lightbox = function (options) {
    var self = this,
        defaults;

    self.callbacks = {};

    // Options

    defaults = {};
    $.extend(defaults, options);
    self.options = defaults;

    // Element references

    self.$lightbox = $('<div class="overlay"><div class="container"><div class="content"><a href="#" class="close-btn"></a><div class="innerContent"></div></div></div></div>');
    self.$container = self.$lightbox.find('.container');
    self.$content = self.$lightbox.find('.innerContent');

    // Properties

    self.isVisible = false;
    self.isVideo = false;

    // Setup


    // Event Delegation

    self.$lightbox.on('click', '.close-btn', function (event) {
        event.preventDefault();
        self.hide();
    });

    $(document).on('click', '.overlay', function (event) {
        if ($(event.target).hasClass('overlay')) {
            self.hide();
        }
    });

    $(document).on('keydown', function (event) {
        if (event.keyCode === 27 && self.isVisible) {
            self.hide();
        }
    });
};

VMW.Lightbox.prototype = {
    show: function () {
        var self = this;

        self.scale();

        $('body').append(self.$lightbox).css({'overflow': 'hidden'});

        $(window).on('scroll resize', function (event) {
            self.scale();
        });

        self.isVisible = true;
        self.runCallbacks('open', {});

        if (self.isVideo) {
            // No load event from Brightcove
            setTimeout(function() {
                self.$spinner.hide();
            }, 2000);
        }		
    },
    hide: function () {
        var self = this;

        self.$lightbox.detach();

        $(window).off('scroll');

        $('body').css('overflow', '');

        self.isVisible = false;

        if (self.isVideo) {
            self.$spinner.show();
        }
    },
    // content (jQuery Element)
    setContent: function (content) {
        var self = this;

        self.$content.empty().append($(content));

        // Check for existence of spinner to indicate a video lightbox
        self.$spinner = self.$content.find('.spinner');
        self.isVideo = self.$spinner.length ? true : false;
    },
	minHeight: function (height) { //Provide min height for window as video take some time to load
        var self = this;
        self.$content.css({'min-height':height+'px'});
    },
    scale: function () {
        var self = this,
            lightboxHeight,
            lightboxWidth,
            windowHeight,
            windowWidth,
            heightReady,
            $img;

        // Remove any dynamically added CSS
        self.$content.css({
            height: '',
            width: ''
        });

        self.$content.removeClass('scrollable');

        self.$container.css({
            height: '',
            width: ''
        });

        // Use an interval to ensure container height is ready (due to race condition in DOM rendering)
        heightReady = setInterval(function () {
            if (self.$container.height()) {
                clearInterval(heightReady);

                lightboxHeight = self.$container.height();
                windowHeight = $(window).innerHeight();

                lightboxWidth = self.$container.width();
                windowWidth = $(window).innerWidth();

                if (lightboxHeight > windowHeight) {
                    self.$container.css({
                        height: windowHeight - 40
                    });

                    self.$content.css({
                        height: windowHeight - self.$lightbox.find('.close-btn').height() - 80
                    });

                    self.$content.addClass('scrollable');
                } else {
                    self.$container.css({
                        marginTop: (windowHeight - lightboxHeight) / 2
                    });
                }

                // If the contents are just an img, then reduce the width if it's too small
                if (self.$content.children('img').length) {
                    $img = self.$content.children('img').eq(0);

                    if ($img.width() < lightboxWidth - 40) {
                        self.$container.css({width: $img.width()});
                    }
                }
            }
        }, 1);
    },
    bind: function (eventType, callback, scope) {
        var self = this;

        if (typeof self.callbacks[eventType] === 'undefined') {
            self.callbacks[eventType] = [];
        }

        self.callbacks[eventType].push({
            callback: callback,
            scope: scope
        });
    },
    unbind: function (eventType) {
        var self = this;

        self.callbacks[eventType] = [];
    },
    runCallbacks: function (eventType, eventData) {
        var self = this,
            i,
            ii;

        if (typeof self.callbacks[eventType] !== 'undefined') {
            for (i = 0, ii = self.callbacks[eventType].length; i < ii; i++) {
                self.callbacks[eventType][i].callback.call(self.callbacks[eventType][i].scope || self, eventData);
            }
        }
    }
};