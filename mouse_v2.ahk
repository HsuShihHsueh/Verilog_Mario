x=500
y=500
r=50

w:: ;up
	while GetKeystate("w")
	{
		Click up
		MouseMove,x,y-r
		Click down
		Click up
	}	
	return
s:: ;down
	while GetKeystate("s")
	{
		Click up
		MouseMove,x,y
		Click down
		Click up
	}	
	return
a:: ;left
	while GetKeystate("a")
	{
		Click up	
		MouseMove,x-r,y
		Click down
		Click up	
	}
	return
d:: ;right
	while GetKeystate("d")
	{
		Click up	
		MouseMove,x+r,y
		Click down
		Click up	
	}
	return
p:: ;position
	MouseGetPos,x,y