import urllib2

def spawn():
	urllib2.urlopen('http://shop.greatergood.net/store/ths/shoppingcart/FREEBIRD', timeout = 500)

x = 1

while x < 25001:
	try: 
		spawn()
		print 'Page number: ', x
		x = x + 1
	except: 
		print 'There was an error!'
		break
