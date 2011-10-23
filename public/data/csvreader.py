#!/usr/bin/env python

import csv
import re, sys
import exceptions
import json
import pdb

class LocDataReader:
    # do we have any class variable ?

    def __init__(self, filename=None):
        self.filename = filename

    def getData(self, file):
		reader = csv.reader(open(file, 'rb'), delimiter=',')
		for line in reader:
			try:
				lat = float(line[10])
				lng = float(line[11])
			except exceptions.ValueError:
				continue
			#print lat, lng
			#pdb.set_trace()
			if lat > 42.00 and lat < 43.00 and lng < -87.50 and lng > -88.50 :
				d = {}
				d['loc'] = ['%.6f'%lat, '%.6f'%lng]
				print json.dumps(d)
				#print '{"loc":"["+str(lat)+','+str(lng)+"]}'

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print "Usage: python csvreader.py logfile"
        sys.exit()

    locs = LocDataReader()
    data = locs.getData(sys.argv[1])
