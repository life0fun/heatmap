#!/usr/bin/env coffee

fs = require 'fs'
fspath = require 'path'
sys = require 'sys'
Buffer = require('buffer').Buffer


readFile = (file) ->
	fs.readFile file, (err, data) ->
		throw err if err
		i = 0
		content = data.toString()
		lines = content.split('\n')
		console.log ++i+'=> '+l for l in lines

readFile './loc.data'

