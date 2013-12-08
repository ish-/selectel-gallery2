class AbscureExplorator
  constructor: (img) ->
    if img.explorator
      img.explorator.setStage?(-1)
      return img.explorator.$img 

    @$img = $(img)
    @$img.explorator = this
    img.explorator = this

    @$img.bind 'dblclick', @getOnDblClick()
    @$img.bind 'movestart', => @movin = yes
    @$img.bind 'moveend', => @movin = no
    @$img.bind 'swipeleft', =>
    @$img.bind 'swiperight', =>

    @orient = @$img.width() > @$img.height()

    return @$img

  align: (@metric) ->
    return if metric.h is 0 || metric.w is 0
    if @$img.innerWidth() is 0 || @$img.innerHeight() is 0
      setTimeout (=> @align(metric)), 30
    @$img.css
      left: @left = metric.w/2 - @$img.innerWidth()/2
      top: @top = metric.h/2 - @$img.innerHeight()/2
    @contOrient = metric.w > metric.h

  getOnDblClick: ->
    stages = ['', 'stage1', 'stage2']
    @stage = 0
    return @setStage = (stage) =>
      @stage = stage if stage < 3
      @$img.removeClass 'stage1 stage2 stage1v'
      @$img.css width: 'auto', height: 'auto' if @sLeft
      @$img.addClass (stages[++@stage] or stages[@stage = 0]) + (if !@contOrient and !@orient and @stage is 1 then 'v' else '')
      if @stage is 1 and (document.body.offsetHeight > @$img.height() or document.body.offsetWidth > @$img.width())
        return @setStage.call this
      @movin = @stage is 2
      abscureBox.calcContMetric()
      if @stage isnt 2
        @$img.unbind 'move mousewheel'
        @movable = no
        if @stage is 1
          @$img.css
            left: (if @stage isnt 0 then (document.body.offsetWidth - @$img.width())/2 else 0)
            top: (if @stage isnt 0 then (document.body.offsetHeight - @$img.height())/2 else 0)
      else
        @movable = yes
        @$img.bind 'move', @getOnMove()
        @$img.bind 'mousewheel', @getOnMouseWheel()

  getOnMove: ->
    @mLeft =  0
    @mTop = 0
    return (e) => 
      return unless @movable
      @mLeft += e.deltaX
      @mTop += e.deltaY
      @$img.css left: @left + @mLeft + @sLeft, top: @top + @mTop + @sTop

  getOnMouseWheel: ->
    m = {}
    @sLeft = 0
    @sTop = 0
    setTimeout =>
      m.w = @$img.width()
      m.h = @$img.height()
      m.r = m.h / m.w
    , 30
    return (e) =>
      dy = e.originalEvent.wheelDeltaY
      e.preventDefault()
      return false if dy < 0 and (m.w < document.body.offsetWidth / 2 or m.h < document.body.offsetHeight / 2)
      @$img.css 
        width: m.w += dy
        height: m.h += m.r * dy
        left: @left + @mLeft + (@sLeft -= dy / 2)
        top: @top + @mTop + (@sTop -= m.r * dy / 2)
      # @calcContMetric()
      return false
