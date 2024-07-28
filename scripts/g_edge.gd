extends Sprite2D


var EDGE_ID;
var POS1;
var POS2;

var THICKNESS : int:
	set(value):
		THICKNESS = value
		queue_redraw()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _draw():
	draw_line(POS1, POS2, Color.WHITE, THICKNESS)
