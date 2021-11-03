extends Panel

export var Center : Vector2 = Vector2(-0.55, 0.0)
export var Radius : float = 1.3
export var Rotation : Vector3 = Vector3(0.0, 0.0, 0.0)
export var ZoomFactor : float = 1.1

var dragging : bool = false
var dragging_position : Vector2

# We need maximum 3 fingers
var touch_pressed = [false, false, false]
var touch_position = [] 

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

func label_print(string):
	$Label.text = string + "\n" + $Label.text


func _gui_input(event: InputEvent) -> void:
	
	var dimension = 2.0*Radius/min(rect_size.x, rect_size.y)

	if event is InputEventMouseButton:
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
			dragging_position = event.position
			dragging = true
		if not event.pressed  and event.button_index in [BUTTON_LEFT,BUTTON_MIDDLE]:
			dragging = false
	
	if event is InputEventMouseMotion and dragging:
		var delta = event.position-dragging_position
		delta.y *= -1.0
		Center -= delta*dimension
		dragging_position = event.position

	if event is InputEventScreenTouch:
		label_print("TOUCH: " + str(event.index) + " " + str(event.pressed) + " at " +
					 str(event.position))
		touch_pressed[event.index] = event.pressed
		touch_position[event.index] = event.position
		
		if touch_pressed[1]:
			pass

	if event is InputEventScreenDrag:
		label_print("DRAG: " + str(event.index) + " at " + str(event.position) + " relative " + 
					 str(event.relative))

	#$Label.text = "Center " + str(Center) + "\nRadius " + str(Radius) + "\n" + $Label.text 
	




















# Copied from Multitouch Cubes Demo
func dummy():
	var base_state
	var event
	var curr_state
	
	var finger_count = base_state.size()

	if finger_count == 0:
		# No fingers => Accept press.
		if event is InputEventScreenTouch:
			if event.pressed:
				# A finger started touching.

				base_state = {
					event.index: event.position,
				}

	elif finger_count == 1:
		# One finger => For rotating around X and Y.
		# Accept one more press, unpress or drag.
		if event is InputEventScreenTouch:
			if event.pressed:
				# One more finger started touching.

				# Reset the base state to the only current and the new fingers.
				base_state = {
					curr_state.keys()[0]: curr_state.values()[0],
					event.index: event.position,
				}
			else:
				if base_state.has(event.index):
					# Only touching finger released.

					base_state.clear()

		elif event is InputEventScreenDrag:
			if curr_state.has(event.index):
				# Touching finger dragged.
				# Since rotating around two axes, we have to reset the base constantly.
				curr_state[event.index] = event.position
				base_state[event.index] = event.position

	elif finger_count == 2:
		# Two fingers => To pinch-zoom and rotate around Z.
		# Accept unpress or drag.
		if event is InputEventScreenTouch:
			if not event.pressed and base_state.has(event.index):
				# Some known touching finger released.

				# Clear the base state
				base_state.clear()

		elif event is InputEventScreenDrag:
			if curr_state.has(event.index):
				# Some known touching finger dragged.
				curr_state[event.index] = event.position

				# Compute base and current inter-finger vectors.
				var base_segment = base_state[base_state.keys()[0]] - base_state[base_state.keys()[1]]
				var new_segment = curr_state[curr_state.keys()[0]] - curr_state[curr_state.keys()[1]]

				# Get the base scale from the base matrix.


	# Finger count changed?
	if base_state.size() != finger_count:
		# Copy new base state to the current state.
		curr_state = {}
		for idx in base_state.keys():
			curr_state[idx] = base_state[idx]
		# Remember the base transform.


