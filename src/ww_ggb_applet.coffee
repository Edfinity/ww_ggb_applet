class WwGgbApplet
  #
  # internal methods
  #
  _instances = []
  _options = {}

  _buildInnerId = ->
    # Build inner element because of Geogebra's use of global id for its inject method.
    Math.random().toString(36).replace(/[^a-z]+/g, '').substr(2, 10)

  _buildResetButton = ($inner, params) ->
    $inner.after("<button class='btn btn-white my-3 reset-applet d-block'>#{params.resetButtonLabel}</button>")

  #
  # class methods
  #
  @configure: (options) ->
    if jQuery?
      jQuery.extend(_options,
        {
          onHideAnswer: jQuery.noop,
          onHideAnswers: jQuery.noop
        },
        options
      )

  @lock: ($container='body', lock=true) ->
    instance.lock(lock) for instance in @getInstances($container)

  @getInstances: ($container='body') ->
    $container = jQuery($container)
    containedInstances = []

    if $container.get(0)
      for instance in _instances
        containedInstances.push(instance) if jQuery.contains($container.get(0), instance.$container.get(0))
    containedInstances

  @getInstance: (element) ->
    element = $(element)
    _(_instances).find (instance) ->
      instance.$el.get(0) is element.get(0)

  #
  # instance methods
  #
  constructor: (elementId, @params) ->
    @locked = false
    @restoring = false
    @initialLoad = true
    @innerId = _buildInnerId()
    @elementId = "#{elementId}-#{@innerId}"
    @originalState = @params.ggbBase64 # save this for possible reset

    if jQuery?
      $el = jQuery("[id=#{elementId}]:last")

      if $el.get(0)?
        @$el = $el
        @$container = @params.container or $el.parent()
        @$container.addClass('edfinity-geogebra')

        @params = jQuery.extend(
          {},
          {
            id: @elementId,
            width: 400,
            height: 400,
            saveState: false,
            appletOnUpdate: $.noop,
            autoBuild: false,
            resetButton: false, resetButtonLabel: 'Reset'
          },
          @params
        )
        @params.resetButton = false unless @params.saveState

        @hideAnswers() if @params.hideAnswers

        @params.appletOnLoad = @onAppletLoad(@params.appletOnLoad)
        @build() if @params.autoBuild
        _instances.push this
      else
        console.log('Element not found')
    else
      console.log('WwGgbApplet depends on jQuery library.')

  build: ->
    @ggbApplet = new GGBApplet(@params, true)
    innerId = _buildInnerId()
    $inner = jQuery("<div>").attr(id: innerId)

    $inner.appendTo(@$el.empty().css(border: 'none', width: @params.width, height: @params.height))
    _buildResetButton(@$el, @params) if @params.resetButton

    if document.readyState is 'complete'
      @ggbApplet.inject(innerId)
      $inner.css(width: @params.width, height: @params.height)
    else
      window.addEventListener "load", => @ggbApplet.inject(innerId)

  answerEl: (answerId) ->
    @$container.find("##{answerId}")

  resetButton: ->
    @$container.find('.reset-applet')

  setAnswer: (answerId, value) ->
    $answerEl = @answerEl(answerId)
    if $answerEl.val() isnt value
      $answerEl.val(value)
      $answerEl.trigger 'rapid-change'
      @hideAnswer(answerId) if @params.hideAnswers

  getAnswer: (answerId) ->
    $answerEl = @answerEl(answerId)
    $answerEl.val()

  hideAnswer: (answerId) ->
    @answerEl(answerId).hide()
    _options.onHideAnswer(@$container, answerId)

  hideAnswers: ->
    @$container.find('[id^="AnSwEr"]').hide()
    _options.onHideAnswers(@$container)

  setCoordinates: (answerId, defaults) ->
    @hideAnswer(answerId) if @params.hideAnswers

    answerCoordinates = []
    answers = @answerEl(answerId).val().split(';')

    answers.pop() if answers.length > 2 # remove correctness
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
    @resetButton().toggleClass('d-block', not lock).toggleClass('d-none', lock)

  setState: (ggb64, callback) ->
    @restoring = true
    @applet.setBase64 ggb64, =>
      @restoring = false
      @hideBuggyControls()
      callback()

  delete: ->
    if @applet?
      @applet.unregisterUpdateListener(@onAppletUpdate)
      @applet.unregisterUpdateListener(@onAppletUpdateCallback)
    @$el.off 'focusout'
    @resetButton().off 'click'

    index = _instances.indexOf(this)
    if (index > -1)
      _instances.splice(index, 1)

  listenToElements: ->
    @$el.on('focusout', (e) => @onAppletFocusout(e)) if @params.saveState
    @resetButton().on('click', (e) => @onAppletReset(e))

  hideBuggyControls: ->
    # Remove occasional (timing-based) appearance of rogue sliders (seriously...)
    # https://help.geogebra.org/topic/versions-continuity-seems-broken-between-5-0-507-0-and-5-0-544-0-d-current
    @applet.setVisible 'Prism', false
    @applet.setVisible 'Pyramid', false
    @applet.setVisible 'Archimedean', false

  #
  # event handlers
  #
  onAppletUpdate: (obj) ->
    @$el.trigger 'applet-update', ggb: this, applet: @applet, obj: obj

  onAppletFocusout: ->
    @$el.trigger 'applet-focusout', ggb: this, applet: @applet

  onAppletReset: ->
    @setState @originalState, =>
      @$el.trigger 'applet-reset', ggb: this, applet: @applet

  onAppletLoad: (callback=$.noop) =>
    (applet) =>
      @applet = applet
      applet.registerUpdateListener(@onAppletUpdate.bind(this)) if @params.saveState
      @onAppletUpdateCallback = jQuery.proxy(@params.appletOnUpdate, this)
      applet.registerUpdateListener(@onAppletUpdateCallback)
      @listenToElements() if @initialLoad

      jQuery.proxy(callback, this)?(applet)
      @lock() if @locked
      @hideBuggyControls()
      @$el.trigger 'applet-load', ggb: this, applet: @applet, initialLoad: @initialLoad
      @initialLoad = false

window?.WwGgbApplet = WwGgbApplet
exports?.WwGgbApplet = WwGgbApplet
