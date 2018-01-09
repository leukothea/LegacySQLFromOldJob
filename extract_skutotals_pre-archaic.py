# Extract LandedCost file's SKU totals 
# Catherine Warren, 2016-09-28 & 29
# 

#!/usr/local/bin/python3

import csv
import codecs


class MyData:                   #Object to store unique data
	def __init__(self, cellDate, cellQty):
		self.cellDate = cellDate
		self.cellQty = cellQty

rownum = 0 #Row Number currently iterating over
list = {}  #List to store objects

def utf_8_encoder(unicode_csv_data):
    for line in unicode_csv_data:
        yield line.encode('utf-8')

def checkList(cellDate, cellSku, cellQty):
	if int(cellSku) in list.keys():
		list[int(cellSku)].cellQty += int(cellQty)

	else:
		newObject = MyData(cellDate, int(cellQty)) #Create a new object with new cellDate, cellSku, and cellQty
		list[int(cellSku)] = newObject  #Add to list and break out


with codecs.open('LandedCostDetail-2013-12-01.csv', 'r', encoding='mac_roman') as file:
	reader = csv.reader(file, delimiter = ',', quotechar = '"')
	for row in reader:
		if rownum == 0: #Store header row seperately to not get confused
			header = row
		else:
			try:
				cellDate = row[0]
				cellSku = row[5]
				cellQty = row[2]
				checkList(cellDate, cellSku, cellQty) #add any new SKU quantities to any previous SKU quantities in the list

			except ValueError:
				break #break out of an error condition
		rownum += 1 #go to the next row, repeat


with open('skutotals-2013-12-01.txt', 'w') as output_file:
	fieldnames = ('cellDate', 'cellSku', 'cellQty')
	writer = csv.DictWriter(output_file, fieldnames, delimiter=',')
	for sku in list.keys():
		writer.writerow({'cellDate':list[sku].cellDate, 'cellSku':sku,'cellQty':list[sku].cellQty})