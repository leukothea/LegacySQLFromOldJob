#!/usr/bin/env python
# encoding: utf-8
"""
	testPsycodb
	2013-05-13
	
	Test the interface 
"""


import sys
import os
import psycopg2

dbH = psycopg2.connect(host="postgres-bi.greatergood.net", database="pentaho", user="pentaho")
myCursor = dbH.cursor()
myCursor.execute("SELECT * FROM sales_data_mart.store_site_dim")
for dbRow in myCursor:
	print dbRow
	
myCursor.close()
dbH.close()
