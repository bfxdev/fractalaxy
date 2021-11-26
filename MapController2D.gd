extends Panel # TODO change to Control or something similar

# Orthogonal basis vectors
var Origin : Vector2         = Vector2(-2.5, -1.2)
var HorizontalBasis : Vector2 = Vector2(0.004, 0.0)
var VerticalBasis : Vector2   = Vector2(0.0, 0.004)

# View-related variables
var Center : Vector2         = Vector2(-0.55, 0.0)
var Radius : float           = 1.3
var Rotation : Vector3       = Vector3(0.0, 0.0, 0.0) # TODO: change to single Angle (2D)
var Zoom : float             = 1.0

# Parameters of keyboard and mouse triggered movements
export var ZoomFactor : float = 1.1
export var PanDelta : float = 10
export var RotationAngle : float = PI/100

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

# Non-continuous movement triggered by single clicks or keyboard hits
enum {ZOOM, PAN, ROTATION, NONE}
var single_movement_type = NONE
var single_zoom_factor : float
var single_zoom_center : Vector2
var single_pan_direction : Vector2 = Vector2(0,0)
var single_rotation_angle : float


# Called when the node enters the scene tree for the first time.
func _ready():
	#print(Time.get_unix_time_from_system())
	pass # Replace with function body.


# Called every frame to compute the new position using the touch points acquired from input events
func _process(_delta):

	############################ Single movements ##############################
	match single_movement_type:
		ZOOM:
			Origin += (1-single_zoom_factor)*single_zoom_center.x*HorizontalBasis
			Origin += (1-single_zoom_factor)*single_zoom_center.y*VerticalBasis
			HorizontalBasis *= single_zoom_factor
			VerticalBasis *= single_zoom_factor
		PAN:
			Origin += single_pan_direction.x*HorizontalBasis
			Origin += single_pan_direction.y*VerticalBasis
		ROTATION:
			HorizontalBasis = HorizontalBasis.rotated(single_rotation_angle)
			VerticalBasis = VerticalBasis.rotated(single_rotation_angle)
			
	single_movement_type = NONE
	single_pan_direction = Vector2(0,0)

	############################ Touch movements ###############################

	# PAN if current or previous frame has exactly one point, kept between frames
	if touch_points.size() == 1 and previous_touch_points.has(touch_points.keys()[0]) or \
	   previous_touch_points.size() == 1 and touch_points.has(previous_touch_points.keys()[0]):
		
		# Determines the index of the touch point and the delta in screen coordinates
		var index = (touch_points if touch_points.size() == 1 else previous_touch_points).keys()[0]
		var delta = touch_points[index] - previous_touch_points[index]
		
		# Adapts values
		Origin -= delta.x*HorizontalBasis + delta.y*VerticalBasis
		
	# ZOOM/ROTATE if 2 points are kept between frames
	elif touch_points.size() == 2 and previous_touch_points.size() >= 2 and \
		 previous_touch_points.has(touch_points.keys()[0]) and \
		 previous_touch_points.has(touch_points.keys()[1]):

		# Determines the new and previous touch points, and their deltas
		var index1 = touch_points.keys()[0]
		var np1 = touch_points[index1]
		var pp1 = previous_touch_points[index1]
		#var d1 = np1 - pp1
		var index2 = touch_points.keys()[1]
		var np2 = touch_points[index2]
		var pp2 = previous_touch_points[index2]
		#var d2 = np2 - pp2
		
		# Computes intermediate vectors (see formulas notebook)
		var A = np1 - np2
		var B = (pp1.x-pp2.x)*HorizontalBasis + (pp1.y-pp2.y)*VerticalBasis
		var D = A.x*A.x + A.y*A.y
		
		# Solution only if D big enough
		if D > 1e-6:
			Origin += pp1.x*HorizontalBasis + pp1.y*VerticalBasis
			HorizontalBasis.x = (A.x*B.x + A.y*B.y) / D
			HorizontalBasis.y = (A.x*B.y - A.y*B.x) / D
			VerticalBasis.x = -HorizontalBasis.y
			VerticalBasis.y =  HorizontalBasis.x
			Origin -= np1.x*HorizontalBasis + np1.y*VerticalBasis


	# Prepares structure for next frame
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

	# Message
	$Label.text  = "Arrow keys or mouse to pan - Mouse wheel or PgUp/PgDown to zoom"
	$Label.text += " - Del/End to rotate - Drag/Pinch on mobile"
	$Label.text += "\nOrigin: " + str(Origin)
	$Label.text += "\nBasis vectors: " + str(HorizontalBasis) + " " + str(VerticalBasis)
	
	$Label.text += "\nTouch points:" + str(previous_touch_points)

func label_print(string):
	$Label.text = string + "\n" + $Label.text


func _input(event : InputEvent) -> void:

	######################### Mouse events #####################################
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_WHEEL_UP:
			single_movement_type = ZOOM
			single_zoom_center = event.position
			single_zoom_factor = 1/(ZoomFactor*event.factor)
			
		if event.pressed and event.button_index == BUTTON_WHEEL_DOWN:
			single_movement_type = ZOOM
			single_zoom_center = event.position
			single_zoom_factor = ZoomFactor*event.factor

	# Simulates a pan with single touch point with index 100
	if event is InputEventMouseButton and event.button_index == MouseButtonPan or \
	   event is InputEventMouseMotion and touch_points.has(100):
		touch_points[100] = event.position
		if event is InputEventMouseButton and not event.pressed:
			released_touch_points.append(100)


	######################### Touch events #####################################

	# Record position of touch event
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if event is InputEventScreenTouch and not event.pressed:
			released_touch_points.append(event.index)


	######################### Keyboard events ##################################

	if event is InputEventKey and event.pressed:
		if event.scancode in [KEY_RIGHT, KEY_D]:
			single_movement_type = PAN
			single_pan_direction.x += PanDelta
		if event.scancode in [KEY_LEFT, KEY_A]:
			single_movement_type = PAN
			single_pan_direction.x -= PanDelta
		if event.scancode in [KEY_UP, KEY_W]:
			single_movement_type = PAN
			single_pan_direction.y -= PanDelta
		if event.scancode in [KEY_DOWN, KEY_S]:
			single_movement_type = PAN
			single_pan_direction.y += PanDelta

		if event.scancode in [KEY_KP_ADD, KEY_PAGEDOWN, KEY_R]:
			single_movement_type = ZOOM
			single_zoom_factor = 1/ZoomFactor
			single_zoom_center = rect_size / 2
	
		if event.scancode in [KEY_KP_SUBTRACT, KEY_PAGEUP, KEY_F]:
			single_movement_type = ZOOM
			single_zoom_factor = ZoomFactor
			single_zoom_center = rect_size / 2

		if event.scancode in [KEY_KP_DIVIDE, KEY_DELETE, KEY_Q]:
			single_movement_type = ROTATION
			single_rotation_angle = RotationAngle

		if event.scancode in [KEY_KP_MULTIPLY, KEY_END, KEY_E]:
			single_movement_type = ROTATION
			single_rotation_angle = -RotationAngle


