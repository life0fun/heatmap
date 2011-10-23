# Server-side Code
querystring = require('querystring')

# simple function mix object, Vs. new locationmdb
locationmdb = require './locationmdb'

#
# expose all server side function thru exports.actions object
#
exports.actions =
	init: (cb) ->  # the init called by SS framework after conn established!
		@session.on 'disconnect', (session) ->  # this.session is internal field 
			if session?  # existent operator, true only not undefined and null
				#SS.publish.broadcast 'signedOut', session.user_id
				console.log 'user disconnected'
				session.user.logout ->   # invoke the function, == f()
	
		# put your customize init stuff here.
		R.zcard 'mapcenter', (err, card) ->
            if card <= 100
                console.log 'Bootstrapping heatmap data'
            else
                console.log 'compl keys:'+card

		#locationmdb.populateLocation 'locs', (err) -> console.log 'populate location done!'
		locationmdb.readLocDataPopRedis (err) -> console.log 'populate location done!'
		cb 'server done init!'

	publishLocation: (lat, lng) ->
		datapoint = {lat:lat, lng:lng}
		SS.publish.broadcast 'datapoint', datapoint
		console.log 'published location:' + lat + ' : ' + lng
			
	# event handler upon client mouse click, bcast to all clients!
	updateHeatmap: (args, callback) ->
		lat = args.lat
		lng = args.lng
		console.log 'client click with latlng: '+lat + ':' + lng
		@publishLocation lat, lng

		#locationmdb.findLocation lat,lng, 5  #unit of latlng+- 5
		callback 'broadcast success'

	testScope1: ->
		console.log ' => testScope 1...'
		@testScope2()
	testScope2: ->
		console.log ' => => test scope 2...'

	square: (number, cb) ->
		console.log('square'+number)
		cb(number*2)
	
	postfix: (req, res, cb) ->
		console.log req.body.lat
		console.log req.body.lng
