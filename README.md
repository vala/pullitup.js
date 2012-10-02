# Pull it up !

PullItUp.js is a simple plugin that makes it simple for you to create scrollable animations in a web page
It allows you to specify the objects you want to be animated at some scroll position with a simple configuration hash
It's based on two coffeescript classes and wrapped in a jQuery plugin for ease of use.

It can leverage jQuery.easing plugin's methods for animations


## Usage

The basic idea is to configure 3 states of your animations :

* The `start` state
* The `fixed` state
* The `end` state

But you can avoid :

* The `fixed` state, if you want a linear trajectory
* The `end` state's position coordinates, if you want them to be the same as the `start` ones

You can pass both Number coordinates and position strings to the states' config hash :

* `start: { bounds: 0, x: 350, y: 0 }`
* `start: { bounds: 0, x: 'left', y: 'top inset' }`
* `start: { bounds: 0, x: 'center', y: 'bottom' }`

A real example will clarify things for you while I don't have time to write better doc !

## Example use :

With Coffeescript :

```coffeescript
$ ->
  $('#background').pullItUp
    start: { bounds: 0, x: 'left inset', y: 'top inset', fade: true, easeMove: true, easing: 'easeInOutQuad' },
    fixed: { bounds: [5500, 6500], x: 'left inset', y: 'bottom inset' }
    end: { bounds: 10000, x: 'right inset', y: 'bottom inset', easeMove: true, easing: 'easeOutSine' }
    onResize: ($el, w, h) ->
      $el.find('img').css
        width: w / 3
        height: h / 2
    alwaysVisible: true
```

With Javascript :

```javascript
$(function() {
  $('#background').pullItUp({
    start: { bounds: 0, x: 'left inset', y: 'top inset', fade: true, easeMove: true, easing: 'easeInOutQuad' },
    fixed: { bounds: [5500, 6500], x: 'left inset', y: 'bottom inset' },
    end: { bounds: 20000, x: 'right inset', y: 'bottom inset', easeMove: true, easing: 'easeOutSine' },
    onResize: function($el, w, h) {
      $el.find('img').css
        width: w / 3
        height: h / 2
    },
    alwaysVisible: true
});
```

## Work in progress

This library was designed for a specific project but with the goal of being adaptable to as many cases as posible.
Some more real world cases will make it better !

## Dependencies

PullItUp.js depends on jQuery only
jQuery.easing plugin can be used to specify other easing methods to the `start` and `end` transitions



