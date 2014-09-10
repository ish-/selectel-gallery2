
bindAll = (obj) ->
  funcs = Array.prototype.slice.call arguments, 1
  funcs.forEach (f) -> obj[f] = obj[f].bind(obj)
  obj

`function debounce(a,b,c){var d;return function(){var e=this,f=arguments;clearTimeout(d),d=setTimeout(function(){d=null,c||a.apply(e,f)},b),c&&!d&&a.apply(e,f)}}`

log = console.log.bind console

########################################################################################

class Abscure
  # @HASH_PREFIX = '!/'
  constructor: ->
    for name, method of Events
      this[name] = method.bind @ee if typeof method is 'function'

    # @on 'all', log
  initialize: ->
    # document.body.addEventListener 'click', (e) ->
    #   el = e.target
    #   if el.tagName is 'A' and (href = el.getAttribute 'href')[0] = '#'
    #     if !(e.metaKey or e.altKey or e.ctrlKey or e.shiftKey)
    #       e.preventDefault()
    #     else
    #       e.stopImmediatePropagation()
    #     return false
    # , true


    @list = new ItemCollectionView()
    @box = new AbcureBox()

    if hash = (window.location.hash.match /^[#!\/]*([\w\W]*)$/)?[1]
      if page = (hash.match /^page-([\d]*$)/)?[1]
        @on 'collection:reset', =>
          while (Number page) > @list.collection.page  
            @list.needMore()
          setTimeout ->
            window.scroll 0, $('#page-' + page).offset().top
          , 50
      else
        model = new ItemModel name: hash
        @trigger 'item:show', model
        model.load().fail @box.hide
      console.log page

    @on 'item:show', (model) => @setHash model.attrs.name, model._index
    @on 'box:hide', => @setHash ''

    @$body = $(document.body)
      # .on 'click', 'a', (e) -> 
      #   if (href = e.currentTarget.getAttribute 'href')[0] is '#' and !e.metaKey and !e.ctrlKey and !e.altKey
      #     e.preventDefault()
      #     if href.length > 1
      #       e.stopImmediatePropagation()
      .on 'click', '.btn-share', shareToggle.bind @box
      .on 'click', '.btn-fullscreen', fullscreen
      .on 'appear click', '#lazy', @list.needMore
      # .on 'click', '.goup', -> $('body,html').scrollTop 0

    $(window)
      .on 'resize orientationchange', (debounce (@box.calcContMetric), 300) 
      .on 'popstate', (e) => 
        return true if !(state = window.history.state)
        if @lastTime > state.time
          @box.hide()
          # @lastTime = state.time
          window.location.hash = ''
        else if state.i?
          @trigger 'item:show', @list.collection[state.i]


  setHash: (str, i) ->
    return if !(str?) or ((state = window.history.state) and state.time? and state.time < @lastTime)
    setTimeout =>
      state = {time: @lastTime = Date.now()}
      state.i = i if i?
      window.history.replaceState state, null, '#' + str
    , 10

########################################################################################


imgTpl = '<a href="#" class="photo loading"><div class="title"></div></a>'
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
      title = this.find('.title')
      (subdir) -> 
        title.text subdir
        title.attr 'href', (subdir.slice 0, -1)
  remove: ->
    @$el.remove()

class ItemModel
  constructor: (@attrs) ->

  url: ->
    (@collection or App.list.collection).url()

  load: ->
    if !@__loadPromise
      dfd = new $.Deferred
      @__loadPromise = dfd.promise()
      @img = new Image
      @img.src = @url() + @attrs.name
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
      title = this.find('.title')
      (name) -> 
        title.text name
        this.attr 'href', '#' + name

  constructor: (@model) ->
    # @model = new ItemModel model
    name = @model.attrs.name
    @$el = @template.clone {name}
    @$el.on 'click', (e) => 
      if !(e.metaKey or e.altKey or e.ctrlKey or e.shiftKey)
        e.preventDefault()
        App.trigger 'item:show', @model
    # abscureBox.show.bind abscureBox, @model

    if THUMBS_OFF
      @__loadOriginal()
    else
      @thumbImg = new Image
      @thumbImg.src = @model.url() + '.thumbs/' + name
      @thumbImg.onload = @__thumbOnLoad.bind this, @thumbImg.src
      @thumbImg.onerror = @__loadOriginal.bind this

  remove: ->
    @$el.off()
    @$el.remove()

class ItemCollection extends Array
  Model: ItemModel
  constructor: (models) ->
    @page = 0
    @fetch()

    App.on 'item:show', =>
      (@getNeighborModel.apply this, arguments)?.load()

  reset: (models) ->
    @push.apply this, models.map (m, i) => 
      model = new @Model m
      model.collection = this
      model._index = i
      return model
    App.trigger 'collection:reset', this

  getNextPage: ->
    first = @page * @__itemsPerPage
    @page++
    @slice(first, first + @__itemsPerPage)

  url: ->
    HOST + FLD
  fetch: ->
    $loadingEl = $('.before-load')
      .addClass 'loading'
    return $.ajax(
      url: @url() + "?format=json"
      beforeSend: (xhr) ->
        xhr.setRequestHeader('X-Web-Mode', 'listing')
    ).done (files, err) =>
      models = files
        .filter (file) ->
          if (/^\./).test file.subdir
            return false
          if file.subdir
            return true
          if file.content_type
            return file.content_type.split('/')[0] is 'image'
          return false
        .map (file) ->
          file.modified = new Date file.last_modified
          return file
        .sort (a, b) ->
          if a.modified > b.modified or a.subdir then -1 else 1

      pathArr = document.location.pathname.split('/').filter (el) -> 
        el
      if pathArr.length > 1
        models.unshift({subdir: '../'})

      @reset models
      $loadingEl.removeClass 'loading'

  __itemsPerPage: (->
    ratio = Math.floor($(window).width() / 312) 
    # if ratio > 2 then ratio else 3 )() * 4
    return ratio )() * 4

  getNeighborModel: (model, dir = yes) =>
    model = @lastModel unless model?
    if dir
      return @lastModel = @[model._index + 1] or (@filter (model) -> model.attrs.name)[0]
    else
      prevModel = @[model._index - 1]
      return @lastModel = if (!prevModel or !prevModel.attrs.name) then @[@length - 1] else prevModel

  # getNext: (model) ->
  #   return @[@indexOf(model) + 1] || (@filter (model) -> model.attrs.name)[0]

  # getPrev: (model) ->
  #   prevModel = @[@indexOf(model) - 1]
  #   return if (!prevModel or !prevModel.attrs.name) then @[@length - 1] else prevModel

class ItemCollectionView
  $el: $('.photo-list')
  tplLineBreak: new Tpl lineBreakTpl,
    page: -> 
      title = this.find '.tit'
      anchor = this.find 'a'
      (page) -> 
        anchor.attr href: if page-1 then ('#page-' + page) else '#'
        title.text page + 1
        title.attr id: 'page-' + (page + 1)

  constructor: (models) ->
    @children = []
    @collection = new ItemCollection()
    
    App.on 'collection:reset', @render

  render: =>
    @collection.page = 0
    @empty()
    @renderCount()
    $('#lazy').appear().show()

    for i in [0..(Math.floor($(window).height()/312))]
      @needMore()

    

  appendChild: (model) =>
    view = if model.attrs.subdir then new FldView(model) else new ImgView(model)
    @children.push view
    @$el.append(view.$el)

  needMore: =>
    page = @collection.page
    if (arr = @collection.getNextPage()).length
      if page
        @$el.append @tplLineBreak.clone {page}
      arr.forEach @appendChild
      return @needMore
    $('#lazy').remove()

  renderCount: =>
    lastDigit = @collection.length%10;
    twoLastDigits = @collection.length%100;
    $('.count').html(@collection.length + ' элемент' + (
        if twoLastDigits isnt 11 and lastDigit is 1 then '' else
          if twoLastDigits not in [12,13,14] and lastDigit in [2,3,4] then 'а' else 'ов'
      ))

  empty: ->
    $('#lazy').hide()
    @children.forEach (child) ->
      child.remove()
    @$el.find '.linebreak'
      .remove()


fullscreen = (->
  fullscreened = false
  return ->
    if fullscreened = !fullscreened
      el = document.documentElement
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

$ ->
  (window.App = new Abscure)
    .initialize()
