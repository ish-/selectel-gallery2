# [Selectel][] [storage][] image gallery 2 [![Build Status][travis-img]][travis]

[travis]: http://travis-ci.org/selectel/photo-gallery
[travis-img]: https://travis-ci.org/selectel/photo-gallery.png

Features:

v2
- switching 3 types of image review with a double click
 - fit
 - fill + crop (maybe ommited)
 - real size with drag and scaling with scroll

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

/dist/*.html are results files with all resources.
Node.js >= 0.8 required

[Selectel]: http://selectel.com
[storage]: http://storage.selectel.ru/
