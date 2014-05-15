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

VMW.matchHeights = {
    init: function () {
        // fn init
        var self = this,
            i,
            ii;

        // ELEMENTS

        self.matchGroups = []; // Contains all groups of elements to height match on window resize        

        // PROPERTIES

        // SETUP

        // EVENT DELEGATION
        if (typeof heightMatchables !== 'undefined') {
            for (i = 0, ii = heightMatchables.length; i < ii; i++) {
                self.matchGroups.push($(heightMatchables[i]));
            }

            self.runHeightMatches();
        }
    },
    heightMatch: function (collection) {
        var self = this,
            maxHeight = 0;

        collection.height('auto');

        collection.each(function () {
            if ($(this).height() > maxHeight) {
                maxHeight = $(this).height();
            }
        });

        collection.each(function (event) {
            $(this).height(maxHeight);
        });
    },
    runHeightMatches: function () {
        var self = this,
            i,
            ii;

        for (i = 0, ii = self.matchGroups.length; i < ii; i++) {
            self.heightMatch(self.matchGroups[i]);
        }
    }
};