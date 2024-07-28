extends Sprite2D


var ID;
var RADIUS;


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _draw():
	draw_circle(Vector2(0, 0), RADIUS, Color.WHITE)


	var default_font = ThemeDB.fallback_font
	var default_font_size = RADIUS
	var string_id = str(ID)
	var display_text_px_size = default_font.get_string_size(string_id, HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size)
	var characters =  string_id.length()
	var character_offset = 0.57 * RADIUS
	var character_offset_y = 0.33

	var CPOS = Vector2((display_text_px_size.x / 2 - (characters * character_offset)), character_offset_y * 100)
	draw_string(default_font, CPOS, string_id, HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size, Color.BLACK)
