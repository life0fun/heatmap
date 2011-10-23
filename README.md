## to run:
1. redis-server
2. mongod --dbpath /data/
3. socketstream start

## where to put client lib js files ?

1. if you put client js in lib/client folder, it will get minified into
  `lib_xxxx.js` and loaded first. you screwed if the lib js has dependency.
  For example, can not put google map based lib js there as google map js needs 
  to be loaded first.

2. css files are stored in  `/lib/css/app.styl`
  For any resource refed, put them in `/public/images` folder and ref wiht `/images` prefix.
    background url("/images/bg.jpg")
    #header h1
	  text-align left

3. create overlay after window.onload done.
    window.onload = -> createHeatmap() bindEvent()

4. heatmap related global vars into window.heatmap object.
    window.heatmap = gmap: null, heatmap: null

5. client handles map click, call SS.server.app.updateHeatmap API.

6. client then listens to SS bcast by SS.events.on 'datapoint' (data) -> handle(data)

7. server side exposes updateHeatmap API and SS.publish.broadcast('datapoint', latlng)

## minify and Uglyfy
1. heatmap-gmaps.js has deps on gmap, which loaded at runtime from google. so it can not be pre-compiled and packed.
2. heatmap-lib.js is moved to lib/client/3.heatmap-lib.js and pre-compiled into public/asset/lib_xxx.js, disable the ref in app/views/app.jade
3. remember to clean public/asset/ folder after any modification.

## OverlayView To create your own overlay on top of Gmap
1. constructor, prototype inheritant `google.maps.OverlayView()`
    `HeatmapOverlay.prototype = new google.maps.OverlayView();`

2. stack the overlay into `map.getPanes()` inside `onAdd(), draw()`.
  Encapsulate the overlay into a div element, set width height, and stack into panes. 
    `map.getPanes().overlayLayer.appendChild(document.createElement('div'));`

3. recalculate overlay with overlay's `MapCanvasProjection` using `getProjection()`.
    var point = this.getProjection.fromLatLngToDivPixel(latlng))
	this.div_.left = point.x, ...

4. Draw heatmap on the overlay using canvas.getContext('2d').fillRect().
  Create a canvas inside overlay div with the same width height.

    var canvas = document.createElement("canvas")
	this.get("element").appendChild(canvas);
	this.set("actx", acanvas.getContext("2d"));

    rgr = ctx.createRadialGradient(x,y,r1,x,y,r2),
	ctx.fillStyle = rgr;
	ctx.fillRect(xb,yb,mul,mul);


## dataset preparation
1. raw data sit under public/data/loc.data, uses the script there to read data from csv file.
2. loc data got pump into mongo db for spatial indexing, as well as into Redis.
3. mongo db server configed at config/environments/development.coffee, refed as SS.config.db.mongo
4. mongo db schema configued at config/db.coffee, with db/col name, and db got opened.
5. mongo db opened and Db ref stored into global.M.
6. app/server/locationmdb is func mix-in as simple object with a collection of funcs.
7. app/server/streamnode is func mix-in as a full fledge obj with class and constructor.
8. 

## emit message
1. you need to extends EventEmitter in your class def to be able to emit msg.
2. prototype chain means it is sufficient just one upstream class inherits EventEmitter.
