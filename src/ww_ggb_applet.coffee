class WwGgbApplet
  _instances = []
  _options = {}

  _buildInnerId = ->
    # Build inner element because of Geogebra's use of global id for its inject method.
    Math.random().toString(36).replace(/[^a-z]+/g, '').substr(2, 10)

  _buildApplet = ($element, params) ->
    applet = new GGBApplet(params, true)
    innerId = _buildInnerId()
    inner = jQuery("<div>").attr(id: innerId).appendTo($element.empty().css(border: 'none', width: params.width, height: params.height))

    if document.readyState is 'complete'
      applet.inject(innerId)
      inner.css(width: params.width, height: params.height)
    else
      window.addEventListener "load", => applet.inject(innerId)

  @configure: (options) ->
    jQuery.extend(_options, {onHideAnswer: jQuery.noop, onHideAnswers: jQuery.noop}, options) if jQuery?

  @lock: ($container='body', lock=true) ->
    instance.lock(lock) for instance in @getInstances($container)

  @getInstances: ($container='body') ->
    $container = jQuery($container)
    containedInstances = []

    if $container.get(0)
      for instance in _instances
        containedInstances.push(instance) if jQuery.contains($container.get(0), instance.$container.get(0))
    containedInstances

  constructor: (@elementId, @geogebraParams) ->
    @locked = false

    if jQuery?
      $el = jQuery("[id=#{@elementId}]:last")
      if $el.get(0)?
        @$container = $el.parent()
        @geogebraParams = jQuery.extend({}, {id: @elementId, width: 400, height: 400}, @geogebraParams)

        userOnLoad = @geogebraParams.appletOnLoad
        @geogebraParams.appletOnLoad = (applet) =>
          @applet = applet
          applet.registerUpdateListener(jQuery.proxy(@geogebraParams.appletOnUpdate, this)) if @geogebraParams.appletOnUpdate
          jQuery.proxy(userOnLoad, this)?(applet)
          @hideAnswers() if @geogebraParams.hideAnswers
          @lock() if @locked

        @ggbApplet = _buildApplet($el, @geogebraParams)
        _instances.push this
      else
        console.log("Element not found")
    else
      console.log('GeogebraApplet3 depends on the jQuery library.')

  setAnswer: (answerId, value) ->
    @$container.find("##{answerId}").val(value).trigger('rapid-change')

  hideAnswer: (answerId) ->
    @$container.find("##{answerId}").hide()
    _options.onHideAnswer(@$container, answerId)

  hideAnswers: ->
    @$container.find('[id^="AnSwEr"]').hide()
    _options.onHideAnswers(@$container)

  setCoordinates: (answerId, defaults) ->
    answers = @$container.find("##{answerId}").val().split(';')
    answers.pop() if answers.length > 2 # remove correctness

    answerCoordinates = []
    for answer in answers
      values = answer.split('=')
      answerCoordinates[values[0]] = values[1]

    for objectName, coord of defaults
      @applet.evalCommand("#{objectName} = #{answerCoordinates[objectName] ? coord}")

  setCoordinateAnswer: (answerId, keys, answerKey) ->
    value = []

    for key in keys
      value.push "#{key}=(#{@applet.getXcoord(key)}, #{@applet.getYcoord(key)})"

    value.push @applet.getValue(answerKey); # should return 0 or 1
    @setAnswer answerId, value.join(';')

  lock: (lock=true) ->
    @locked = lock
    if @applet?
      for name in @applet.getAllObjectNames()
        @applet.setFixed(name, lock)

window?.WwGgbApplet = WwGgbApplet
exports?.WwGgbApplet = WwGgbApplet
