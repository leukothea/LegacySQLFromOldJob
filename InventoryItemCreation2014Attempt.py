import psycopg2
import os

pg_conn = psycopg2.connect("host='postgres-a.greatergood.net' dbname='charityusa' user='adminecom' password=<pw goes here>")
pg_cursor = pg_conn.cursor()
email_text = ""
openfile = open("SQLQueries2014-11-07.txt", 'r')
inputfile = openfile.readlines()
for line in inputfile:
    print line + "\n"
    print "---"
    try:
	    pg_cursor.execute(line)
	    pg_conn.commit()
    	# pg_result = pg_cursor.fetchall()
    except psycopg2.DatabaseError, e:
    	print 'Error %s' % e    
    	sys.exit(1)
pg_conn.close()

print"Done!" 

