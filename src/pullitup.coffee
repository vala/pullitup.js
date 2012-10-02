# Be sure $ is what we want it to be
$ = jQuery

# Memoize window jQuery object
$window = $(window)

# The Pullitup class is the manager that will scroll
class Pullitup
  constructor: (@container) ->
    @items = []
    # Current scrollTop
    @last_scroll_top = @container.scrollTop()
    # TODO: Implement scaling
    @base_resolution =
      width: @container.width()
      height: @container.height()

    @scale = 1
    # Bind events
    @bindAll()
    @setScaleFromActualResolution()

  # Auxiliary method for initialization, binds events that we want to handle
  # in our Scroller class
  bindAll: ->
    @container.on 'scroll', =>
      scrollTop = @container.scrollTop()
      direction = if @last_scroll_top < scrollTop then 'down' else 'up'
      @processScrollAt(scrollTop, direction)
      @last_scroll_top = scrollTop
    # Yo
    @container.on 'resize', => @handleResize()

  # Subscribes an item to be animated and positioned by the Scroller
  # on scrollTop min or max reached
  # The options
  listen: (sel, opts) ->
    @items.push new ScrollableItem(
      sel, opts, @scale, @last_scroll_top, @sizes
    )

  # Propagates scroll to scrollable items
  processScrollAt: (y) ->
    $.each @items, (i, item) -> item.scrolledAt(y)

  # Handles $container's resizing and changes scale for children
  handleResize: ->
    @setScaleFromActualResolution()
    # Resize items
    $.each @items, (i, item) => item.resizeToScale @scale, @sizes
    # Simulate new scroll so every element's positions are refreshed
    @container.trigger('scroll')

  setBaseResolution: (res) ->
    @base_resolution = res
    @setScaleFromActualResolution()

  setScaleFromActualResolution: ->
    # Actual sizes and ratios
    [aw, ah] = [@container.width(), @container.height()]
    actual_ratio = aw / ah
    # Base ones
    [bw, bh] = [@base_resolution.width, @base_resolution.height]
    base_ratio = bw / bh

    # If width should be adapted
    if actual_ratio >= base_ratio
      width = aw
      height = bh * (aw / bw)
    # Else, height should be adapted
    else
      width = bw * (ah / bh)
      height = aw
    # Set scale from processed sizes
    @scale = width / bw

    @sizes =
      width: @base_resolution.width * @scale
      height: @base_resolution.height * @scale
      # Define offset to center items if screen width is greater than used width
      offset: Math.max(aw - width, 0) / 2



class ScrollableItem
  constructor: (sel, params, @scale, y, @parent_sizes) ->
    @el = $(sel)
    # Fade params
    @fadeIn = params.start.fade
    @fadeOut = params.end.fade
    # Ease on move ?
    @easeMoveIn = params.start.easeMove
    @easeMoveOut = params.end.easeMove
    # Check for defined easigns
    @inEasing = params.start.easing || 'linear'
    @outEasing = params.end.easing || 'linear'
    # Store params for later processing
    @params = params
    #
    @last_params = null

    # Get elements size before resizing
    @sizes =
      width: @el.width()
      height: @el.height()
    # Set base size of elements
    @resizeToScale(@scale, @parent_sizes)

    # Process positions from strings & others
    @processPositions()
    # Init position and set visibility
    @initPositionAt(y)

  # Recalculate position bounds
  processPositions: ->
    # Init with blank positions hash
    @positions = {}
    # Process each position params hash
    $.each @params, (key, hash) =>
      return if key == 'refObject' || key == 'onResize' || key == 'alwaysVisible'
      # Allow not to set :end positions if they're the same as :start ones
      # 0 ... false ...
      x = if key == 'end' && !hash.x && hash.x != 0 then @params['start'].x else hash.x
      y = if key == 'end' && !hash.y && hash.y != 0 then @params['start'].y else hash.y
      # Position hash calculation
      @positions[key] =
        # Process bounds
        bounds: if typeof hash.bounds == 'number' then @valueForPosition(hash.bounds)
        else $.map hash.bounds, (n) => @valueForPosition(n)
        # Coords when item position is @ key
        x: @valueForPosition(x) + @parent_sizes.offset
        y: @valueForPosition(y)

    # Allow not to set :fixed key, so we can create simple linear trajectories
    unless @positions.fixed
      bound = @positions.end.bounds -
        ((@positions.end.bounds - @positions.start.bounds) / 2)
      center = @positions.end.x - ((@positions.end.x - @positions.start.x) / 2)
      middle = @positions.end.y - ((@positions.end.y - @positions.start.y) / 2)
      @positions.fixed =
        bounds: [bound, bound]
        x: center
        y: middle

  initPositionAt: (y) ->
    # Store if item is visible
    @visible = @visibility(y)
    # Give good position
    if @visible is 0 then @el.fadeIn(0) else @el.fadeOut(0)
    # Set fixed position so we can move @el as we want to
    @el.css position: 'fixed'
    # Force trigger scroll method
    @scrolledAt y

  # Get value from parameter position
  # Allows us to pass string parameters in x and y options for each state
  valueForPosition: (n) ->
    if typeof n == 'number'
      n * @scale
    else
      # Extract position and maybe inset setting
      [pos, set] = n.split(' ')
      # Default to outset
      inset = set? && set == 'inset'
      position = switch pos
        when 'left'
          if inset then 0 else -@el.outerWidth()
        when 'right'
          ww = @parent_sizes.width
          if inset then ww - @el.outerWidth() else ww
        when 'top'
          if inset then 0 else -@el.outerHeight()
        when 'bottom'
          wh = @parent_sizes.height
          if inset then wh - @el.outerHeight() else wh
        when 'center' then (@parent_sizes.width - @el.outerWidth()) / 2
        when 'middle' then (@parent_sizes.height - @el.outerHeight()) / 2
      # Scale processed value
      position

  # ScrollHandler, fetch positions and call animation method depending on
  # item's current visibility
  scrolledAt: (y, force = false) ->
    visibility = @visibility(y)
    # Don't do anything if we are not in
    return if !visibility == 0 && !@visible && !force

    switch visibility
      when -1 then @animateTo(top: @positions.start.y, left: @positions.start.x, false)
      when 1 then @animateTo(top: @positions.end.y, left: @positions.end.x, false)
      when 0 then @animateTo(@getAnimationParamsAt(y), true)


  # Get item visibility for a given y
  #   * -1 if we're before animation start
  #   *  0 if we're should be animating item
  #   *  1 if we're after animation end
  visibility: (y) ->
    switch
      when y < @positions.start.bounds then -1
      when y > @positions.end.bounds then 1
      else 0

  # Animates item to position given by {top, left} hash and handles visiblity
  # change so the scroll handler is not called when not necessary
  animateTo: (params, visible) ->
    return if params == @last_params
    @last_params = params
    # Animate item to params
    @el.stop().animate(params, 0)
    # If visible state changed with this animation
    if visible != @visible
      @visible = visible
      if visible || @params.alwaysVisible
        @el.fadeIn(0)
      else
        @el.fadeOut(0)

  # Calculates coords to use for the current animation state
  # Handles easing based on options passed to the constructor leveraging
  # jQuery.easing available easing methods, so the position and opacity of
  # the element can be eased.
  getAnimationParamsAt: (y) ->
    if @params.refObject
      positions = @processPositionsFromRefObjectAt(y)
    else
      positions = @positions

    fixed_start = positions.fixed.bounds[0]
    fixed_end = positions.fixed.bounds[1]
    starts_at = positions.start.bounds
    ends_at = positions.end.bounds

    if y >= fixed_start && y <= fixed_end
      # If we must keep fixed state
      {
        top: positions.fixed.y # + y
        left: positions.fixed.x
        opacity: 1
      }
    else if y < fixed_start
      # If we're in start to fixed section
      ratio = (y - starts_at) / (fixed_start - starts_at)
      # Process top
      top_start = positions.start.y
      top = (ratio * positions.fixed.y - ratio * top_start) + top_start
      # Left
      left_start = positions.start.x
      left = (ratio * positions.fixed.x - ratio * left_start) + left_start

      if @easeMoveIn
        top = $.easing[@inEasing](top, ratio, top_start, top - top_start, 1)
        left = $.easing[@inEasing](left, ratio, left_start, left - left_start, 1)

      # Fade ratio processing
      if @fadeIn
        opacity =
          $.easing[@inEasing](ratio, ratio, 1, ratio, 1)
      # If we don't fade out, keep it to completely opaque
      else
        opacity = 1

      # Send animation params
      {
        top: top
        left: left
        opacity: if @fadeIn then ratio else 1
      }

    else
      # If we're in fixed to end section
      ratio = (y - fixed_end) / (ends_at - fixed_end)
      # Process top and left
      top_start = positions.fixed.y
      left_start = positions.fixed.x
      top = (ratio * positions.end.y - ratio * top_start) + top_start
      left = (ratio * positions.end.x - ratio * left_start) + left_start

      if @easeMoveOut
        top = $.easing[@outEasing](top, ratio, top_start, top - top_start, 1)
        left = $.easing[@outEasing](left, ratio, left_start, left - left_start, 1)

      # Fade ratio processing
      if @fadeOut
        opacity = 1 -
          (ratio * $.easing[@outEasing](1 - ratio, ratio, 1, 1 - ratio, 1))
      # If we don't fade out, keep it to completely opaque
      else
        opacity = 1

      # Send animation params
      {
        top: top # + y
        left: left
        opacity: opacity
      }

  # Scale item
  resizeToScale: (@scale, @parent_sizes) ->
    [w, h] = [@sizes.width * @scale, @sizes.height * @scale]
    # Callback before resizing
    @params.onResize(@el, w, h) if $.isFunction @params.onResize
    # Set element's css sizes
    @el.css
      width: w
      height: h
    # Process positionz
    @processPositions()

  processPositionsFromRefObjectAt: (y) ->
    offsets = @params.refObject.offset()
    positions = $.extend true, {}, @positions
    $.each @positions, (key, hash) =>
      positions[key].x = hash.x + offsets.left
      positions[key].y = hash.y - (y - offsets.top)
    positions

# jQuery plugin to simplify class usage
$.fn.pullItUp = (options, value = null, container = $window) ->
  is_setter = typeof options == 'string'

  # container = value if is_setter && value
  # Wrap container if necessary
  $container =
    if typeof container.jquery != 'undefined' then $(container) else container

  # Lookup for existing scroll handler for container or create new one
  pullup = $container.data('pullitup')
  unless pullup
    pullup = new Pullitup $container
    # Cache it
    $container.data('pullitup', pullup)


  if is_setter && typeof pullup[options] != 'undefined'
    pullup[options] value
  else
    this.each ->
      # Subscribe item to be scrolled
      pullup.listen this, options

