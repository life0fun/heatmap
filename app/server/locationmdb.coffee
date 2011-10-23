#
# this file contains location related methods. The methods interact with Mongodb
# locs collection that is GeoIndexed.
#
sys = require 'sys'
EventEmitter = require('events').EventEmitter
fs = require 'fs'
path = require 'path'
#_ = require 'underscore'

StreamNode = require('./streamnode').StreamNode

LOCCOL = ''  # location collection name
LOCFILE = path.join(__dirname, '../../public/data/loc.data')
LocData = []
LOCDATAKEY = 'locdatakey'  # redis list of loc 

LiveTimer = null

DBPARAM = do ->
	colname = 'locs'
	setColName: (name)->
		colname = name

# mixin as full fledged function with class constructor
stream = new StreamNode('mdb')

# mixin as object with collection of functions..
# mixin as function, locationmdb = -> @readLocData = -> ...
# read location data from txt file
exports.readLocData = (col, file) ->
	fs.readFile file, (err, data) =>
		throw err if err
		content = data.toString()
		lines = content.split '\n'
		for l in lines
			if l.length == 0
				continue
			@storeData col, l   # called from cb, so cb needs to use fat arrow.
		@setLiveTimer -> # start location stream timer

exports.storeData = (col, l) ->
	col.insert JSON.parse(l), (err, docs) -> console.log 'added location:'+docs
	latlng = JSON.parse(l).loc
	console.log 'storeData ->' + latlng + ' lat:'+latlng[0] + ':'+latlng[1]
	R.lpush LOCDATAKEY, JSON.stringify(latlng), (err, status) ->   # 8) "42.289383,-88.001001"
	LocData.push latlng
	console.log 'LocData:' + LocData[LocData.length-1][0] + LocData[LocData.length-1][1]

''' just read data from log and pump into R'''
exports.readLocDataPopRedis = (cb) ->
	fs.readFile LOCFILE, (err, data) =>   # need closure so to ref set live timer
		throw err if err
		content = data.toString()
		lines = content.split '\n'
		for l in lines
			if l.length == 0
				continue
			latlng = JSON.parse(l).loc
			R.lpush LOCDATAKEY, JSON.stringify(latlng), (err, status) ->
			LocData.push latlng
			console.log 'LocData:' + LocData[LocData.length-1][0] + LocData[LocData.length-1][1]

		R.lindex LOCDATAKEY, 2, (err, data) ->
			console.log 'R lindex:' + JSON.parse(data)
		@setLiveTimer -> # start stream timer
		stream.emit('locdataready', {data:'ready'})

''' when doc read out from db, already json'''
exports.readCollection = (err, col) =>
	col.find().each (err, doc) ->
		return if not doc?
		latlng = doc.loc
		console.log 'readCollection ->' + latlng + ' lat:'+latlng[0] + ':'+latlng[1]
		R.lpush LOCDATAKEY, JSON.stringify(latlng), (err,status) ->
			console.log 'inserted to Redis:' + latlng # 8) "42.289383,-88.001001"
		LocData.push latlng

''' redis is in-memory, volatile after restart '''
exports.fetchData = ->
	R.lrange LOCDATAKEY, 0, -1, (err, docs) ->
		for loc in docs
			LocData.push loc.split(',')
			console.log 'LocData:' + LocData[LocData.length-1][0] + ':' + LocData[LocData.length-1][1]
	if not LocData.length
		M.collection LOCCOL, @readCollection

''' populate location collection if does not exist '''
exports.populateLocation = (colname, cb) ->
	console.log 'populateLocations : ' + colname
	LOCCOL = colname
	M.collectionNames colname, (err, l) =>  #list of collection names as db.col
		console.log 'colletion exists:' + col.name for col in l #[{ name: 'location.locs' }]
		if not l.length
			M.collection colname, @addLocation  # now context is down to when cb invoked.
		else if not LocData.length
			@fetchData()
			console.log 'collection exist start timer'
		@setLiveTimer -> # start stream timer
		stream.emit('locdataready', {data:'ready'})

# add location data into collection, col obj returned from colname map.
exports.addLocation = (err, col) =>
	#col.insert {loc:[42.005753, -88.102734]},(err,docs) -> console.log 'added:'+docs
	#col.insert {loc:[42.296108, -88.003106]},(err,docs) -> console.log 'added:'+docs
	#col.insert {loc:[42.300405, -87.999999]},(err,docs) -> console.log 'added:'+docs
	@readLocData col, LOCFILE
	@indexLocation col, 'loc'

# index the col, col is the result of M.collection colname
exports.indexLocation = (col, field) ->
	console.log 'indexLocation...'
	locd = {}
	locd[field] = '2d'  # need 2d indexing
	col.ensureIndex locd, (err, result) -> console.log 'ensureIndex:' + result

# find locations nearby, the unit of maxdistance, the same unit as your data unit.(lat/lng deg)
# http://stackoverflow.com/questions/5319988/how-is-maxdistance-measured-in-mongodb
exports.findLocation = (lat, lng, radius) ->
	console.log 'findLocation: ' + lat + ',' + lng
	# fetch the collection by name, new collection returned in callback
	M.collection LOCCOL, (err, collection) ->  # new collection returned
		#collection.find {loc:{$near:[42.3,-88.0], $maxDistance: 10}}, (err, cursor) ->
		collection.find {loc:{$near:[lat,lng], $maxDistance: radius}}, (err, cursor) =>
			cursor.each (err, doc) =>
				console.log 'findLocation Nearby:' + doc if doc?
				if doc?
					SS.server.app.publishLocation doc.loc[0], doc.loc[1]

exports.clearLiveTimer = ->
	if LiveTimer?
		clearInterval LiveTimer
		LiveTimer = null

exports.setLiveTimer = ->
	if not LiveTimer?
		offset = 0
		streamLoc = do (offset) ->
			''' need to return a callback which close the passed in loop index '''
			->
				start = offset
				end = if offset+20 >= LocData.length then LocData.length-1 else offset+20
				SS.server.app.publishLocation LocData[idx][0], LocData[idx][1] for idx in [start..end]  # inclusive of both ends
				console.log 'streamLoc: offset='+offset + ' :' + LocData[offset][0]
				offset = (end + 1) % LocData.length

		LiveTimer = setInterval streamLoc, 1000
		console.log 'setLiveTimer for every 1000...'
