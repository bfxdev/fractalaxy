extends Panel # TODO change to Control or something similar

# Orthogonal basis vectors
var Origin : Vector2         = Vector2(-2.5, 1.2)
var HorizontalBasis : Vector2 = Vector2(0.004, 0.0)
var VerticalBasis : Vector2   = Vector2(0.0, -0.004)

# View-related variables
var Center : Vector2         = Vector2(-0.55, 0.0)
var Radius : float           = 1.3
var Rotation : Vector3       = Vector3(0.0, 0.0, 0.0) # TODO: change to single Angle (2D)
var Zoom : float             = 1.0

# Script parameters
export var ZoomFactor : float = 1.1
# TODO: rename with uppercase
export var MouseButtonPan     = BUTTON_LEFT
export var MouseButtonZoomIn  = BUTTON_WHEEL_UP
export var MouseButtonZoomOut = BUTTON_WHEEL_DOWN

# TODO to be used later
export var VerticalAxisUp : bool = true
export var ViewCircle : bool = true
#export var Rotation : bool = true

var dragging : bool = false
var dragging_position : Vector2

# Dictionary of current touch points in screen coordinates relative to the Node (from InputEvent).
# The coordinates of the related points in Map coordinates do not change during a pan or zoom.
var touch_points = {}

# List of touch point indexes to be removed at next frame (e.g. following unpressed)
var released_touch_points = []

# Touch points of the previous frame. The number of touch points may vary between frames.
# Normally only updated in `_process` but may be modified in `_input` to simulate movements 
# based on single events (from keyboard or clicks).
var previous_touch_points = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	#print(Time.get_unix_time_from_system())
	pass # Replace with function body.


# Called every frame to compute the new position using the touch points acquired from input events
func _process(_delta):

	#var dimension = 2.0*Radius/min(rect_size.x, rect_size.y)

	# Zoom around point with special indices 1000 and 1001
	if touch_points.size() == 1 and touch_points.keys()[0]>=1000:
		var index = touch_points.keys()[0]
		var zoom = ZoomFactor if index==1001 else 1/ZoomFactor
		var point = touch_points[index]
		Origin += (1-zoom)*point.x*HorizontalBasis + (1-zoom)*point.y*VerticalBasis
		HorizontalBasis *= zoom
		VerticalBasis *= zoom

	# Pan if current or previous frame has exactly one point, kept between frames
	if touch_points.size() == 1 and previous_touch_points.has(touch_points.keys()[0]) or \
	   previous_touch_points.size() == 1 and touch_points.has(previous_touch_points.keys()[0]):
		
		# Determines the index of the touch point and the delta in screen coordinates
		var index = (touch_points if touch_points.size() == 1 else previous_touch_points).keys()[0]
		var delta = touch_points[index] - previous_touch_points[index]
		
		# Adapts values
		Origin -= delta.x*HorizontalBasis + delta.y*VerticalBasis
		
		#delta.y *= -1.0
		#Center -= delta*dimension
		#elif touch_points.size() == 2:


	# Prepares structure for next frame
	$Label.text  = "\n\n\nCenter: " + str(Center)
	$Label.text += "\nRadius: " + str(Radius)
	$Label.text += "\nOrigin: " + str(Origin)
	$Label.text += "\nHorizontalBasis: " + str(HorizontalBasis)
	$Label.text += "\nVerticalBasis: " + str(VerticalBasis)
	$Label.text += "\ntouch_points: " + str(touch_points)
	previous_touch_points = touch_points.duplicate()
	for index in released_touch_points:
		touch_points.erase(index)
	released_touch_points = []
	
	# Updates parameters in shader
	material.set_shader_param("Resolution", rect_size)
	material.set_shader_param("Center", Center)
	material.set_shader_param("Radius", Radius)
	material.set_shader_param("Rotation", Rotation)
	material.set_shader_param("Origin", Origin)
	material.set_shader_param("HorizontalBasis", HorizontalBasis)
	material.set_shader_param("VerticalBasis", VerticalBasis)

func label_print(string):
	$Label.text = string + "\n" + $Label.text


func _input(event : InputEvent) -> void:
	
	var dimension = 2.0*Radius/min(rect_size.x, rect_size.y)

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_WHEEL_UP:
			Radius /= ZoomFactor
			var delta = event.position-0.5*rect_size
			delta.y *= -1.0
			Center += (ZoomFactor-1)*delta*dimension
			
			touch_points[1000] = event.position
			released_touch_points.append(1000)

			
		if event.pressed and event.button_index == BUTTON_WHEEL_DOWN:
			var delta = event.position-0.5*rect_size
			delta.y *= -1.0
			Center -= (ZoomFactor-1)*delta*dimension
			Radius *= ZoomFactor
			
			touch_points[1001] = event.position
			released_touch_points.append(1001)

	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)

	if event is InputEventScreenDrag:
		touch_points[event.index] = event.position

	# Record position of touch event
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if event is InputEventScreenTouch and not event.pressed:
			released_touch_points.append(event.index)

	# Simulates a pan with single touch point with index 100
	if event is InputEventMouseButton and event.button_index == MouseButtonPan or \
	   event is InputEventMouseMotion and touch_points.has(100):
		touch_points[100] = event.position
		if event is InputEventMouseButton and not event.pressed:
			released_touch_points.append(100)


		

	





















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


