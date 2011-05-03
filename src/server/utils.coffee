log = (msg) ->
	console.log msg

error = (msg) ->
	console.error msg

js = (path) ->
	 path.match(/js$/)

mod = (x, n) ->
	if x > 0 then x%n else mod x+n, n

distance = (x1, y1, x2, y2) ->
	Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))

randomColor = () ->
	Math.round(70 + Math.random()*150) +
		',' + Math.round(70 + Math.random()*150) +
		',' + Math.round(70 + Math.random()*150)