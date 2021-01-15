import psycopg2
import os
import sys

pg_conn = psycopg2.connect("host='postdev-a.greatergood.net' dbname='charityusa' user='adminecom' password=<pw goes here>")
pg_cursor = pg_conn.cursor()
email_text = ""
openfile = open("VersionID-ASIN-data.csv", 'r')
inputfile = openfile.readlines()
for line in inputfile:
    line_arr = line.split(",")
    sql = "update ecommerce.productversion set asin = "
    sql = sql + line_arr[1]
    sql = sql + ' where productversion_id = '
    sql = sql + line_arr[0] + "'"
    print sql
    # try:
	   #  pg_cursor.execute(line)
	   #  pg_conn.commit()
    # except psycopg2.DatabaseError, e:
    # 	print 'Error %s' % e
    # 	sys.exit(1)
pg_conn.close()

print"Done!" 
