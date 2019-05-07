import urllib2

def spawn():
	x = 1
	urllib2.urlopen('http://shop.greatergood.net/store/ths/shoppingcart/FREEBIRD', timeout = 500)
	x = x + 1

try: 
	spawn()
	print 'The page spawned successfully'
except: 
	print 'There was an error!'