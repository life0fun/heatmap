#
# Example of object with full constructor function with prototype chain
#
sys = require 'sys'
EventEmitter = require('events').EventEmitter
fs = require 'fs'
path = require 'path'
#_ = require 'underscore'

#
# top class inherits Event Emitter, prototype chain end at event emitter
#
class Node extends EventEmitter
	constructor: (@client) ->

#
# Prototype chain points to Node and cascade to event emitter
#
class StreamNode extends Node
	cls_priv_sect = 1		# class shared private static 
	@cls_pub_static = 2		# class static, pub

	constructor: (@client) ->
		instance_sect = 3   # instance privacy
		@bindEvent()
	
	# this is prototype
	bindEvent: ->
		console.log 'bindEvent...' + cls_priv_sect
		@on 'locdataready', (data) ->
			console.log 'locdataready :' + data.data

exports.StreamNode = StreamNode
