/*global $: false, console: false, VMW: true */
/*jslint browser: true, sloppy: true, forin: true, plusplus: true, maxerr: 50, indent: 4 */

/*

	Responsive Carousel
	VERSION 0.7.3
	AUTHOR G.S.

	DEPENDENCIES:

	- jQuery 1.7.2

	TODO:

	- Add pagination bullets?
	- height equalization (perhaps optional)

	ISSUES:

	-
*/

VMW.Carousel = function (target, options) {
	var self = this,
		defaults;

	self.events = {
		slideChange: function (event) {
			self.runCallbacks('slideChange', event);
		},
		scaled: function (event) {
			self.runCallbacks('scaled', event);
		}
	};

	// Options

	defaults = {
		cssTransitioned: true,
		slideLayouts: {
			0: 1
		},
		infinite: false,
		gutter: 0, // Percentage (float) of Carousel width
		debug: false
	};

	$.extend(defaults, options);

	self.options = defaults;

	// Element references

	self.$target = $(target);
	self.$strip = $(target).find('.strip');
	self.$slides = self.$strip.children();
	self.$fakeStartGroup = $();
	self.$fakeEndGroup = $();

	// Properties

	self.callbacks = {};
	self.realIndex = 0;
	self.positionIndex = 0;
	self.displayMap = []; // A mirror for indexes of slides in the DOM
	self.slideCount = self.$slides.length;
	self.slidesVisible = null;
	self.width = self.$target.width();
	self.slideWidth = null;
	self.isTransitioning = false;

	// Touch tracking

	self.startXPosition = 0;
	self.lastXPosition = 0;

	// Setup

	self.scale();

	// Prevent document movement when touching the carousel

	$(window.document).bind('touchmove', function (event) {
		if ($(event.target).parents().is(self.$target)) {
			event.preventDefault();
		}
	});

	// Event Delegation

	self.$strip.bind('touchstart', function (event) {
		self.startXPosition = event.originalEvent.pageX;
		self.lastXPosition = event.originalEvent.pageX;
	});

	self.$strip.bind('touchmove', function (event) {
		var delta;

		delta = -1 * (self.lastXPosition - event.originalEvent.pageX);
		self.lastXPosition = event.originalEvent.pageX;
		self.moveRelative(delta);
	});

	self.$strip.bind('touchend', function (event) {
		if (self.startXPosition > self.lastXPosition) {
			self.next();
		} else {
			self.back();
		}
	});
};

VMW.Carousel.prototype = {
	next: function () {
		var self = this;

		if (self.options.infinite) {
			self.goto(self.displayMap[self.positionIndex + self.slidesVisible], 'forward');
		} else {
			self.goto(self.realIndex + self.slidesVisible, 'forward');
		}
	},
	back: function () {
		var self = this;

		if (self.options.infinite) {
			self.goto(self.displayMap[self.positionIndex - self.slidesVisible], 'backward');
		} else {
			self.goto(self.realIndex - self.slidesVisible, 'backward');
		}
	},
	moveRelative: function (delta) {
		var self = this,
			currentOffset;

		currentOffset = parseInt(self.$strip.css('marginLeft'), 10);

		self.$strip.css('marginLeft', currentOffset + delta);
	},
	goto: function (index, direction, isAnimated) {
		var self = this;

		if (typeof isAnimated === 'undefined') {
			isAnimated = true;
		}

		if (typeof index !== 'number') {
			throw 'Type mismatch: index NaN';
		}

		if (index < 0 || index >= self.slideCount) {
			throw 'Index out of range';
		}

		function findNearestSlidePosition() {
			var distanceForward = 0,
				distanceBackward = 0,
				found = false;

			while (!found) {
				if (self.displayMap[self.positionIndex + distanceForward] === index) {
					found = true;
				} else {
					distanceForward++;
				}

				// TODO: Remove when safe
				if (distanceForward > self.displayMap.length) {
					break;
				}
			}

			found = false;

			while (!found) {
				if (self.displayMap[self.positionIndex - distanceBackward] === index) {
					found = true;
				} else {
					distanceBackward++;
				}

				// TODO: Remove when safe
				if (distanceBackward > self.displayMap.length) {
					break;
				}
			}

			if (distanceForward <= distanceBackward) {
				return self.positionIndex + distanceForward;
			} else {
				return self.positionIndex - distanceBackward;
			}
		}

		function jumpIfNecessary() {
			if (direction === 'forward') {
				if (self.positionIndex + self.slidesVisible * 2 >= self.displayMap.length) {
					self.positionIndex -= self.slideCount;
					self.$strip.css({marginLeft: -1 * self.slideWidth * self.positionIndex});
				}
			} else if (direction === 'backward') {
				if (self.positionIndex - self.slidesVisible < self.slidesVisible) {
					self.positionIndex += self.slideCount;
					self.$strip.css({marginLeft: -1 * self.slideWidth * self.positionIndex});
				}
			}
		}

		function transition(targetIndex) {
			var targetMargin;

			function transitionEnd() {
				self.realIndex = index;
				self.positionIndex = targetIndex;
				self.isTransitioning = false;
				self.events.slideChange({index: self.realIndex});
			}

			targetMargin = -1 * self.$slides.eq(targetIndex).position().left + parseInt(self.$strip.css('marginLeft'), 10);

			if (self.options.cssTransitioned) {
				self.$strip.bind('webkitTransitionEnd MSTransitionEnd oTransitionEnd transitionend', function () {
					self.$strip.unbind('webkitTransitionEnd MSTransitionEnd oTransitionEnd transitionend');
					self.$strip.removeClass('animated');
					transitionEnd();
				});

				if (isAnimated) {
					self.$strip.addClass('animated');
				}

				self.$strip.css({marginLeft: targetMargin});

				if (!isAnimated) {
					transitionEnd();
				}
			} else {
				if (isAnimated) {
					self.$strip.animate({marginLeft: targetMargin}, 400, 'swing', function () {
						transitionEnd();
					});
				} else {
					self.$strip.css({marginLeft: targetMargin});
					transitionEnd();
				}
			}

			if (self.options.debug) {
				console.log('targetIndex: ', targetIndex, 'targetMargin: ', targetMargin);
			}
		}

		if (!self.isTransitioning) {
			self.isTransitioning = true;

			if (typeof direction === 'undefined') {
				if (self.options.infinite) {
					transition(findNearestSlidePosition());
				} else {
					transition(index);
				}
			} else if (direction === 'forward') {
				if (self.options.infinite) {
					jumpIfNecessary();
				}

				setTimeout(function () {
					transition(self.positionIndex + self.slidesVisible);
				}, 50);
			} else if (direction === 'backward') {
				if (self.options.infinite) {
					jumpIfNecessary();
				}

				setTimeout(function () {
					transition(self.positionIndex - self.slidesVisible);
				}, 50);
			}
		}
	},
	scale: function () {
		var self = this,
			width,
			oldVisibleClass,
			newVisibleClass,
			startSlidesNeeded,
			totalGutterWidth,
			gutterCount,
			slideWidthMinusGutter,
			minSingleGutterWidth,
			gutterRemainder,
			mutableGutterRemainder,
			minSlideWidth,
			slideRemainder,
			mutableSlideRemainder,
			debugSummed = 0,
			i,
			ii,
			j; // TODO : Make semantic

		self.width = self.$target.width();
		self.realIndex = 0;

		// TODO: This doesn't accomodate for out of order widths. Need to pre-sort.
		// Determine how many slides should be simultaenously visible for the current carousel width

		for (width in self.options.slideLayouts) {
			if (self.width >= parseInt(width, 10)) {
				self.slidesVisible = self.options.slideLayouts[width];
			}
		}

		// Calculate gutters

		totalGutterWidth = Math.floor(self.options.gutter * self.width);
		gutterCount = self.slidesVisible;
		minSingleGutterWidth = Math.floor(totalGutterWidth / gutterCount);
		gutterRemainder = totalGutterWidth % gutterCount;
		mutableGutterRemainder = gutterRemainder;

		// Calculate slide widths
		// The extra gutter that is added to the last item in the group is ignored

		self.slideWidth = (self.width - (totalGutterWidth - minSingleGutterWidth)) / self.slidesVisible;
		minSlideWidth = Math.floor(self.slideWidth);
		slideRemainder = (self.width - (totalGutterWidth - minSingleGutterWidth)) % self.slidesVisible;
		mutableSlideRemainder = slideRemainder;

		self.$slides.each(function (index) {
			// Use up any extra pixels by distributing them over the first few slides
			if (mutableSlideRemainder) {
				$(this).css({width: minSlideWidth + 1});
				mutableSlideRemainder--;
				debugSummed += (minSlideWidth + 1);
			} else {
				$(this).css({width: minSlideWidth});
				debugSummed += minSlideWidth;
			}

			// Use up any extra gutter by distributing it over the first few slides
			if (mutableGutterRemainder) {
				$(this).css({marginRight: minSingleGutterWidth + 1});
				mutableGutterRemainder--;
				debugSummed += (minSingleGutterWidth + 1);
			} else {
				$(this).css({marginRight: minSingleGutterWidth});

				if ((index + 1) % self.slidesVisible !== 0) {
					debugSummed += minSingleGutterWidth;
				}
			}

			// For the last slide in each group reset the remainders to deal with
			if ((index + 1) % self.slidesVisible === 0) {
				mutableSlideRemainder = slideRemainder;
				mutableGutterRemainder = gutterRemainder;

				if (self.options.debug) {
					console.log('self.width: ', self.width, 'debugSummed: ', debugSummed);
				}

				debugSummed = 0;
			}
		});

		if (self.options.infinite) {
			// Reset displayMap

			self.displayMap = [];

			for (i = 0, ii = self.slideCount; i < ii; i++) {
				self.displayMap.push(i);
			}

			// Remove and reset cloned slides

			self.$fakeStartGroup.remove();
			self.$fakeStartGroup = $();
			self.$fakeEndGroup.remove();
			self.$fakeEndGroup = $();

			// Create cloned end slides

			for (i = 0, ii = (self.slidesVisible * 2 - 1) - (self.slideCount % self.slidesVisible); i < ii; i++) {
				self.$fakeEndGroup = self.$fakeEndGroup.add(self.$slides.eq(i).clone());
				self.displayMap.push(i);
			}

			// Create cloned start slides

			startSlidesNeeded = self.slidesVisible + (self.slidesVisible - (self.slidesVisible - (self.slideCount % self.slidesVisible)));

			for (i = self.slideCount - 1, ii = self.slideCount - startSlidesNeeded; i >= ii; i--) {
				self.displayMap.unshift(i);
			}

			for (i = 0, ii = startSlidesNeeded; i < ii; i++) {
				self.$fakeStartGroup = self.$fakeStartGroup.add(self.$slides.eq(self.displayMap[i]).clone());
			}

			// Append cloned slides

			self.$strip.prepend(self.$fakeStartGroup);
			self.$strip.append(self.$fakeEndGroup);

			// Update tracked indices

			self.positionIndex = startSlidesNeeded;

			self.$strip.css({marginLeft: -1 * self.slideWidth * self.positionIndex});
		} else {
			self.positionIndex = 0;
			self.$strip.css({marginLeft: 0});
			self.events.scaled({});
		}

		// Set wrapper class to indicate number of visible items (Styling hook)

		oldVisibleClass = self.$target.attr('class').match(/visible-\d+/);
		newVisibleClass = 'visible-' + self.slidesVisible;

		if (oldVisibleClass !== null && oldVisibleClass[0] !== newVisibleClass) {
			self.$target.removeClass(oldVisibleClass[0]);
			self.$target.addClass(newVisibleClass);
		} else if (oldVisibleClass === null) {
			self.$target.addClass(newVisibleClass);
		}
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
