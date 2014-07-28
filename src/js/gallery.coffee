abscureList = null
PATH = ''

reqAPI = (fld) ->
  PATH = HOST + fld
  return $.ajax(
    url: HOST + fld + "?format=json"
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

reqAPI FLD or ''
########################################################################################

bindAll = (obj) ->
  funcs = Array.prototype.slice.call arguments, 1
  funcs.forEach (f) -> obj[f] = obj[f].bind(obj)
  obj

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
      @img.src = PATH + @attrs.name
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
      @thumbImg.onload = @__thumbOnLoad.bind this, @thumbImg.src
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

abscureBox = new AbcureBox

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

