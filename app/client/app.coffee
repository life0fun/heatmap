#
# Client-side Code

window.heatmap =
	gmap: null
	canvas: null
	heatmap: null
	timer: null
	repeatcnt: 0
	lastlat: null
	lastlng: null

SS.socket.on 'disconnect', ->  $('#message').text('SocketStream server is down :-(')
SS.socket.on 'connect', ->     $('#message').text('SocketStream server is up :-)')

window.onload = ->
	console.log 'window onload done..., create gmap'
	createHeatmap()
	bindEvent()

# This method is called automatically when the websocket connection is established. 
# Do not rename/delete
exports.init = ->
    # Make a call to the server to check whether server inited properly
	SS.server.app.init (response) ->
		#$('#message').text(response)
        console.log response

# called after window.onload done so all scripts are loaded.
createHeatmap = ->
	console.log 'creating gmap....'
	#mylat = new google.maps.LatLng(41.884411,-87.625984)
	mylat = new google.maps.LatLng(42.004411,-87.995984)
	myOptions = {
		zoom: 12,
		center: mylat,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	}
	heatmap.gmap = new google.maps.Map(document.getElementById("map_canvas"), myOptions)
	width = window.innerWidth
	height = window.innerHeight
	heatmap.heatmap = new HeatmapOverlay(heatmap.gmap, {"radius":15, "visible":true, "opacity":60})
	console.log 'heatmap overlay created...'

# 
# top level bind event to set up all View event callbacks
bindEvent = ->
	google.maps.event.addListener heatmap.gmap, 'click', (event) ->
		console.log 'heatmap clicked : ' + event.latLng
		args = {}
		args.lat = event.latLng.lat()
		args.lng = event.latLng.lng()
		#SS.server.app.updateHeatmap args, (result) ->

	console.log 'done bindEvent for gmaps...'

# handle server broadcast datapoint msg, args contains only lat/lng
SS.events.on 'datapoint', (data) ->
	if not heatmap.lastlat?
		mapPanTo data.lat, data.lng

	heatmap.lastlat = data.lat
	heatmap.lastlng = data.lng
	heatmap.repeatcnt = 0
	#addDataPoint data.lat, data.lng, Math.floor(Math.random()*100) # count is random in 100
	addDataPoint data.lat, data.lng, 1
        
mapPanTo = (lat, lng) ->
	latlng = new google.maps.LatLng lat, lng
	#heatmap.gmap.panTo latlng
	heatmap.gmap.setCenter latlng

addDataPoint = (lat, lng, cnt) ->
	console.log 'heatmap addDataPoint:' + lat + ':' + lng + ':' + cnt
	heatmap.heatmap.addDataPoint lat, lng, cnt
	#mapPanTo lat, lng
	setRepeatTimer()

fakeDataPoint = ->
	if heatmap.repeatcnt > Number.MAX_VALUE
		clearRepeatTimer()
	else
		heatmap.repeatcnt += 1
		console.log 'periodic fake data point...:' + heatmap.repeatcnt
		addDataPoint heatmap.lastlat, heatmap.lastlng, heatmap.repeatcnt

fadeOut = ->
	console.log 'fading out....'
	heatmap.heatmap.fadeOut()

clearRepeatTimer = ->
	if heatmap.timer?
		clearInterval heatmap.timer
		heatmap.timer = null
		heatmap.repeatcnt = 0

setRepeatTimer = ->
	if not heatmap.timer?
		clearRepeatTimer()
		heatmap.timer = setInterval fadeOut, 2000
		console.log 'setInterval for fadeOut every...5000'

