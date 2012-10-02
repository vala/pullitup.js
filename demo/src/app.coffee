$ ->

  $body = $('body')

  $(window).pullItUp 'setBaseResolution', width: 1600, height: 1000

  $('#background').pullItUp
    start: { bounds: 0, x: 'left inset', y: 'top inset' },
    fixed: { bounds: [5500, 6500], x: 'left inset', y: 'bottom inset' }
    end: { bounds: 20000, x: 'right inset', y: 'bottom inset' }
    onResize: ($el, w, h) ->
      $el.find('img').css
        width: w / 3
        height: h / 2
    alwaysVisible: true

  $('#camtar').pullItUp
    start: { bounds: 7000, x: 1675, y: 660 }
    end: { bounds: 11000, x: 710, y: 680 }
    refObject: $('#fond2')
