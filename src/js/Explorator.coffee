ticking = no

reqAnimationFrame = do ->
  window[Hammer.prefixed(window, 'requestAnimationFrame')] or (callback) ->
    window.setTimeout callback, 1000 / 60

class AbscureExplorator
  constructor: (img) ->
    if img.explorator
      @calc.call img.explorator
      return img.explorator.$img 
    @$img = $(img)
    @img = img
    @$img.explorator = this
    img.explorator = this

    # bindAll this, 'resetEnd', 'onPan', 'requestUpdate', 'align', 'updateTransform', 'resetStart', 'onTap', 'onPinch', 'onRotate'

    @calc()
    @h = new Hammer img

    @h.get('pinch').set({ enable: true });
    @h.get('rotate').set({ enable: true });

    @h.on 'tap', @onTap
    @h.on 'pan', @onPan
    @h.on 'pinch', @onPinch
    @h.on 'rotate', @onRotate
    @h.on 'panstart rotatestart pinchstart', @resetStart
    @h.on 'panend rotateend pinchend pancancel rotatecancel pinchcancel', @resetEnd

    # @$img.on 'mousewheel', (e) =>
    #   y = e.originalEvent.deltaY
    #   scale = Math.max 1, Math.min 10, @__transform.scale + y / 100
    #   if scale < 1.2
    #     @align()
    #   else
    #     @transform.scale = scale
    #   @updateTransform()

    @$img.addClass 'animate'
    return @$img

  calc: ->
    @ratio = (@originalWidth = @img.width) / (@originalHeight = @img.height);
    @align()

    @updateTransform()

  resetStart: (e) =>
    # abscureBox.hideFooter()
    @$img.removeClass 'animate'

  resetEnd: (e) =>
    @$img.addClass 'animate'
    if e
      if e.type in ['panend', 'pancancel']
        if @panDirection and Math.abs(e.velocity) > 0.82
          @img.style.opacity = 0
          if @panDirection is 1
            if e.velocityX > 0
              App.trigger 'item:show:sequence', yes
              # abscureBox.showNext()
            else
              App.trigger 'item:show:sequence', no
              # abscureBox.showPrev()
          else if @panDirection is 2
            App.box.hide()
        else if !@panned
            @__transform.translate.x = @transform.translate.x = @startX
            @__transform.translate.y = @transform.translate.y = @startY
            @img.style.opacity = 1
        else
          @__transform.translate.x = @transform.translate.x
          @__transform.translate.y = @transform.translate.y
          # @align no
        @panDirection = null
        return @pinched = no if @pinched

      else if e.type in ['pinchend', 'pinchcancel']
        # return @pinched = no if @pinched
        @pinched = yes
        @__transform.scale = @transform.scale

    @transform.rotate = 0
    @requestUpdate()

  onPinch: (e) =>
    scale = Math.max 1, Math.min 10, @__transform.scale * e.scale
    if scale < 1.2
      @align()
    else
      @transform.scale = scale
      @transform.translate.x = @__transform.translate.x + e.deltaX
      @transform.translate.y = @__transform.translate.y + e.deltaY
    @requestUpdate()

  onRotate: (e) =>
    @transform.rotate = e.rotation
    @requestUpdate()

  onPan: (e) =>
    return if @pinched
    if @transform.scale is 1 and !@reverse
      if !@panDirection and Math.abs(e.velocity) > .3
        @panDirection = if Math.abs(e.velocityX) > Math.abs(e.velocityY) then 1 else 2

      if @panDirection is 1
        @transform.translate.x = @__transform.translate.x + e.deltaX
        @img.style.opacity = window.innerWidth / Math.abs(e.deltaX) / 10
      else if @panDirection is 2
        @transform.translate.y = @__transform.translate.y + e.deltaY
        @img.style.opacity = window.innerHeight / Math.abs(e.deltaY) / 10
    else
      @transform.translate.x = @__transform.translate.x + e.deltaX
      @transform.translate.y = @__transform.translate.y + e.deltaY
      @panned = yes
    @requestUpdate()

  onTap: (e) =>
    @transform.scale = 1.2
    @requestUpdate()

    setTimeout =>
        # @transform.scale = @__transform.scale = 1;
        # @transform.translate.x = @__transform.translate.x = @startX;
        # @transform.translate.y = @__transform.translate.y = @startY;
        @align !@reverse and !@panned
        @requestUpdate();
    , 200

  requestUpdate: =>
    if !ticking
      ticking = yes
      reqAnimationFrame @updateTransform

  @TRANSFORM_ATTR = Hammer.prefixed(document.body.style, 'transform')

  updateTransform: =>
      value = [
        'translate3d(' + @transform.translate.x + 'px, ' + @transform.translate.y + 'px, 0)',
        'scale(' + (@transform.scale || 1) + ', ' + (@transform.scale || 1) + ')',
        'rotate(' + @transform.rotate + 'deg)'
      ]
      @img.style[AbscureExplorator.TRANSFORM_ATTR] = value.join ''
      ticking = no

  align: (reverse) => 
    @panned = no
    @img.style.opacity = 1
    @reverse = reverse if reverse?
    windowHeight = window.innerHeight
    windowWidth = window.innerWidth
    windowR = windowWidth / windowHeight
    imageHeight = 0
    imageWidth = 0
    if (d = @ratio > 1 and windowR < 1) or (@reverse and !d)
      @$img.css
        width: imageWidth = windowWidth
        height: imageHeight = windowWidth / @ratio
    else
      @$img.css
        width: imageWidth = @ratio * windowHeight
        height: imageHeight = windowHeight

    @__transform = 
      rotate: 0
      scale: 1
      translate:
        x: @startX = Math.round((windowWidth - imageWidth) / 2);
        y: @startY = Math.round((windowHeight - imageHeight) / 2);

    @transform =
      rotate: 0
      scale: 1
      translate:
        x: @startX
        y: @startY

  # constructor: (img) ->
  #   if img.explorator
  #     img.explorator.setStage?(-1)
  #     return img.explorator.$img 

  #   @$img = $(img)
  #   @$img.explorator = this
  #   img.explorator = this

  #   @$img.bind 'dblclick', onDblClick = @getOnDblClick()
  #   @$img.bind 'touchend', do =>
  #     lastTime = 0
  #     (e) =>
  #       if e.timeStamp - DBLTOUCH_TIMEOUT < lastTime
  #         onDblClick()
  #       lastTime = e.timeStamp
  #   @$img.bind 'movestart', => @movin = yes
  #   @$img.bind 'moveend', => @movin = no
  #   @$img.bind 'swipeleft', =>
  #   @$img.bind 'swiperight', =>

  #   @orient = @$img.width() > @$img.height()

  #   return @$img

  # align: (@metric) ->
  #   return if metric.h is 0 || metric.w is 0
  #   if @$img.innerWidth() is 0 || @$img.innerHeight() is 0
  #     setTimeout (=> @align(metric)), 30
  #   @$img.css
  #     left: @left = metric.w/2 - @$img.innerWidth()/2
  #     top: @top = metric.h/2 - @$img.innerHeight()/2
  #   @contOrient = metric.w > metric.h

  # getOnDblClick: ->
  #   stages = ['', 'stage1', 'stage2']
  #   @stage = 0
  #   return @setStage = (stage) =>
  #     @stage = stage if stage < 3
  #     @$img.removeClass 'stage1 stage2 stage1v'
  #     @$img.css width: 'auto', height: 'auto' if @sLeft
  #     @$img.addClass (stages[++@stage] or stages[@stage = 0]) + (if !@contOrient and !@orient and @stage is 1 then 'v' else '')
  #     if @stage is 1 and (document.body.offsetHeight > @$img.height() or document.body.offsetWidth > @$img.width())
  #       return @setStage.call this
  #     @movin = @stage is 2
  #     abscureBox.calcContMetric()
  #     if @stage isnt 2
  #       @$img.unbind 'move mousewheel'
  #       @movable = no
  #       if @stage is 1
  #         @$img.css
  #           left: (if @stage isnt 0 then (document.body.offsetWidth - @$img.width())/2 else 0)
  #           top: (if @stage isnt 0 then (document.body.offsetHeight - @$img.height())/2 else 0)
  #     else
  #       @movable = yes
  #       @$img.bind 'move', @getOnMove()
  #       @$img.bind 'mousewheel', @getOnMouseWheel()

  # getOnMove: ->
  #   @mLeft =  0
  #   @mTop = 0
  #   return (e) => 
  #     return unless @movable
  #     @mLeft += e.deltaX
  #     @mTop += e.deltaY
  #     @$img.css left: @left + @mLeft + @sLeft, top: @top + @mTop + @sTop

  # getOnMouseWheel: ->
  #   m = {}
  #   @sLeft = 0
  #   @sTop = 0
  #   setTimeout =>
  #     m.w = @$img.width()
  #     m.h = @$img.height()
  #     m.r = m.h / m.w
  #   , 30
  #   return (e) =>
  #     dy = e.originalEvent.wheelDeltaY
  #     e.preventDefault()
  #     return false if dy < 0 and (m.w < document.body.offsetWidth / 2 or m.h < document.body.offsetHeight / 2)
  #     @$img.css 
  #       width: m.w += dy
  #       height: m.h += m.r * dy
  #       left: @left + @mLeft + (@sLeft -= dy / 2)
  #       top: @top + @mTop + (@sTop -= m.r * dy / 2)
  #     # @calcContMetric()
  #     return false
