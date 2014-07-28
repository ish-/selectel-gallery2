class AbcureBox
  events:
    'click .btn-close': 'hide'
    'click .btn-next': 'showNext'
    'click .btn-prev': 'showPrev'
    'click .btn-play': 'play'
    
  constructor: ->
    that = this
    @$el = $('.light-box')
    $(window).on 'resize orientationchange', => 
      @calcContMetric()
    @$btnLoad = @$el.find('.btn-download')
    @$footer = @$el.find('.light-box-footer').on 'mouseenter', -> $(this).removeClass('hidden')

    __swiped = no
    @$imgCont = @$el.find('.light-box-image')
      .on 'transitionend', 'img.slide', (event) ->
        if !$(event.target).hasClass('current')
          $(this).remove()
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
        return __swiped = no if __swiped
        if e.target == this
          that.hide()

    $('body').on 'keydown', (event) =>
      if event.keyCode in [39,37,32]
        @$footer.addClass('hidden')
      switch event.keyCode
        when 39 then @showNext()
        when 37 then @showPrev()
        when 32 then @showNext()
        when 27 then @hide()
        when 13 then @fullscreen(event) if event.altKey

    $('.btn-fullscreen').click fullscreen

    for key, fn of @events
      w = key.split /\s+/
      @$el.on w[0], w[1], @[fn].bind this

  __initImg: ->
    @$imgCont
      .find('.current')
      .removeClass('current')
    @$img = new AbscureExplorator @model.img
    @$img.addClass 'loaded'
    @$imgCont.append @$img.show()

    setTimeout =>
      @$img.addClass 'current'
    , 10

    @$el.show().addClass 'show'

    @calcContMetric(@$img)
    @bodyScroll = $('body').scrollTop() || $('html').scrollTop()
    abscureList.$el.hide()

  show: (@model, direction = true) ->
    if !model or !model.attrs.name then return false
    @$imgCont.removeClass 'loading'
    @model.deferredShow = no
    model.load().then =>
      @$imgCont.removeClass 'loading'
      return false if @model isnt model or @model.deferredShow
      abscureList.collection[if direction then 'getNext' else 'getPrev'](@model).load()
      @__initImg()

    if @model.load().state() isnt 'resolved'
      $timeout ->
          if @model is model
            @$imgCont.addClass 'loading'
      , 500, this, [model]

      $timeout ->
        if @model is model
          return if @model.deferredShow++
          @__initImg()
      , 3000, this, [model]

    @$el.show().addClass 'show'
    abscureList.$el.hide()

  showNext: ->
    return if @$img.movin
    @$img and @$img.hide().unbind()
    @show abscureList.collection.getNext(@model), true
    # shareToggle false
    return false

  showPrev: ->
    return if @$img.movin
    @$img and @$img.hide().unbind()
    @show abscureList.collection.getPrev(@model), false
    # shareToggle false
    return false

  hide: ->
    abscureList.$el.show()
    @$el.removeClass 'show'
    setTimeout =>
      @$el.hide()
      @$img and @$img.hide()
      @model = null
    , 200
    @stop() if @playing
    shareToggle false
    (=>
      setTimeout => 
        $('body,html').scrollTop(@bodyScroll)
      , 0
    )()

  calcContMetric: ->
    # @$img?[0].explorator.align h: @$imgCont.innerHeight(), w: @$imgCont.innerWidth()

  setInterval: ->
    setTimeout =>
      if @playing
        @showNext()
        @setInterval()
    , @timeout

  stop: ->
    @playing = false
    @$el.find('.btn-play span').attr(class: 'icon-play')
    return false

  play: ->
    if @playing then return @stop() else @playing = true
    @$el.find('.btn-play span').attr(class: 'icon-pause')
    @setInterval()
    return false

  wait: false
  timeout: 4000
  visible: false
  playing: false
  sharing: false
  bodyScroll: 0