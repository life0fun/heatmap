exports.config =
	http:
		port:3000
		hostname:'0.0.0.0'
	https:
		enabled: false
		port:443
		domain:"www.socketstream.org"
	browser_check:
		enabled: false
		strict: true
	redis:
		host: "localhost"
		port: 6379
		password:""
