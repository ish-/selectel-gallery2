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
    $(window).on 'resize orientationchange', (debounce (@calcContMetric.bind this), 300) 
    @$btnLoad = @$el.find('.btn-download')
    @$footer = @$el.find('.light-box-footer').on 'mouseenter', -> $(this).removeClass('hidden')

    @$imgCont = @$el.find('.light-box-image')
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
          if that.$img[0].explorator.transform.scale isnt 1
            return that.$img[0].explorator.onTap()
          that.hide()

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

  hideFooter: ->
    @$footer.addClass('hidden')

  __initImg: ->
    @$imgCont
      .find('.current')
      .removeClass('current')
    @$img = new AbscureExplorator @model.img
    @$imgCont.append @$img.show()

    @$el.show().addClass 'show'
    setTimeout =>
      @$img.addClass 'loaded'
      @$img.addClass 'current'
    , 10


    @calcContMetric(@$img)
    @bodyScroll = $('body').scrollTop() || $('html').scrollTop()
    # abscureList.$el.hide()

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

      # $timeout ->
      #   if @model is model
      #     return if @model.deferredShow++
      #     @$imgCont.removeClass 'loading'
      #     @__initImg()
      # , 3000, this, [model]

    @$el.show().addClass 'show'
    # abscureList.$el.hide()

  showNext: ->
    @$img and @$img.hide().unbind()
    @show abscureList.collection.getNext(@model), true
    # shareToggle false
    return false

  showPrev: ->
    @$img and @$img.hide().unbind()
    @show abscureList.collection.getPrev(@model), false
    # shareToggle false
    return false

  hide: ->
    abscureList.$el.show()
    @$el.removeClass 'show loading'
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

  calcContMetric: =>
    @$img?[0].explorator.calc()

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