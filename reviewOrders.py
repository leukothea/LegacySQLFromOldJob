#!/usr/bin/env python
"""

    reviewOrders -- obtains and reviews missing order data
    
    2014-04-14
    
    Have no clue what I'm doing here at this point...
    
    The basic idea is to obtain missing order data from 
    the warehouse and attempt to figure out why the data are 
    missing by querying the source Ecommerce data.
    
"""

import sys
import os
import psycopg2


def initPayStatusDict(dbHandle):
    tEcommCon = dbHandle.cursor()
    
    tEcommCon.execute("SELECT * FROM ecommerce.payment_status")
    zDict = {}
    for zRow in tEcommCon:
        zDict[zRow[0]]=zRow[1]


    tEcommCon.close()

    return zDict


def getAuthRecord(dbHandle, orderId):
    tEcommCon = dbHandle.cursor()
    
    authed = []
    
    tEcommCon.execute("SELECT * FROM ecommerce.paymentauthorization WHERE order_id = %s order by authdate DESC", (orderId,))
    
    authed = tEcommCon.fetchall()
    dbHandle.commit()
    tEcommCon.close()
    
    return authed
    

def getOrderHeader(dbHandle, orderId):
    tEcommCon = dbHandle.cursor()
    rCount = 0
    tEcommCon.execute("SELECT * FROM ecommerce.rsorder WHERE oid = %s",(orderId,))
    rCount = tEcommCon.rowcount
    
    dbHandle.commit()
    tEcommCon.close()
    
    return rCount
 
 
def getOrderLineItem(dbHandle, orderId):
    tEcommCon = dbHandle.cursor()
    tReturn = "lineItemOkay"
    lineTypeTally = {1:0,2:0,3:0,4:0,5:0,6:0,7:0,8:0}

    tEcommCon.execute("SELECT oid, lineitemtype_id FROM ecommerce.rslineitem WHERE order_id = %s", (orderId,))
    if tEcommCon.rowcount == 0:
        tReturn = "NoLineItemRI"
    else:
        for zRow in tEcommCon:
            lineTypeTally[zRow[1]] += 1
    
        if (lineTypeTally[1] + lineTypeTally[5]) == 0:
            tReturn = "NoLineItemReversal"
    
    return tReturn

def main():
    biInsertHandle = psycopg2.connect(host="postgres-bi.greatergood.net", database="pentaho", user="pentaho")
    biHandle = psycopg2.connect(host="postgres-bi.greatergood.net", database="pentaho", user="pentaho")
    ecommHandle = psycopg2.connect(host="postgres-b.greatergood.net", database="charityusa", user="reporter")

    payStatusDict = initPayStatusDict(ecommHandle)
    
    #
    #   Initialize some other stuffs before we begin
    #
    errorTally = {"resultNoAuth":0, \
    "statusNoAuth":0, \
    "statusDeclined":0, \
    "statusVoided":0, \
    "statusCredited":0, \
    "statusError":0, \
    "orderOkay":0, \
    "noSuchOrder":0, \
    "NoLineItemRI":0, \
    "NoLineItemReversal":0, \
    "statusNoAuth":0, \
    "statusDeclined":0, \
    "statusVoided":0, \
    "statusCredited":0, \
    "statusError":0 \
    }
    statusErrorLookup = {1:"statusNoAuth", 2:"statusDeclined",4:"statusVoided",7:"statusCredited",8:"statusError"}
    
    #  
    #   Attach to the data warehouse and get all authed orders from December 2012 onward
    #   that do not have assocociated facts; form the query, fire it off and iterate through the
    #   results.
    #
    #   The analysis then will be to (1) check the authorization data for the order,
    #   (2) check the order header for the order
    #   (3) Check the order line item for line item entries 
    #
    biInsert = biInsertHandle.cursor()
    biCon = biHandle.cursor()
    biCon.execute("SELECT odim.order_key, odim.order_date_key, odim.order_date, odim.order_id, odim.payment_authorization_date \
        FROM sales_data_mart.order_dim odim LEFT OUTER JOIN sales_data_mart.order_sales_fact osf USING (order_key) \
        WHERE odim.payment_authorization_date >= '2012-12-01' \
        AND odim.is_authorized = 'T' \
        AND osf.order_key IS NULL ") 

    osfMissingCount = 0
    for missingOsfOrder in biCon:
        osfMissingCount += 1
        orderTallyStatus = "orderOkay"
        authorization = getAuthRecord(ecommHandle, missingOsfOrder[3])
        
        if authorization[0][13] == 1:
            #print missingOsfOrder[3],"Authorized"

            if authorization[0][12] in set([3,5,6]):
                orderIn = getOrderHeader(ecommHandle, missingOsfOrder[3])
                
                if orderIn != 0:
                    lineItemSuss = getOrderLineItem(ecommHandle, missingOsfOrder[3])
                    if lineItemSuss == "lineItemOkay":
                        orderTallyStatus = "orderOkay"
                    else:
                        orderTallyStatus = lineItemSuss
                else:
                    orderTallyStatus = "noSuchOrder"
            else:
                orderTallyStatus = statusErrorLookup[authorization[0][12]]
        else:
            orderTallyStatus = "resultNoAuth"
        
        errorTally[orderTallyStatus] += 1
        biInsert.execute("INSERT INTO public.bad_osf (order_key, order_id, order_stat) VALUES (%s,%s,%s)", (missingOsfOrder[0], missingOsfOrder[3],orderTallyStatus))
        biInsertHandle.commit()
            
        


    print osfMissingCount
    print errorTally
    #
    #   Close up the database connections, and rundown

    biInsertHandle.commit()
    biHandle.commit()
    biHandle.close()
    biInsertHandle.close()
    ecommHandle.close()







try:
    set
except NameError:
    from sets import Set as set, ImmutableSet as frozenset
    

if __name__ == '__main__':
    main()
