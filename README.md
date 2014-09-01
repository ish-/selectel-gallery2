# [Selectel][] [storage][] image gallery 2 [![Build Status][travis-img]][travis]

[travis]: http://travis-ci.org/selectel/photo-gallery
[travis-img]: https://travis-ci.org/selectel/photo-gallery.png

Features:

v2
- multitouch
- resize
- click to resize to opposite bounds
  - then you are able to drag

(cause original large images make lags and load too long):
- increased. distance for lazy load trigger 
- changed. logic of image displaying (on review even before loaded. not to force to delay user)
- researched. css and applied tricks for heavy rendering places

v1
- swipes
- lazy load
- slideshow
- key control
- unintrusive panel
- sharing
- folders
- optional thumbs ('./.thumbs')
- responsive & adaptive

## Build

```
npm install

grunt build:access
grunt build:gallery
```

[Selectel]: http://selectel.com
[storage]: http://storage.selectel.ru/
