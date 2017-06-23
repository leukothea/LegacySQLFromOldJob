-- Replace one string in item content with a longer string, for ALL items with the first string. 
-- (NOTE: If I wanted to only update some, I’d have to add a "where" clause with the list of item_ids affected)

update
   ecommerce.item
set
   itemdescription = replace (
       itemdescription,
       '<img class="fitNote" alt="Fit Note" src="/store/product/image/3.gif" />',
       '<img class="fitNote" alt="Fit Note" src="/store/product/image/3.gif" /><font size="large"><strong>Garment Measurements:</strong></font><br />'
   );


-- And again, for fit notes that are formatted differently!

update
   ecommerce.item
set
   itemdescription = replace (
       itemdescription,
       '<img style="margin: 0px 15px 10px 0px; display: block;" alt="Fit Note" src="/store/product/image/4.gif" width="540" height="60"/></p>',
       '<img style="margin: 0px 15px 10px 0px; display: block;" alt="Fit Note" src="/store/product/image/4.gif" width="540" height="60"/></p><font size="large"><strong>Garment Measurements:</strong></font><br />'
   );

-- And again, to change autoplay=1 in URLs to autoplay=0 (thus turning off autoplay for embedded videos)
-- NOTE that the "count" that comes back is the count of every single item in the store, because the query examines all items in order to do the replace operation. So even though only 180 items were affected, the "count" in PostGres shows as 54,000+. 

update
  ecommerce.item
set
  itemdescription = replace (
    itemdescription,
    'autoplay=1',
    'autoplay=0'
  );