#!/usr/bin/env python
"""
Zip Code Parser
CharityUSA.com, LLC, 2013

"""

import csv
import sys
import re

filename = 'UPSData1.csv'

with open('UPSData1.csv', 'rb') as f:
	reader = csv.reader(f)
	try:
		for row in reader:
			print row
	except csv.Error as e:
		sys.exit('file %s, line %d: %s' % (filename, reader.line_num, e))


# with open('UPSData1.csv', 'rb') as csvfile:
# 	data = csv.reader(csvfile, delimiter=' ', quotechar='|')
# 	for row in data:
# 		print ', '.join(row)



f.close()