import urllib2

def spawn():
	urllib2.urlopen('http://thehungersite.greatergood.com/store/ths/artisan/%x/', timeout = 500)

x = 1

while x < 797:
	try: 
		spawn()
		print 'Page number: ', x
		x = x + 1
	except: 
		print 'There was an error!'
		break
