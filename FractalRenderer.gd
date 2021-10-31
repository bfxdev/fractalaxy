extends Panel

export var Center : Vector2 = Vector2(-0.55, 0.0)
export var Radius : float = 1.3
export var Rotation : Vector3 = Vector3(0.0, 0.0, 0.0)
export var ZoomFactor : float = 1.1

var dragging : bool = false
var dragpos : Vector2


# Called when the node enters the scene tree for the first time.
func _ready():
	#print(Time.get_unix_time_from_system())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	material.set_shader_param("Resolution", rect_size)
	material.set_shader_param("Center", Center)
	material.set_shader_param("Radius", Radius)
	material.set_shader_param("Rotation", Rotation)

func _on_FractalRenderer_gui_input(event: InputEvent) -> void:
	
	var dimension = 2.0*Radius/min(rect_size.x, rect_size.y)

	if event is InputEventMouseButton:
		print("Center:", Center, "  Radius:", Radius)
		if event.pressed and event.button_index == BUTTON_WHEEL_UP:
			Radius /= ZoomFactor
			var delta = event.position-0.5*rect_size
			delta.y *= -1.0
			Center += (ZoomFactor-1)*delta*dimension
		if event.pressed and event.button_index == BUTTON_WHEEL_DOWN:
			var delta = event.position-0.5*rect_size
			delta.y *= -1.0
			Center -= (ZoomFactor-1)*delta*dimension
			Radius *= ZoomFactor
		if event.pressed  and event.button_index in [BUTTON_LEFT,BUTTON_MIDDLE]:
			dragpos = event.position
			dragging = true
		if not event.pressed  and event.button_index in [BUTTON_LEFT,BUTTON_MIDDLE]:
			dragging = false
	
	if event is InputEventMouseMotion and dragging:
		var delta = event.position-dragpos
		delta.y *= -1.0
		Center -= delta*dimension
		
		dragpos = event.position
		







