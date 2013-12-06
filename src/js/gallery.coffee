FLD = '__tmp/'
URL = 'http://64815.selcdn.ru/' + FLD
THUMBS_OFF = true

abscureList = null

reqAPI = ->
  return $.ajax(
    url: (URL or './') + "?format=json"
    beforeSend: (xhr) ->
      xhr.setRequestHeader('X-Web-Mode', 'listing')
  ).done (files, err) ->
    models = files.filter (file) ->
      if (/^\./).test file.subdir
        return false
      if file.subdir
        return true
      if file.content_type
        return file.content_type.split('/')[0] is 'image'
      return false

    pathArr = document.location.pathname.split('/').filter (el) -> 
      el
    if pathArr.length > 1
      models.unshift({subdir: '../'})

    abscureList = new ItemCollectionView models

reqAPI '__tmp/'

########################################################################################

imgTpl = '<div class="photo loading"><div class="title"></div></div>'
fldTpl = '<div class="folder"><a href="" class="title"></a></div>'
lineBreakTpl = '<div class="linebreak"><div class="tit"></div><a href="#" class="goup"></a><div class="line"></div></div>'

$timeout = (fn, time, ctx, args) ->
  setTimeout (-> fn.apply(ctx, args)), time

class Tpl
  constructor: (tpl, binds) ->
    @$el = $(tpl)
    if binds
      @binds = {}
      for name, bind of binds
        @binds[name] = if typeof bind is 'function' then bind.call @$el else bind

  clone: (bindMap) ->
    $el = @$el
    if @binds and bindMap
      for name, bind of bindMap
        if bindPoint = @binds[name]
          bindPoint.call $el, bind
    return $el.clone()
  # set: (bindMap) ->

class FldView
  constructor: (@model) ->
    @$el = @template.clone subdir: @model.attrs.subdir
  template: new Tpl fldTpl,
    subdir: -> 
      title = this.find('.title')[0]
      (subdir) -> 
        title.innerText = subdir
        title.href = subdir.slice 0, -1

class ItemModel
  constructor: (@attrs) ->

  load: ->
    if !@__loadPromise
      dfd = new $.Deferred
      @__loadPromise = dfd.promise()
      @img = new Image
      @img.src = URL + @attrs.name
      @img.onload = dfd.resolve.bind dfd, @img.src
      @img.onerror = dfd.reject
    return @__loadPromise

class ImgView
  __thumbOnLoad: (src) =>
    @$el.css('background-image', 'url("' + src + '")') \
      .removeClass("loading")
      .addClass("loaded")

  __loadOriginal: =>
    @model.load().then @__thumbOnLoad

  template: new Tpl imgTpl, 
    name: -> 
      title = this.find('.title')[0]
      (name) -> title.innerText = name

  constructor: (@model) ->
    # @model = new ItemModel model
    name = @model.attrs.name
    @$el = @template.clone {name}
    @$el[0].onclick = abscureBox.show.bind abscureBox, @model

    if THUMBS_OFF
      @__loadOriginal()
    else
      @thumbImg = new Image
      @thumbImg.src = URL + '.thumbs/' + name
      @thumbImg.onload = __thumbOnLoad.bind this, @thumbImg.src
      @thumbImg.onerror = loadOriginal.bind this

class ItemCollection extends Array
  Model: ItemModel
  constructor: (models) ->
    @push.apply this, models.map (m) => new @Model m

  getNextPage: ->
    first = @page * @__itemsPerPage
    @page++
    @slice(first, first + @__itemsPerPage)

  page: 0
  __itemsPerPage: (->
    ratio = Math.floor($(window).width() / 312) 
    # if ratio > 2 then ratio else 3 )() * 4
    return ratio )() * 4

  getNext: (model) ->
    return @[@indexOf(model) + 1] || (@filter (model) -> model.attrs.name)[0]

  getPrev: (model) ->
    prevModel = @[@indexOf(model) - 1]
    return if (!prevModel or !prevModel.attrs.name) then @[@length - 1] else prevModel

class ItemCollectionView
  $el: $('.photo-list')
  tplLineBreak: new Tpl lineBreakTpl,
    page: -> 
      title = this.find('.tit')[0]
      (page) -> 
        title.innerText = page + 1
        title.id = page + 1

  constructor: (models) ->
    @collection = new ItemCollection models
    @renderCount()

    $('#lazy').appear().show()

    for i in [0..(Math.floor($(window).height()/312))]
      @needMore()

    $(document.body)
      .on('appear click', '#lazy', @needMore.bind this)
      .on('click', '.goup', -> $('body,html').scrollTop 0)

  appendChild: (model) ->
    view = if model.attrs.subdir then new FldView(model) else new ImgView(model)
    @$el.append(view.$el)

  needMore: ->
    page = @collection.page
    if (arr = @collection.getNextPage()).length
      if page
        @$el.append @tplLineBreak.clone {page}
      arr.forEach (model) => @appendChild(model)
      return @needMore
    $('#lazy').remove()

  renderCount: () ->
    lastDigit = @collection.length%10;
    twoLastDigits = @collection.length%100;
    $('.count').html(@collection.length + ' элемент' + (
        if twoLastDigits isnt 11 and lastDigit is 1 then '' else
          if twoLastDigits not in [12,13,14] and lastDigit in [2,3,4] then 'а' else 'ов'
      ))

abscureBox = new class AbcureBox
  events:
    'click .btn-close': 'hide'
    'click .btn-next': 'showNext'
    'click .btn-prev': 'showPrev'
    'click .btn-play': 'play'
    
  constructor: ->
    @$el = $('.light-box')
    $(window).on 'resize orientationchange', => 
      @calcContMetric()
    @$btnLoad = @$el.find('.btn-download')
    @$footer = @$el.find('.light-box-footer').on 'mouseenter', -> $(this).removeClass('hidden')
    @$imgCont = @$el.find('.light-box-image')
      .on 'transitionend', 'img.slide', (event) ->
        if !$(event.target).hasClass('current')
          $(this).remove()
      .on 'click', (event) -> 
        if event.target == this
          _this.hide()
      .bind('dragstart', -> false)
      # .bind('swipeleft', @showNext.bind this)
      .bind 'swipeleft', =>
        @showNext() unless @$img.movable
      .bind 'swiperight', =>
        @showPrev() unless @$img.movable
      .bind('swiperight swipeleft', => @$footer.addClass('hidden'))
      .click(=> @$footer.addClass('hidden'))

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
    @$img = $(@model.img)
    @$img.addClass 'loaded slide'
    @$imgCont.append @$img.show()

    @$img
      .bind('dblclick', (($el) ->
              stages = ['', 'stage1', 'stage2']
              now = 0
              return ->
                if document.body.offsetHeight > $el.height() and now is 0
                  now++
                $el.removeClass 'stage1 stage2'
                $el.addClass stages[++now] or stages[now = 0]
                $el.movin = now is 2
                abscureBox.calcContMetric()
                if now isnt 2
                  $el.unbind 'move'
                  if now is 1
                    $el.css
                      left: (if now isnt 0 then (document.body.offsetWidth - $el.width())/2 else 0)
                      top: (if now isnt 0 then (document.body.offsetHeight - $el.height())/2 else 0)
                    .movable = no
                else
                  $el.movable = yes
                  $el.bind('move', ( ($el) ->
                    left = (parseInt $el.css 'left') or 0
                    top = (parseInt $el.css 'top') or 0
                    return (e) -> 
                      return unless $el.movable
                      left += e.deltaX
                      top += e.deltaY
                      $el.css({left: left, top: top});
                  )($el))
            )(@$img))
      .bind('mousewheel', (($el) => 
              width = 0
              height = 0
              ratio = 0
              setTimeout ->
                width = $el.width()
                height = $el.height()
                ratio = height / width
              , 10
              return (e) =>
                e.preventDefault()
                $el.width(width += e.originalEvent.wheelDeltaY)
                $el.height(height += ratio * e.originalEvent.wheelDeltaY)
                @calcContMetric()
                return false
              )(@$img))
      .bind('movestart', => @$img.movin = yes)
      .bind('moveend', => @$img.movin = no)
      .bind 'swipeleft', =>
        @showNext() unless @$img.movable
      .bind 'swiperight', =>
        @showPrev() unless @$img.movable

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
    @$el.hide()
    @$img and @$img.hide().unbind()
    @model = null
    @stop() if @playing
    shareToggle false
    (=>
      setTimeout => 
        $('body,html').scrollTop(@bodyScroll)
      , 0
    )()

  calcContMetric: ->
    @contHeight = @$imgCont.innerHeight()
    @contWidth = @$imgCont.innerWidth()
    @align()

  align: ->
    if @$img.innerWidth() is 0 || @$img.innerWidth() is 0
      setTimeout (=> @align()), 10
    # if @contWidth > @$img.innerWidth()
    @$img.css('left', @contWidth/2 - @$img.innerWidth()/2)
    # else
    #   @$img.css('left', 0)
    # if @contHeight > @$img.innerHeight()
    @$img.css('top', @contHeight/2 - @$img.innerHeight()/2)
    # else
    #   @$img.css('top', 0)

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

fullscreen = (->
  fullscreened = false
  return ->
    if fullscreened = fullscreened
      el = document.body
      fullscreenMethod = el.requestFullScreen || el.webkitRequestFullScreen || el.mozRequestFullScreen || el.msRequestFullScreen
    else 
      el = document
      fullscreenMethod = el.exitFullScreen || el.webkitCancelFullScreen || el.mozCancelFullScreen || el.msCancelFullScreen
    fullscreenMethod.call(el)
)()

shareToggle = (-> 
  sharing = false 
  return (forceVisible = true) ->
    $btnShare = $('.btn-share');
    $el = $('.share')
    if !forceVisible
      $btnShare.removeClass('active')
      $el.hide()
      return !sharing = false
      
    $btnShare.toggleClass('active')
    $el.toggle();
    if !sharing != sharing
      url = encodeURI(document.location.origin + document.location.pathname.split('/').slice(0,-1).join('/') + '/' + @model.attrs.name)
      $('.dl').attr(href: @model.attrs.name)
      $('.fb').attr(href: 'http://share.yandex.ru/go.xml?service=facebook&url=' + url + '&title=Selectel Photo Gallery / ' + @model.attrs.name)
      $('.tw').attr(href: 'http://share.yandex.ru/go.xml?service=twitter&url=' + url + '&title=Selectel Photo Gallery / ' + @model.attrs.name)
      $('.gp').attr(href: 'http://share.yandex.ru/go.xml?service=gplus&url=' + url + '&title=Selectel Photo Gallery / ' + @model.attrs.name)
      $('.mail').attr(href: 'mailto:?subject=' + @model.attrs.name + '&body=' + url + '&title=Selectel Photo Gallery / ' + @model.attrs.name)
      $('.vk').attr(href: 'http://share.yandex.ru/go.xml?service=vkontakte&url=' + url + '&title=Selectel Photo Gallery / ' + @model.attrs.name)
    return false
)()

$('.btn-share').click shareToggle.bind abscureBox

