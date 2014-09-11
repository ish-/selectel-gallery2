class AbcureBox
  events:
    'click .btn-close': 'hide'
    'click .btn-next': 'showNext'
    'click .btn-prev': 'showPrev'
    'click .btn-play': 'play'
    
  constructor: ->
    that = this
    @$el = $('.light-box')
      .on 'mousewheel scroll', (e) -> !e.preventDefault()

    @$btnLoad = @$el.find('.btn-download')
    @$footer = @$el.find('.light-box-footer')
      .on 'mouseenter', -> $(this).removeClass('hidden')

    @$imgCont = @$el.find('.light-box-image')
      .on 'touchstart', (e) ->
        e.preventDefault()
      # .on 'transitionend', 'img.slide', (event) ->
      #   if !$(event.target).hasClass('current')
      #     $(this).remove()
      .bind 'dragstart', -> 
        false
      # .bind 'swipeleft', (e) =>
      #   @showNext() unless @$img.explorator.movable
      # .bind 'swiperight', =>
      #   @showPrev() unless @$img.explorator.movable
      # .bind 'swiperight swipeleft', (e) => 
      #   __swiped = yes
      #   @$footer.addClass('hidden')
      # .bind 'touchend', => 
      #   @$footer.addClass('hidden')
      .bind 'click', (e) -> 
        if e.target == this
          if that.explorator.transform.scale isnt 1
            that.explorator.onTap()

    $('body').on 'keydown', (event) =>
      if event.keyCode in [39,37,32]
        @hideFooter()
      switch event.keyCode
        when 39 then @showNext()
        when 37 then @showPrev()
        when 32 then @showNext()
        when 27 then @hide()
        when 13 then fullscreen() if event.altKey

    for key, fn of @events
      w = key.split /\s+/
      @$el.on w[0], w[1], @[fn].bind this

    App.on 'item:show', @show
    App.on 'item:show:sequence', @showNeighborModel
      

  hideFooter: ->
    @$footer.addClass('hidden')

  __initImg: ->
    @explorator = new AbscureExplorator @model.img
    @$img = @explorator.$img
    @$imgCont.append @$img.show()

    @$el.show().addClass 'show'
    setTimeout =>
      @$img.addClass 'loaded'
      @$img.addClass 'current'
    , 10


    @calcContMetric(@$img)
    @bodyScroll = $('body').scrollTop() || $('html').scrollTop()

  show: (@model, direction = true) =>
    if !model or !model.attrs.name then return false
    @$imgCont
      .removeClass 'loading'
      .find '.current'
      .removeClass 'current'
    @model.deferredShow = no
    model.load().then =>
      @$imgCont.removeClass 'loading'
      return false if @model isnt model or @model.deferredShow
      # App.trigger 'item:preload:' + (if direction then 'next' else 'prev'), @model
      # App.list.collection[if direction then 'getNext' else 'getPrev'](@model).load()
      $timeout ($img) ->
        if @$img isnt $img
          $img?.hide()
      , 200, this, [@$img]

      @__initImg()

    if @model.load().state() isnt 'resolved'
      $timeout (model) ->
          if @model is model
            @$imgCont.addClass 'loading'
      , 500, this, [model]

      # $timeout ->
      #   if @model is model
      #     return if @model.deferredShow++
      #     @$imgCont.removeClass 'loading'
      #     @__initImg()
      # , 3000, this, [model]

    @$el.show().addClass 'show'
    shareToggle false
  showNeighborModel: (dir) =>
    App.trigger 'item:show', App.list.collection.getNeighborModel @model, dir

  showNext: -> @showNeighborModel yes
  showPrev: -> @showNeighborModel no
  #   @$img and @$img.hide().unbind()
  #   @show App.list.collection.getNeighborModel @model, true
  #   # shareToggle false
  #   return false

  # showPrev: ->
  #   @$img and @$img.hide().unbind()
  #   @show App.list.collection.getNeighborModel @model, false
  #   # shareToggle false
  #   return false

  hide: =>
    @$el.removeClass 'show loading'
    setTimeout =>
      @$el.hide()
      @$img and @$img.hide()
      @model = null
    , 200
    @stop() if @playing
    shareToggle false
    setTimeout => 
      $('body,html').scrollTop(@bodyScroll)
    , 0
    App.trigger 'box:hide'
    @$footer.removeClass 'hidden'

  calcContMetric: =>
    @explorator.calc()

  setInterval: ->
    model = @model
    model.load().then =>
      setTimeout =>
        if @model isnt model
          return @setInterval()
        if @playing
          @showNext()
          @setInterval()
      , @timeout

  stop: ->
    @playing = false
    @$el.find('.btn-play').removeClass 'play'
    return false

  play: ->
    if @playing then return @stop() else @playing = true
    @$el.find('.btn-play').addClass 'play'
    @setInterval()
    return false

  wait: false
  timeout: 4000
  visible: false
  playing: false
  sharing: false
  bodyScroll: 0