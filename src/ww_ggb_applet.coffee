exports.WwGgbApplet = class WwGgbApplet
  @instances = []
  @locked = false
  @$frame = null

  @lockAll: ->
    @locked = true
    instance.lock() for instance in @instances

  @unlockAll: -> @locked = false

  @recreateAll: ->
    instance.recreate() for instance in @instances
  
  constructor: (@elementId, @geogebraParams) ->
    console.log('GeogebraApplet3 depends on the jQuery library.') unless jQuery?

    # User inner element because of Geogebra's use of global id for its inject method.
    @innerId = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(2, 10)

    @geogebraParams.id ?= @elementId
    @geogebraParams.width ?= 400
    @geogebraParams.height ?= 400

    userOnLoad = @geogebraParams.appletOnLoad
    
    @geogebraParams.appletOnLoad = (applet) =>
      @applet = applet
      
      applet.registerUpdateListener(@geogebraParams.appletOnUpdate) if @geogebraParams.appletOnUpdate
      userOnLoad?(applet)

      @hideAllAnswers() if @geogebraParams.hideAnswers
      @lock() if WwGgbApplet.locked      

    WwGgbApplet.instances.push this
    @buildApplet()

  $element: -> jQuery(WwGgbApplet.$frame ? document).find("[id=#{@elementId}]")

  buildApplet: ->
    if GGBApplet?
      @buildLoaded()
    else
      jQuery.ajax
        url: 'https://cdn.geogebra.org/apps/deployggb.js'
        dataType: "script"
        cache: true
        success: => @buildLoaded()

  buildLoaded: ->
    @ggbApplet = new GGBApplet(@geogebraParams, true)

    console.log("Element not found") if not @$element().get(0)
    @$inner = jQuery("<div>").attr(id: @innerId).appendTo(@$element().empty().css(border: 'none', width: @geogebraParams.width, height: @geogebraParams.height))
    
    if document.readyState is 'complete'
      @ggbApplet.inject(@innerId)
      @$inner.css(width: @geogebraParams.width, height: @geogebraParams.height)
    else
      window.addEventListener "load", => @ggbApplet.inject(@innerId)
   
  setAnswer: (answerId, value) ->
    jQuery(WwGgbApplet.$frame ? document).find("##{answerId}").val(value).trigger('rapid-change')
        
  hideAnswer: (answerId) ->
    jQuery(WwGgbApplet.$frame ? document).find("##{answerId}").hide().addClass('hide-marks')
    jQuery(WwGgbApplet.$frame ? document).find("##{answerId} + .answer-mark").hide()
    jQuery(WwGgbApplet.$frame ? document).find$('.submit.button').removeClass 'disabled'

  hideAllAnswers: ->
    jQuery(WwGgbApplet.$frame ? document).find('[id^="AnSwEr"]').hide().addClass('hide-marks')
    jQuery(WwGgbApplet.$frame ? document).find('[id^="AnSwEr"] + .answer-mark').hide()    

  setCoordinates: (answerId, defaults) ->
    answers = jQuery(WwGgbApplet.$frame ? document).find("##{answerId}").val().split(';')
    answers.pop() # remove correctness

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

  lock: ->
    if @applet?
      for name in @applet.getAllObjectNames()
        @applet.setFixed(name, true)

  recreate: ->
    @buildApplet() unless @$inner? and not @$inner.is(':empty')
