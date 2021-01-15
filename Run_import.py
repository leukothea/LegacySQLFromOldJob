import psycopg2
import os
import sys

pg_conn = psycopg2.connect("host='postdev-a.greatergood.net' dbname='charityusa' user='adminecom' password=<pw goes here>")
pg_cursor = pg_conn.cursor()
email_text = ""
openfile = open("import.csv", 'r')
inputfile = openfile.readlines()
for line in inputfile:
    line_arr = line.split(",")
    sql = "insert into ecommerce.rsinventoryitem (oid, quantity, weight, merchantprice, supplier_id, daterecordadded, initialquantity, sku_id, inventory_item_type_id, inventory_item_class_id, active) values ("
    sql = sql + "nextval('ecommerce.seq_rsinventoryitem'),"
    sql = sql + line_arr[0] + ","
    sql = sql + line_arr[1] + ","
    sql = sql + line_arr[2] + ","
    sql = sql + line_arr[3] + ","
    sql = sql + line_arr[5] + ","
    sql = sql + line_arr[5] + ","
    sql = sql + line_arr[6] + ","
    sql = sql + "1,"
    sql = sql + "true)"
    print sql
    # try:
	   #  pg_cursor.execute(line)
	   #  pg_conn.commit()
    # except psycopg2.DatabaseError, e:
    # 	print 'Error %s' % e
    # 	sys.exit(1)
pg_conn.close()

print"Done!" 
