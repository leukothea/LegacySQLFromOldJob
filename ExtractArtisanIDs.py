import psycopg2
import os
import sys
import re

openfile = open("ProductAUTOMATED_20150915_part5.xml", 'r')
inputfile = openfile.readlines()
for line in inputfile:
    try:
        found = re.search('<artisanID>(.+?)</artisanID>', line).group(1)
    except AttributeError:
        # <artisanID>, </artisanID> not found in the original string
        found = '' # apply your error handling
    print found 

print"Done!" 