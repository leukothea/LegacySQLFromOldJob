# import psycopg2
import os

# pg_conn = psycopg2.connect("host='postdev-a.greatergood.net' dbname='charityusa' user='adminecom' password='ecommerce'")
# pg_cursor = pg_conn.cursor()
# email_text = ""
openfile = open("test.csv", 'r')
inputfile = openfile.readlines()
for line in inputfile:
    line_arr = line.split(",")
    print line
    sql = "update ecommerce.rsinventoryitem set weight = " + line_arr[0] + " where oid = " + line_arr[1] + ";"
    print sql
#    try:
#	    pg_cursor.execute(line)
#	    pg_conn.commit()
#    except psycopg2.DatabaseError, e:
#    	print 'Error %s' % e
#    	sys.exit(1)
# pg_conn.close()

openfile.close()

print"Done!" 